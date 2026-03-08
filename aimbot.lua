-- SKIN CHANGER v2.0 — Real Skin IDs + All Methods
----------------------------------------------------------------------
local CFG = {
    LOG  = true,
    LOGP = "/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/skin_log.txt",

    ---------------------------------------------------------------
    -- 🎨 CHANGE YOUR DESIRED SKINS HERE!
    -- Set the AvatarID you want for each weapon
    -- Set to nil/false to keep default skin
    ---------------------------------------------------------------
    DESIRED_SKINS = {
        -- Classic (CLA = 10101)
        [10101] = 101005011,   -- 万铀引力辐爆者_标准_基础

        -- Ghost (GHO = 10104)
        [10104] = 104003011,   -- 天界神兵_标准_基础

        -- Frenzy (FRE = 10103)
        [10103] = 103003111,   -- 全息波普_标准_基础

        -- Phantom (PHA = 10403)
        -- [10403] = XXXXXX,   -- Add Phantom skin ID here

        -- Vandal (VAN = 10404)
        -- [10404] = XXXXXX,   -- Add Vandal skin ID here

        -- Knife (JD = 10901)
        -- [10901] = XXXXXX,   -- Add knife skin ID here
    },
}

----------------------------------------------------------------------
-- ALL KNOWN SKINS DATABASE
----------------------------------------------------------------------
local SKIN_DB = {
    -- ===== Classic (标配) 10101 =====
    {id=101000000, name="Classic - Default"},
    {id=101010400, name="Classic - 琉璃幻梦"},
    {id=101001000, name="Classic - 涂鸦艺廊"},
    {id=101002100, name="Classic - 寒冬兵器"},
    {id=101050600, name="Classic - 国王工设"},
    {id=101001200, name="Classic - 樱花"},
    {id=101002401, name="Classic - 源能者危机001_基础"},
    {id=101004211, name="Classic - 紫阙金琅_标准"},
    {id=101004221, name="Classic - 紫阙金琅_橙色"},
    {id=101004231, name="Classic - 紫阙金琅_蓝色"},
    {id=101004241, name="Classic - 紫阙金琅_黄色"},
    {id=101005011, name="Classic - 万铀引力辐爆者_标准"},
    {id=101005021, name="Classic - 万铀引力辐爆者_合金"},
    {id=101005031, name="Classic - 万铀引力辐爆者_黑色"},
    {id=101005041, name="Classic - 万铀引力辐爆者_红蓝白"},
    {id=101005110, name="Classic - 无垠星环_标准"},
    {id=101005120, name="Classic - 无垠星环_绿色"},
    {id=101005130, name="Classic - 无垠星环_红色"},
    {id=101005140, name="Classic - 无垠星环_蓝色"},
    -- ===== Shorty (短炮) 10102 =====
    {id=102000000, name="Shorty - Default"},
    {id=102002600, name="Shorty - 异彩晶棱II"},
    {id=102051800, name="Shorty - 质感轻奢"},
    {id=102001800, name="Shorty - 废土"},
    -- ===== Frenzy (狂怒) 10103 =====
    {id=103000000, name="Frenzy - Default"},
    {id=103002800, name="Frenzy - 炽红快攻"},
    {id=103051800, name="Frenzy - 质感轻奢"},
    {id=103000300, name="Frenzy - 炫彩澎湃"},
    {id=103006100, name="Frenzy - 泰坦兵器"},
    {id=103010300, name="Frenzy - 巨神铁甲"},
    {id=103001100, name="Frenzy - 漫天彩霞"},
    {id=103002311, name="Frenzy - 起源_标准"},
    {id=103000700, name="Frenzy - 金角生辉"},
    {id=103003111, name="Frenzy - 全息波普_标准"},
    {id=103003121, name="Frenzy - 全息波普_蓝色"},
    {id=103003131, name="Frenzy - 全息波普_红色"},
    {id=103003141, name="Frenzy - 全息波普_金色"},
    -- ===== Ghost (鬼魅) 10104 =====
    {id=104000000, name="Ghost - Default"},
    {id=104001600, name="Ghost - 合金突袭"},
    {id=104051710, name="Ghost - 本色混搭_贤者"},
    {id=104051720, name="Ghost - 本色混搭_斯凯"},
    {id=104002500, name="Ghost - 异彩晶棱"},
    {id=104003011, name="Ghost - 天界神兵_标准"},
    {id=104003021, name="Ghost - 天界神兵_绿色"},
    {id=104003031, name="Ghost - 天界神兵_银色"},
    {id=104005311, name="Ghost - 侦查力量_标准"},
    {id=104005321, name="Ghost - 侦查力量_红色迷彩"},
    {id=104005331, name="Ghost - 侦查力量_蓝色迷彩"},
    {id=104005341, name="Ghost - 侦查力量_绿色迷彩"},
    {id=104004711, name="Ghost - 奇幻朋克_标准"},
    {id=104004721, name="Ghost - 奇幻朋克_绿色"},
    {id=104004731, name="Ghost - 奇幻朋克_紫色"},
    {id=104004741, name="Ghost - 奇幻朋克_橙色"},
    {id=104003810, name="Ghost - 无人之境_标准"},
    {id=104004400, name="Ghost - 无畏契约第一卷"},
    {id=104006314, name="Ghost - 盖亚的复仇_红色"},
    {id=104006324, name="Ghost - 盖亚的复仇_蓝色"},
    {id=104006334, name="Ghost - 盖亚的复仇_绿色"},
}

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

