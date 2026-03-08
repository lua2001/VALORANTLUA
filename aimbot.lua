-- MEGA HACK v1.0 — All Features Combined
-- ESP Outline + Smoke Remover + Auto Callout + Enemy Stats + Aimbot + Auto Buy
----------------------------------------------------------------------
local CFG = {
    -- Master toggles (true = enabled)
    ESP_OUTLINE     = true,   -- Reveal enemies through walls (red outline)
    ESP_DRAW3D      = true,   -- DrawDebugBox/String over enemies
    SMOKE_REMOVER   = true,   -- Hide enemy smoke/walls visually
    AUTO_CALLOUT    = true,   -- Auto ping enemy positions to team
    AIMBOT          = true,   -- Aimbot (fire only)
    NO_RECOIL       = true,   -- Stabilize rotation while firing
    SPIKE_TRACKER   = true,   -- Highlight spike carrier in yellow

    -- Aimbot settings
    FOV             = 45,
    MAXD            = 6000,
    CHEST_Z         = 25,
    MY_EYE_Z        = 55,
    AIM_SMOOTH      = 0.15,
    AIM_SMOOTH_FIRST= 0.6,
    JITTER          = 0.3,

    -- General
    TICK            = 0.020,
    ESP_INTERVAL    = 0.5,    -- ESP refresh interval (seconds)
    CALLOUT_CD      = 3.0,    -- Callout cooldown per enemy (seconds)
    LOG             = true,
    LOGP            = "/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/mega_log.txt",
}

----------------------------------------------------------------------
-- IMPORTS (safe)
----------------------------------------------------------------------
local ok_tt, TT = pcall(require, "Common.Framework.TimeTicker")
local AP, SGPS, SGCC, SGCH, KML, GP = nil,nil,nil,nil,nil,nil
local UKSL, CVFunc, ETTQ_Vis = nil,nil,nil
local RPCSender = nil
local DecoSys = nil   -- DecorationSystem
local GameSysUtil = nil

local function SafeImport(name)
    local o,v = pcall(function() return import(name) end)
    return o and v or nil
end
local function SafeImportLib(name)
    local o,v = pcall(function() return import_func_lib(name) end)
    return o and v or nil
end
local function SafeRequire(name)
    local o,v = pcall(require, name)
    return o and v or nil
end

----------------------------------------------------------------------
-- LOGGING
----------------------------------------------------------------------
local function L(m)
    if not CFG.LOG then return end
    pcall(function()
        local f = io.open(CFG.LOGP, "a")
        if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(m) .. "\n") f:close() end
    end)
end

----------------------------------------------------------------------
-- LAZY INIT
----------------------------------------------------------------------
local initDone = false
local function LazyInit()
    if initDone then return end
    AP     = SafeRequire("Game.Mod.BaseMod.GamePlay.Core.GAS.Util.AbilityPreDefine")
    SGPS   = SafeImport("SGBasePlayerState")
    SGCH   = SafeImport("SGBaseCharacter")
    KML    = SafeImportLib("KismetMathLibrary")
    GP     = SafeImportLib("GameplayStatics")
    UKSL   = SafeImportLib("KismetSystemLibrary")
    CVFunc = SafeImportLib("CVFunctionLibrary")

    -- Trace channel
    if CVFunc and not ETTQ_Vis then
        pcall(function()
            local ECC = import("ECollisionChannel")
            if ECC and ECC.ECC_Visibility then
                ETTQ_Vis = CVFunc.ConvertToTraceType(ECC.ECC_Visibility)
            end
        end)
    end

    if AP then pcall(function() SGCC = AP.ASGBaseCharacterClass end) end
    if not SGCC and SGCH then SGCC = SGCH end

    -- RPCSender for auto callout
    RPCSender = SafeRequire("Game.Core.RPC.RPCSender")

    -- DecorationSystem for ESP outline
    pcall(function()
        GameSysUtil = SafeRequire("Game.Core.Util.GameSystemUtil")
        if GameSysUtil and GameSysUtil.GetOrCreateGameSystem then
            DecoSys = GameSysUtil.GetOrCreateGameSystem("DecorationSystem")
        end
    end)

    if SGPS and KML then initDone = true end
    L("[INIT] AP=" .. tostring(AP~=nil) .. " SGPS=" .. tostring(SGPS~=nil)
      .. " KML=" .. tostring(KML~=nil) .. " UKSL=" .. tostring(UKSL~=nil)
      .. " RPC=" .. tostring(RPCSender~=nil) .. " Deco=" .. tostring(DecoSys~=nil))
