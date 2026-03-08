-- SKIN CHANGER v3.0 — Force All Methods + Deep Debug
----------------------------------------------------------------------
local CFG = {
    LOG  = true,
    LOGP = "/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/skin_log.txt",
    
    DESIRED_SKINS = {
        [10101] = 101005011,   -- Classic -> 万铀引力辐爆者
        [10104] = 104003011,   -- Ghost -> 天界神兵
        [10103] = 103003111,   -- Frenzy -> 全息波普
    },
}

local function L(m)
    if not CFG.LOG then return end
    pcall(function()
        local f = io.open(CFG.LOGP, "a")
        if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(m) .. "\n") f:close() end
    end)
end
pcall(function() local f=io.open(CFG.LOGP,"w") if f then f:write("") f:close() end end)
L("╔══════════════════════════════════════╗")
L("║  SKIN CHANGER v3.0 — Deep Force     ║")
L("╚══════════════════════════════════════╝")

----------------------------------------------------------------------
local function SR(n) local o,v = pcall(require, n) return o and v or nil end
local function SIL(n) local o,v = pcall(function() return import_func_lib(n) end) return o and v or nil end

local GP = SIL("GameplayStatics")
local RPCSender = SR("Game.Core.RPC.RPCSender")
local GameSystemUtil = SR("Game.Core.Util.GameSystemUtil")
local ok_tt, TT = pcall(require, "Common.Framework.TimeTicker")

local function GetPC()
    if GameAPI and GameAPI.GetPlayerController then
        local o,p = pcall(function() return GameAPI.GetPlayerController() end)
        if o and p and slua_isValid(p) then return p end
    end
    if GP then
        local o,p = pcall(function() return GP.GetPlayerController(slua_getWorld(), 0) end)
        if o and p and slua_isValid(p) then return p end
    end
end
local function GetPS()
    if GameAPI and GameAPI.GetPlayerState then
        local o,p = pcall(function() return GameAPI.GetPlayerState() end)
        if o and p and slua_isValid(p) then return p end
    end
    local pc = GetPC()
    if pc then
        local o,p = pcall(function() return pc.PlayerState end)
        if o and p and slua_isValid(p) then return p end
        local o2,p2 = pcall(function() return pc:GetSGPlayerState() end)
        if o2 and p2 and slua_isValid(p2) then return p2 end
    end
end
local function GetCh(pc)
    if not pc then return end
    local o,c = pcall(function() return pc:GetSGBaseCharacter() end)
    if o and c and slua_isValid(c) then return c end
    local o2,c2 = pcall(function() return pc:K2_GetPawn() end)
    if o2 and c2 and slua_isValid(c2) then return c2 end
end