pcall(function() local f=io.open(CFG.LOGP,"w") if f then f:write("") f:close() end end)
L("╔══════════════════════════════════════╗")
L("║  SKIN CHANGER v2.0 — Real IDs       ║")
L("╚══════════════════════════════════════╝")

----------------------------------------------------------------------
-- IMPORTS
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

----------------------------------------------------------------------
-- DIAGNOSE: Log current weapon skins
----------------------------------------------------------------------
local function LogCurrentWeapons(tag)
    local pc = GetPC()
    local ch = pc and GetCh(pc)
    if not ch then L("[" .. tag .. "] No character") return end
    pcall(function()
        local weapons = ch:GetWeaponList()
        if weapons then
            for i = 0, weapons:Num() - 1 do
                local w = weapons:Get(i)
                if slua_isValid(w) then
                    local wid = w:GetWeaponID()
                    local avid = w:GetWeaponAvatarID()
                    L("[" .. tag .. "] Weapon ID=" .. tostring(wid) .. " AvatarID=" .. tostring(avid))
                end
            end
        end
    end)
end

----------------------------------------------------------------------
-- METHOD 1: SetWeaponAvatarOverride (best chance — no ownership check)
----------------------------------------------------------------------
local function Method1_Override(ps, weaponID, skinID)
    local ok = false
    -- Try the function directly
    pcall(function()
        ps:SetWeaponAvatarOverride(weaponID, {skinID})
        ok = true
        L("[M1] SetWeaponAvatarOverride(" .. weaponID .. ", {" .. skinID .. "}) OK")
    end)
    if ok then return true end
    -- Fallback: direct table + manual apply
    pcall(function()
        ps.WeaponAvatarOverrideInfo[weaponID] = {skinID}
        L("[M1] Direct table set OK")
        pcall(function()
            ps:ApplyWeaponAvatarImmediately(weaponID)
            L("[M1] ApplyWeaponAvatarImmediately OK")
            ok = true
        end)
    end)
    return ok
end