end

----------------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------------
local function GetPC()
    if GameAPI and GameAPI.GetPlayerController then
        local p = GameAPI.GetPlayerController()
        if p and slua_isValid(p) then return p end
    end
    if GP and slua_getWorld then
        local o,p = pcall(function() return GP.GetPlayerController(slua_getWorld(), 0) end)
        if o and p and slua_isValid(p) then return p end
    end
end

local function GetPS()
    if GameAPI and GameAPI.GetPlayerState then
        local o,p = pcall(function() return GameAPI.GetPlayerState() end)
        if o and p and slua_isValid(p) then return p end
    end
end

local function GetCh(pc)
    if not pc then return end
    local o,c = pcall(function() return pc:GetSGBaseCharacter() end)
    if o and c and slua_isValid(c) then return c end
end

local function InMatch()
    local pc = GetPC() if not pc then return false end
    local ps = GetPS() if not ps then return false end
    if not GetCh(pc) then return false end
    local o,a = pcall(function() return ps:IsAlive() end)
    if o and a then return true end
    return false
end

local function IsFiring(myChar)
    local o,f = pcall(function() return myChar:HasPawnState(EPawnState_AFire) end)
    return o and f or false
end

local function VDist(a,b)
    return math.sqrt((a.X-b.X)^2 + (a.Y-b.Y)^2 + (a.Z-b.Z)^2)
end

local function NA(a)
    while a > 180 do a = a - 360 end
    while a < -180 do a = a + 360 end
    return a
end

local function LerpAngle(cur, tgt, t)
    return cur + NA(tgt - cur) * t
end

local function LookAt(f, t)
    if KML and KML.FindLookAtRotation then
        local o,r = pcall(function() return KML.FindLookAtRotation(f, t) end)
        if o and r then return r end
    end
    local dx,dy,dz = t.X-f.X, t.Y-f.Y, t.Z-f.Z
    local d2 = math.sqrt(dx*dx + dy*dy)
    return FRotator(math.deg(math.atan(dz, d2)), math.deg(math.atan(dy, dx)), 0)
end

local function IsVisible(myChar, eyePos, targetPos)
    if not UKSL or not ETTQ_Vis then return true end
    local ok2, bHit = pcall(function()
        local zc = FLinearColor(0,0,0,0)
        return UKSL.LineTraceSingle(slua_getWorld(),
            FVector(eyePos.X, eyePos.Y, eyePos.Z),
            FVector(targetPos.X, targetPos.Y, targetPos.Z),
            ETTQ_Vis, true, {myChar}, 0, nil, false, zc, zc, 0.0)
    end)
    if ok2 then return not bHit end
    return true
end