----------------------------------------------------------------------
-- DEEP DIAGNOSE: Understand the full state
----------------------------------------------------------------------
local function DeepDiagnose()
    L("=== DEEP DIAGNOSE ===")
    
    local pc = GetPC()
    L("[D] PlayerController: " .. tostring(pc ~= nil))
    if not pc then return end
    
    local ps = GetPS()
    L("[D] PlayerState: " .. tostring(ps ~= nil))
    
    local ch = GetCh(pc)
    L("[D] Character: " .. tostring(ch ~= nil))
    
    if not ch then return end
    
    -- Check all properties on character related to weapons
    local weaponList = nil
    pcall(function() weaponList = ch:GetWeaponList() end)
    L("[D] GetWeaponList: " .. tostring(weaponList ~= nil))
    
    if weaponList then
        L("[D] WeaponList:Num() = " .. tostring(weaponList:Num()))
        for i = 0, weaponList:Num() - 1 do
            local w = weaponList:Get(i)
            if w and slua_isValid(w) then
                local wid, avid, avcomp = 0, 0, nil
                pcall(function() wid = w:GetWeaponID() end)
                pcall(function() avid = w:GetWeaponAvatarID() end)
                pcall(function() avcomp = w.AvatarComp end)
                L("[D]   W[" .. i .. "] ID=" .. tostring(wid) .. " AvID=" .. tostring(avid) 
                    .. " AvatarComp=" .. tostring(avcomp ~= nil and slua_isValid(avcomp)))
                
                -- Explore weapon object properties
                local props = {}
                for _, pn in ipairs({"ResID","WeaponAvatarID","AvatarID","SkinID","WeaponSkinID"}) do
                    pcall(function()
                        local v = w[pn]
                        if v ~= nil then props[#props+1] = pn .. "=" .. tostring(v) end
                    end)
                end
                if #props > 0 then L("[D]     Props: " .. table.concat(props, ", ")) end
                
                -- Check AvatarComp methods
                if avcomp and slua_isValid(avcomp) then
                    local acProps = {}
                    for _, pn in ipairs({"AvatarID","CurAvatarID","SkinID","WeaponSkinID","bIsInit"}) do
                        pcall(function()
                            local v = avcomp[pn]
                            if v ~= nil then acProps[#acProps+1] = pn .. "=" .. tostring(v) end
                        end)
                    end
                    if #acProps > 0 then L("[D]     AvatarComp: " .. table.concat(acProps, ", ")) end
                end
            end
        end
    end
    
    -- Check SGEquipment
    if ps then
        local eq = nil
        pcall(function() eq = ps.SGEquipment end)
        L("[D] SGEquipment: " .. tostring(eq ~= nil and slua_isValid(eq)))
        
        if eq and slua_isValid(eq) then
            -- Try to get current active weapon
            pcall(function()
                local slot = eq:GetCurActiveSlotID()
                L("[D] ActiveSlotID: " .. tostring(slot))
            end)
        end
        
        -- Check PlayerInfo deeply
        local pi = nil
        pcall(function() pi = ps.PlayerInfo end)
        L("[D] PlayerInfo: " .. tostring(pi ~= nil))
        
        if pi then
            local piProps = {}
            for _, pn in ipairs({"PlayerName","PlayerKey","DefaultWeaponBackpackId","AgentSkinList","AllWeaponBackpack","WeaponSkinDetails","WeaponPendantMap"}) do
                pcall(function()
                    local v = pi[pn]
                    if v ~= nil then
                        if type(v) == "table" then
                            piProps[#piProps+1] = pn .. "=table(#" .. tostring(#v) .. ")"
                        else
                            piProps[#piProps+1] = pn .. "=" .. tostring(v)
                        end
                    end
                end)
            end
            L("[D] PlayerInfo: " .. table.concat(piProps, ", "))
        end
        
        -- Check WeaponAvatarOverrideInfo - try to create it if missing
        local ovrExists = false
        pcall(function() ovrExists = (ps.WeaponAvatarOverrideInfo ~= nil) end)
        L("[D] WeaponAvatarOverrideInfo exists: " .. tostring(ovrExists))
        
        -- List all Lua properties on PlayerState
        local psLuaProps = {}
        pcall(function()
            for k, v in pairs(ps) do
                if type(k) == "string" and (k:find("Weapon") or k:find("Skin") or k:find("Avatar") or k:find("Backpack")) then
                    psLuaProps[#psLuaProps+1] = k .. "=" .. tostring(type(v))
                end
            end
        end)
        if #psLuaProps > 0 then
            L("[D] PS weapon-related props: " .. table.concat(psLuaProps, ", "))
        end
        
        -- Check type of PlayerState (is it Lua-extended?)
        pcall(function()
            local mt = getmetatable(ps)
            L("[D] PS metatable: " .. tostring(mt))
            if mt then
                L("[D] PS metatable type: " .. tostring(type(mt)))
                if type(mt) == "table" and mt.__index then
                    L("[D] PS has __index: " .. tostring(type(mt.__index)))
                end
            end
        end)
        
        -- Try to iterate PS with pcall to find any weapon functions
        local wepFuncs = {}
        pcall(function()
            for k, v in pairs(ps) do
                if type(v) == "function" and type(k) == "string" then
                    if k:find("Weapon") or k:find("Skin") or k:find("Avatar") or k:find("Equip") then
                        wepFuncs[#wepFuncs+1] = k
                    end
                end
            end
        end)
        if #wepFuncs > 0 then
            L("[D] PS weapon functions: " .. table.concat(wepFuncs, ", "))
        end
    end
end

----------------------------------------------------------------------
-- TRY ALL SKIN CHANGE METHODS
----------------------------------------------------------------------
local function TryChangeSkins()
    L("")
    L("=== TRYING SKIN CHANGES ===")
    
    local pc = GetPC()
    local ps = GetPS()
    local ch = pc and GetCh(pc)
    if not pc or not ps or not ch then
        L("[ERR] Missing pc/ps/ch: " .. tostring(pc~=nil) .. "/" .. tostring(ps~=nil) .. "/" .. tostring(ch~=nil))
        return
    end
    
    -- Get weapon list
    local weaponList = nil
    pcall(function() weaponList = ch:GetWeaponList() end)
    if not weaponList then L("[ERR] No weapon list!") return end
    
    for weaponID, targetSkinID in pairs(CFG.DESIRED_SKINS) do
        L("")
        L("--- Changing WeaponID=" .. weaponID .. " to Skin=" .. targetSkinID .. " ---")
        
        -- Find weapon object
        local weaponObj = nil
        for i = 0, weaponList:Num() - 1 do
            local w = weaponList:Get(i)
            if w and slua_isValid(w) then
                local wid = 0
                pcall(function() wid = w:GetWeaponID() end)
                if wid == weaponID then
                    weaponObj = w
                    break
                end
            end
        end
        
        if not weaponObj then
            L("  Weapon " .. weaponID .. " not in inventory, skipping")
        else
            local curAvatar = 0
            pcall(function() curAvatar = weaponObj:GetWeaponAvatarID() end)
            L("  Current AvatarID: " .. tostring(curAvatar))
            
            -- METHOD A: Create WeaponAvatarOverrideInfo if missing, then override
            pcall(function()
                if not ps.WeaponAvatarOverrideInfo then
                    ps.WeaponAvatarOverrideInfo = {}
                    L("  [A] Created WeaponAvatarOverrideInfo table")
                end
                ps.WeaponAvatarOverrideInfo[weaponID] = {targetSkinID}
                L("  [A] Set override: " .. weaponID .. " -> {" .. targetSkinID .. "}")
                
                -- Try ApplyWeaponAvatarImmediately
                pcall(function()
                    ps:ApplyWeaponAvatarImmediately(weaponID)
                    L("  [A] ApplyWeaponAvatarImmediately OK!")
                end)
            end)
            
            -- METHOD B: Try SetWeaponAvatarOverride directly
            pcall(function()
                ps:SetWeaponAvatarOverride(weaponID, {targetSkinID})
                L("  [B] SetWeaponAvatarOverride OK!")
            end)
            
            -- METHOD C: Try direct AvatarComp modification
            pcall(function()
                local avComp = weaponObj.AvatarComp
                if avComp and slua_isValid(avComp) then
                    -- Try to find reinit or reload function
                    local methods = {}
                    pcall(function()
                        for k,v in pairs(avComp) do
                            if type(v) == "function" and type(k) == "string" then
                                methods[#methods+1] = k
                            end
                        end
                    end)
                    L("  [C] AvatarComp methods: " .. table.concat(methods, ", "))
                    
                    -- Try setting AvatarID directly
                    pcall(function() avComp.AvatarID = targetSkinID; L("  [C] Set AvatarID=" .. targetSkinID) end)
                    pcall(function() avComp.CurAvatarID = targetSkinID; L("  [C] Set CurAvatarID=" .. targetSkinID) end)
                    pcall(function() avComp:SetAvatarID(targetSkinID); L("  [C] SetAvatarID() OK!") end)
                    pcall(function() avComp:InitAvatar(targetSkinID); L("  [C] InitAvatar() OK!") end)
                    pcall(function() avComp:ReloadAvatar(targetSkinID); L("  [C] ReloadAvatar() OK!") end)
                    pcall(function() avComp:ChangeAvatar(targetSkinID); L("  [C] ChangeAvatar() OK!") end)
                else
                    L("  [C] No valid AvatarComp")
                end
            end)
            
            -- METHOD D: Equipment Remove + Re-add (force refresh)
            pcall(function()
                local eq = ps.SGEquipment
                if eq and slua_isValid(eq) then
                    local itemID = eq:GetItemID(weaponID)
                    if itemID then
                        local acq = eq:GetItemAcquireType(itemID)
                        L("  [D] Current AcquireType=" .. tostring(acq))
                        eq:RemoveItemsByResID(weaponID)
                        eq:AddItemByResID(weaponID, 1, acq or 0)
                        L("  [D] Re-equipped weapon " .. weaponID)
                    else
                        L("  [D] No itemID for weapon " .. weaponID)
                    end
                end
            end)
            
            -- METHOD E: ServerRPC from Training
            pcall(function()
                if RPCSender then
                    RPCSender:Server("ServerRPC_ChangeWeaponAvatar", 1, weaponID, targetSkinID, true)
                    L("  [E] ServerRPC sent")
                end
            end)
            
            -- METHOD F: RequestWeaponSkinList (standard mode RPC)
            pcall(function()
                if RPCSender then
                    RPCSender:Server("ServerRPC_RequestWeaponSkinList", 1)
                    L("  [F] RequestWeaponSkinList sent")
                end
            end)
            
            -- METHOD G: ActivateWeaponSkinList
            pcall(function()
                if RPCSender then
                    RPCSender:Server("ServerRPC_ActivateWeaponSkinList", 1)
                    L("  [G] ActivateWeaponSkinList sent")
                end
            end)
            
            -- Verify
            pcall(function()
                local newAvatar = weaponObj:GetWeaponAvatarID()
                L("  [VERIFY] AvatarID now: " .. tostring(newAvatar) .. (newAvatar ~= curAvatar and " CHANGED!" or " unchanged"))
            end)
        end
    end
end

----------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------
local applied = false
local tc = 0

local function OnTick(dt)
    tc = tc + 1
    if applied then return end
    
    local ps = GetPS()
    if not ps then return end
    local alive = false
    pcall(function() alive = ps:IsAlive() end)
    if not alive then return end
    if tc < 150 then return end
    
    applied = true
    DeepDiagnose()
    TryChangeSkins()
end

if ok_tt then
    TT.AddTimerLoop(0.02, OnTick)
    L("[BOOT] Timer started...")
else
    L("[FATAL] TimeTicker not found!")
end