----------------------------------------------------------------------
-- METHOD 2: Modify PlayerInfo backpack data
----------------------------------------------------------------------
local function Method2_Backpack(ps, weaponID, skinID)
    local ok = false
    pcall(function()
        local pi = ps.PlayerInfo
        if not pi then L("[M2] No PlayerInfo") return end
        local bpId = pi.DefaultWeaponBackpackId or 1
        local awb = pi.AllWeaponBackpack
        if not awb or not awb[bpId] then L("[M2] No backpack") return end
        local bp = awb[bpId]
        if not bp.WeaponSkinList then L("[M2] No WeaponSkinList") return end
        
        local found = false
        for _, ws in ipairs(bp.WeaponSkinList) do
            if ws.WeaponID == weaponID then
                local old = ws.SkinList[1]
                ws.SkinList = {skinID}
                L("[M2] WeaponID=" .. weaponID .. ": " .. tostring(old) .. " -> " .. skinID)
                found = true
                ok = true
                break
            end
        end
        if not found then
            bp.WeaponSkinList[#bp.WeaponSkinList + 1] = {WeaponID = weaponID, SkinList = {skinID}}
            L("[M2] Added new skin entry")
            ok = true
        end
    end)
    return ok
end

----------------------------------------------------------------------
-- METHOD 3: ServerRPC (Training mode)
----------------------------------------------------------------------
local function Method3_RPC(weaponID, skinID)
    if not RPCSender then return false end
    local ok = false
    pcall(function()
        RPCSender:Server("ServerRPC_ChangeWeaponAvatar", 1, weaponID, skinID, true)
        L("[M3] ServerRPC_ChangeWeaponAvatar sent: wep=" .. weaponID .. " skin=" .. skinID)
        ok = true
    end)
    return ok
end

----------------------------------------------------------------------
-- METHOD 4: Re-equip weapon (forces skin refresh)
----------------------------------------------------------------------
local function Method4_ReEquip(ps, weaponID)
    local ok = false
    pcall(function()
        local eq = ps.SGEquipment
        if not slua_isValid(eq) then L("[M4] No SGEquipment") return end
        local itemID = eq:GetItemID(weaponID)
        if not itemID then L("[M4] Weapon " .. weaponID .. " not in inventory") return end
        local acqType = eq:GetItemAcquireType(itemID)
        eq:RemoveItemsByResID(weaponID)
        eq:AddItemByResID(weaponID, 1, acqType or 0)
        L("[M4] Re-equipped weapon " .. weaponID .. " (AcqType=" .. tostring(acqType) .. ")")
        ok = true
    end)
    return ok
end

----------------------------------------------------------------------
-- METHOD 5: WeaponSkinDetails injection (fake ownership)
----------------------------------------------------------------------
local function Method5_FakeOwnership(ps, weaponID, skinID)
    local ok = false
    pcall(function()
        local pi = ps.PlayerInfo
        if not pi then return end
        -- Try to get skin table data
        local skinData = nil
        pcall(function() skinData = SGTable_GetTableData("WeaponSkinTable", skinID) end)
        if not skinData then
            pcall(function() skinData = DataTableCacheManager.GetTableData("WeaponSkinTable", skinID) end)
        end
        if skinData then
            L("[M5] Found skin data: SkinGroupID=" .. tostring(skinData.SkinGroupID) .. " Level=" .. tostring(skinData.Level))
            -- Inject into WeaponSkinDetails
            if not pi.WeaponSkinDetails then pi.WeaponSkinDetails = {} end
            pi.WeaponSkinDetails[skinData.SkinGroupID] = {
                Level = skinData.Level or 1,
                FormIdList = {skinData.FormIndex or 0}
            }
            L("[M5] Injected fake ownership for SkinGroupID=" .. tostring(skinData.SkinGroupID))
            ok = true
        else
            L("[M5] Skin " .. skinID .. " not in WeaponSkinTable")
        end
    end)
    return ok
end

----------------------------------------------------------------------
-- APPLY ALL DESIRED SKINS
----------------------------------------------------------------------
local function ApplyAllSkins()
    L("")
    L("========================================")
    L("  APPLYING SKINS")
    L("========================================")
    
    local ps = GetPS()
    if not ps then L("[ERR] No PlayerState!") return end
    
    -- Log current state
    LogCurrentWeapons("BEFORE")
    
    -- Log PlayerInfo state
    pcall(function()
        local pi = ps.PlayerInfo
        if pi then
            L("[INFO] BackpackID=" .. tostring(pi.DefaultWeaponBackpackId))
            L("[INFO] WeaponAvatarOverrideInfo exists=" .. tostring(ps.WeaponAvatarOverrideInfo ~= nil))
        end
    end)
    
    for weaponID, skinID in pairs(CFG.DESIRED_SKINS) do
        if skinID then
            L("")
            L("--- WeaponID=" .. weaponID .. " -> SkinID=" .. skinID .. " ---")
            
            -- Find skin name from DB
            for _, s in ipairs(SKIN_DB) do
                if s.id == skinID then
                    L("    Skin: " .. s.name)
                    break
                end
            end
            
            -- Try Method 5 first (fake ownership)
            Method5_FakeOwnership(ps, weaponID, skinID)
            
            -- Try Method 1 (override — best chance)
            local m1 = Method1_Override(ps, weaponID, skinID)
            L("    M1 Override: " .. tostring(m1))
            
            -- Try Method 2 (backpack modify)
            local m2 = Method2_Backpack(ps, weaponID, skinID)
            L("    M2 Backpack: " .. tostring(m2))
            
            -- Try Method 3 (server RPC — training only)
            local m3 = Method3_RPC(weaponID, skinID)
            L("    M3 RPC: " .. tostring(m3))
            
            -- Try Method 4 (re-equip to refresh)
            if m1 or m2 then
                local m4 = Method4_ReEquip(ps, weaponID)
                L("    M4 ReEquip: " .. tostring(m4))
            end
        end
    end
    
    -- Verify after
    L("")
    LogCurrentWeapons("AFTER")
    
    L("")
    L("========================================")
    L("  DONE — Check your weapons in-game!")
    L("========================================")
end

----------------------------------------------------------------------
-- MAIN LOOP: Wait for match, then apply once
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
    
    -- Wait 3 seconds after alive
    if tc < 150 then return end
    
    applied = true
    ApplyAllSkins()
end

----------------------------------------------------------------------
-- STARTUP
----------------------------------------------------------------------
L("Desired skins:")
for wid, sid in pairs(CFG.DESIRED_SKINS) do
    if sid then
        local name = "Unknown"
        for _, s in ipairs(SKIN_DB) do
            if s.id == sid then name = s.name break end
        end
        L("  WeaponID=" .. wid .. " -> " .. sid .. " (" .. name .. ")")
    end
end

if ok_tt then
    TT.AddTimerLoop(0.02, OnTick)
    L("[BOOT] Timer started, waiting for match...")
else
    L("[FATAL] TimeTicker not found!")
end