----------------------------------------------------------------------
-- GET ENEMIES (same as aimbot)
----------------------------------------------------------------------
local function GetEnemies()
    local e = {}
    if GameAPI and GameAPI.GetAllActorsOfClass and SGPS then
        local o,ap = pcall(function() return GameAPI.GetAllActorsOfClass(SGPS) end)
        if o and ap then
            for _,ps in pairs(ap) do
                pcall(function()
                    if slua_isValid(ps) and ps:IsAlive() then
                        local skip = false
                        if AP and AP.IsSameCampWithLocalPlayer then
                            local oc,s = pcall(function() return AP.IsSameCampWithLocalPlayer(ps) end)
                            if oc and s then skip = true end
                        end
                        if not skip then
                            local c = ps:GetSGBaseCharacter()
                            if c and slua_isValid(c) then
                                e[#e+1] = {p=ps, c=c}
                            end
                        end
                    end
                end)
            end
        end
    end
    return e
end

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------
local S = {
    inM = false,       -- in match
    mca = 0,           -- match check accumulator
    tc  = 0,           -- tick counter
    ltk = nil,         -- last target key
    il  = false,       -- init loaded
    dd  = false,       -- diag done
    fireFrames = 0,
    lockedRot = nil,
    -- ESP
    espAcc = 0,
    outlinedEnemies = {},
    -- Callout
    calloutTimers = {},
    -- Smoke remover
    smokeClasses = {},
    smokeInit = false,
}

----------------------------------------------------------------------
-- FEATURE 1: ESP OUTLINE (Reveal enemies through walls)
----------------------------------------------------------------------
local function DoESPOutline(enemies, myChar)
    if not CFG.ESP_OUTLINE then return end
    if not DecoSys then return end
    -- Track which enemies are currently seen
    local currentKeys = {}
    for _, v in ipairs(enemies) do
        pcall(function()
            local key = tostring(v.c)
            currentKeys[key] = true
            if not S.outlinedEnemies[key] then
                local color = FLinearColor(1, 0, 0, 1) -- Red
                -- Try SetCharacterRevealed (sees through walls!)
                local ok1 = pcall(function()
                    DecoSys:SetCharacterRevealed(v.c, color)
                end)
                if not ok1 then
                    -- Fallback: try mesh outline
                    pcall(function()
                        DecoSys:SetMeshComponentOutline(v.c.Mesh, color)
                    end)
                end
                S.outlinedEnemies[key] = v.c
                L("[ESP] Outlined enemy: " .. key)
            end
        end)
    end
    -- Remove outline from enemies no longer tracked
    for key, char in pairs(S.outlinedEnemies) do
        if not currentKeys[key] then
            pcall(function()
                DecoSys:RemoveCharacterDecoration(char)
            end)
            S.outlinedEnemies[key] = nil
        end
    end
end

----------------------------------------------------------------------
-- FEATURE 2: ESP DRAW 3D (name, HP, shield, weapon above heads)
----------------------------------------------------------------------
local function DoESPDraw3D(enemies, myEye)
    if not CFG.ESP_DRAW3D then return end
    if not UKSL then return end
    for _, v in ipairs(enemies) do
        pcall(function()
            local pos = v.c:K2_GetActorLocation()
            if not pos then return end
            local dist = VDist(myEye, pos)
            -- Box around enemy
            pcall(function()
                UKSL.DrawDebugBox(
                    v.c, pos, FVector(30, 30, 90),
                    FLinearColor(1, 0, 0, 0.8), FRotator(0,0,0),
                    CFG.ESP_INTERVAL + 0.1, 2)
            end)
            -- Text: Name [HP/Shield] Distance
            local info = ""
            pcall(function()
                local name = v.p and v.p:GetPlayerName() or "?"
                local hp = v.p and v.p:GetAttributeCurValue("Health") or "?"
                local sh = v.p and v.p:GetAttributeCurValue("Shield") or "?"
                local spike = ""
                pcall(function()
                    if v.p and v.p:GetSuperData().bHasSpike then spike = " [SPIKE]" end
                end)
                info = string.format("%s [HP:%s SH:%s] %dm%s",
                    tostring(name), tostring(math.floor(tonumber(hp) or 0)),
                    tostring(math.floor(tonumber(sh) or 0)),
                    math.floor(dist / 100), spike)
            end)
            if info ~= "" then
                pcall(function()
                    UKSL.DrawDebugString(
                        v.c, pos + FVector(0, 0, 130), info, nil,
                        FLinearColor(1, 0.2, 0.2, 1), CFG.ESP_INTERVAL + 0.1)
                end)
            end
            -- Line from me to enemy
            pcall(function()
                UKSL.DrawDebugLine(
                    v.c,
                    FVector(myEye.X, myEye.Y, myEye.Z - 30),
                    pos + FVector(0, 0, 50),
                    FLinearColor(1, 0, 0, 0.3),
                    CFG.ESP_INTERVAL + 0.1, 1)
            end)
        end)
    end
end

----------------------------------------------------------------------
-- FEATURE 3: SMOKE/WALL REMOVER (hide enemy ability actors)
----------------------------------------------------------------------
local function InitSmokeClasses()
    if S.smokeInit then return end
    S.smokeInit = true
    -- Try to load common smoke/wall actor classes
    local classNames = {
        "BP_AGT_VY_Q_WallActor",   -- Viper wall
        "BP_AGT_VY_Q_BulletActor", -- Viper smoke orb
        "BP_AGT_OM_X_SmokeActor",  -- Omen smoke
        "BP_AGT_BR_E_SmokeActor",  -- Brimstone smoke
        "BP_AGT_AS_C_StarActor",   -- Astra smoke
        "BP_AGT_HA_C_SeaWallActor",-- Harbor wall
        "BP_AGT_PH_C_BulletActor", -- Phoenix wall
        "BP_AGT_SA_C_IceWallBlock",-- Sage wall block
        "BP_AGT_JE_C_SmokeActor",  -- Jett smoke
    }
    for _, name in ipairs(classNames) do
        pcall(function()
            local cls = import(name)
            if cls then
                S.smokeClasses[#S.smokeClasses + 1] = {name=name, class=cls}
                L("[SMOKE] Loaded class: " .. name)
            end
        end)
    end
    L("[SMOKE] Loaded " .. #S.smokeClasses .. " smoke/wall classes")
end

local function DoSmokeRemover()
    if not CFG.SMOKE_REMOVER then return end
    if not GameAPI or not GameAPI.GetAllActorsOfClass then return end
    InitSmokeClasses()
    -- Also try generic approach: find ability actors and check if enemy
    -- Hide smoke/wall actors from enemy team
    for _, sc in ipairs(S.smokeClasses) do
        pcall(function()
            local actors = GameAPI.GetAllActorsOfClass(sc.class)
            if actors then
                for _, actor in pairs(actors) do
                    pcall(function()
                        if slua_isValid(actor) then
                            -- Check if this is enemy's ability actor
                            local isEnemy = false
                            pcall(function()
                                if AP and AP.IsSameCampWithLocalPlayer then
                                    -- ability actors often have CampID or Instigator
                                    local campOk, camp = pcall(function() return actor.OwnerPlayerCampID end)
                                    if campOk and camp then
                                        local myCamp = nil
                                        pcall(function()
                                            local ps = GetPS()
                                            if ps then myCamp = ps:GetCampID() end
                                        end)
                                        if myCamp and camp ~= myCamp and camp ~= 0 then
                                            isEnemy = true
                                        end
                                    end
                                end
                            end)
                            if isEnemy then
                                actor:SetActorHiddenInGame(true)
                                L("[SMOKE] Hidden enemy actor: " .. sc.name)
                            end
                        end
                    end)
                end
            end
        end)
    end
end

----------------------------------------------------------------------
-- FEATURE 4: AUTO CALLOUT (ping enemy positions to team)
----------------------------------------------------------------------
local function DoAutoCallout(enemies, myChar)
    if not CFG.AUTO_CALLOUT then return end
    if not RPCSender then return end
    local now = os.clock()
    for _, v in ipairs(enemies) do
        pcall(function()
            local key = nil
            pcall(function() key = v.p and v.p:GetPlayerKey() end)
            if not key then return end
            -- Cooldown check
            if S.calloutTimers[key] and (now - S.calloutTimers[key]) < CFG.CALLOUT_CD then
                return
            end
            -- Check if enemy is visible (we can see them)
            local pos = v.c:K2_GetActorLocation()
            local myPos = myChar:K2_GetActorLocation()
            local eyePos = {X=myPos.X, Y=myPos.Y, Z=myPos.Z + CFG.MY_EYE_Z}
            if IsVisible(myChar, eyePos, pos) then
                -- Send callout to team
                pcall(function()
                    RPCSender:Server("ServerRPC_OnReceivePostEnemySpotted", key, true, {})
                end)
                S.calloutTimers[key] = now
                L("[CALLOUT] Spotted enemy key=" .. tostring(key))
            end
        end)
    end
end

----------------------------------------------------------------------
-- FEATURE 5: SPIKE TRACKER (yellow outline on spike carrier)
----------------------------------------------------------------------
local function DoSpikeTracker(enemies)
    if not CFG.SPIKE_TRACKER then return end
    if not DecoSys then return end
    for _, v in ipairs(enemies) do
        pcall(function()
            if v.p then
                local hasBomb = false
                pcall(function() hasBomb = v.p:GetSuperData().bHasSpike end)
                if hasBomb then
                    pcall(function()
                        DecoSys:SetCharacterRevealed(v.c, FLinearColor(1, 1, 0, 1)) -- Yellow
                    end)
                    L("[SPIKE] Carrier found!")
                end
            end
        end)
    end
end

----------------------------------------------------------------------
-- FEATURE 6: AIMBOT (same as aimbot.lua v5)
----------------------------------------------------------------------
local function DoAimbot(enemies, myChar, myEye, cr, pc)
    if not CFG.AIMBOT then return end
    if not IsFiring(myChar) then
        S.lockedRot = nil
        S.fireFrames = 0
        return
    end
    S.fireFrames = S.fireFrames + 1
    if #enemies == 0 then S.lockedRot = nil return end

    local be, bp, bestAng = nil, nil, 999
    for _, v in ipairs(enemies) do
        local ok2, ep = pcall(function() return v.c:K2_GetActorLocation() end)
        if ok2 and ep then
            ep.Z = ep.Z + CFG.CHEST_Z
            local d = VDist(myEye, ep)
            if d <= CFG.MAXD then
                local tr = LookAt(myEye, ep)
                local dY = NA(tr.Yaw - cr.Yaw)
                local dP = NA(tr.Pitch - cr.Pitch)
                local ang = math.sqrt(dY*dY + dP*dP)
                if ang <= (CFG.FOV/2) then
                    if IsVisible(myChar, myEye, ep) then
                        if ang < bestAng then
                            bestAng = ang
                            be = v
                            bp = ep
                        end
                    end
                end
            end
        end
    end

    if not be or not bp then S.lockedRot = nil return end
    local ek = nil pcall(function() ek = be.p and be.p:GetPlayerKey() or "bot" end)
    if ek ~= S.ltk then S.ltk = ek L("[AIM] Target=" .. tostring(ek) .. " ang=" .. string.format("%.1f", bestAng)) end

    local exactRot = LookAt(myEye, bp)
    local jX = (math.random()-0.5) * CFG.JITTER
    local jY = (math.random()-0.5) * CFG.JITTER
    local smooth = S.fireFrames == 1 and CFG.AIM_SMOOTH_FIRST or CFG.AIM_SMOOTH
    local newPitch = LerpAngle(cr.Pitch, exactRot.Pitch + jY, smooth)
    local newYaw   = LerpAngle(cr.Yaw,   exactRot.Yaw   + jX, smooth)
    pcall(function() pc:ClientSetRotation(FRotator(newPitch, newYaw, 0), false) end)
end

----------------------------------------------------------------------
-- MAIN TICK
----------------------------------------------------------------------
local function OnTick(dt)
    S.tc = S.tc + 1

    -- Lazy init
    if not S.il then
        LazyInit()
        if initDone then S.il = true end
    end

    -- Match check (every 1s)
    S.mca = S.mca + dt
    if S.mca >= 1.0 then
        S.mca = 0
        local was = S.inM
        S.inM = InMatch()
        if S.inM and not was then
            L("=== MATCH START ===")
            S.outlinedEnemies = {}
            S.calloutTimers = {}
        elseif not S.inM and was then
            L("=== MATCH END ===")
            S.ltk = nil
        end
    end

    if not S.inM then return end

    -- Get player info
    local pc = GetPC() if not pc then return end
    local ps = GetPS() if not ps then return end
    local alive = false pcall(function() alive = ps:IsAlive() end)
    if not alive then return end
    local myChar = GetCh(pc) if not myChar then return end

    -- My position
    local mp = nil pcall(function() mp = myChar:K2_GetActorLocation() end)
    if not mp then return end
    local myEye = {X=mp.X, Y=mp.Y, Z=mp.Z + CFG.MY_EYE_Z}

    -- Current rotation
    local cr = nil pcall(function() cr = pc:GetControlRotation() end)
    if not cr then return end

    -- Get enemies
    local enemies = GetEnemies()

    -- === AIMBOT (every tick) ===
    DoAimbot(enemies, myChar, myEye, cr, pc)

    -- === ESP + CALLOUT + SMOKE (at intervals) ===
    S.espAcc = S.espAcc + dt
    if S.espAcc >= CFG.ESP_INTERVAL then
        S.espAcc = 0
        if #enemies > 0 then
            DoESPOutline(enemies, myChar)
            DoESPDraw3D(enemies, myEye)
            DoSpikeTracker(enemies)
            DoAutoCallout(enemies, myChar)
        end
        DoSmokeRemover()
    end

    -- Periodic status log
    if S.tc % 500 == 0 then
        L("[STATUS] tick=" .. S.tc .. " enemies=" .. #enemies
          .. " firing=" .. tostring(IsFiring(myChar))
          .. " outlined=" .. tostring(next(S.outlinedEnemies) ~= nil))
    end
end

----------------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------------
pcall(function()
    local f = io.open(CFG.LOGP, "w")
    if f then f:write("") f:close() end
end)

L("╔══════════════════════════════════════╗")
L("║      MEGA HACK v1.0 - All Features  ║")
L("╚══════════════════════════════════════╝")
L("ESP Outline:   " .. tostring(CFG.ESP_OUTLINE))
L("ESP Draw3D:    " .. tostring(CFG.ESP_DRAW3D))
L("Smoke Remover: " .. tostring(CFG.SMOKE_REMOVER))
L("Auto Callout:  " .. tostring(CFG.AUTO_CALLOUT))
L("Aimbot:        " .. tostring(CFG.AIMBOT))
L("Spike Tracker: " .. tostring(CFG.SPIKE_TRACKER))
L("FOV=" .. CFG.FOV .. " Smooth=" .. CFG.AIM_SMOOTH)

if ok_tt then
    LazyInit()
    TT.AddTimerLoop(CFG.TICK, OnTick)
    L("[BOOT] Timer started! Tick=" .. CFG.TICK)
else
    L("[FATAL] TimeTicker not found!")
end
