-- SKIN CHANGER v5.0 — Direct AvatarComp PutOnEquipment
----------------------------------------------------------------------
local CFG = {
    LOG  = true,
    LOGP = "/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/skin_log3.txt",
    
    -- Set desired skins (AvatarID from your skin list)
    DESIRED_SKINS = {
        [10101] = 101010400,   -- Classic -> 琉璃幻梦
        -- [10104] = 104003011,   -- Ghost -> 天界神兵
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
L("║  SKIN CHANGER v5.0 — PutOnEquipment ║")
L("╚══════════════════════════════════════╝")

local function SR(n) local o,v = pcall(require, n) return o and v or nil end
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
-- DIRECT SKIN CHANGE using AvatarComp internals
----------------------------------------------------------------------
local function TryDirectSkinChange(weaponObj, targetAvatarID)
    local avComp = nil
    pcall(function() avComp = weaponObj.AvatarComp end)
    if not avComp or not slua_isValid(avComp) then
        L("  [X] No AvatarComp!")
        return false
    end
    
    -- Step 1: Check if target skin's PAK is ready
    local pakReady = false
    pcall(function()
        local WeaponUtil = require("Game.Mod.BaseMod.GamePlay.Core.Components.Avatar.WeaponUtil")
        if WeaponUtil and WeaponUtil.IsAvatarPakRdy then
            pakReady = WeaponUtil:IsAvatarPakRdy(targetAvatarID)
        end
    end)
    L("  [1] IsAvatarPakRdy(" .. targetAvatarID .. ") = " .. tostring(pakReady))
    
    -- Step 2: Get data asset path for target skin
    local targetPath = ""
    pcall(function()
        targetPath = avComp:InternalGetDataAssetPath(targetAvatarID)
    end)
    L("  [2] DataAssetPath = " .. tostring(targetPath))
    
    -- Step 3: Get current data asset path for comparison
    local curAvatarID = 0
    pcall(function() curAvatarID = weaponObj:GetWeaponAvatarID() end)
    local curPath = ""
    pcall(function()
        curPath = avComp:InternalGetDataAssetPath(curAvatarID)
    end)
    L("  [3] Current path = " .. tostring(curPath))
    
    -- Step 4: Try PutOnEquipment with target AvatarID
    -- This is the KEY function — it's called in OnWeaponAvatarChange
    -- and has NO GIsDSOrStandalone check!
    local putOnOK = false
    pcall(function()
        -- FSGAvatarItemDefineID structure
        local itemDef = FSGAvatarItemDefineID()
        itemDef.ItemType = 12
        itemDef.ItemID = targetAvatarID
        avComp:PutOnEquipment(itemDef)
        putOnOK = true
        L("  [4] PutOnEquipment(" .. targetAvatarID .. ") OK!")
    end)
    
    if not putOnOK then
        -- Try alternative: construct the struct differently
        pcall(function()
            local itemDef = {ItemType = 12, ItemID = targetAvatarID}
            avComp:PutOnEquipment(itemDef)
            L("  [4b] PutOnEquipment(table) OK!")
            putOnOK = true
        end)
    end
    
    -- Step 5: Try CheckAvatarDataDirty to force refresh
    pcall(function()
        avComp:CheckAvatarDataDirty()
        L("  [5] CheckAvatarDataDirty OK!")
    end)
    
    -- Step 6: Try to force data asset reload
    pcall(function()
        if targetPath ~= "" then
            local SGAssetLoadLibrary = SGAssetLoadLibrary
            if SGAssetLoadLibrary then
                local dataAsset = SGAssetLoadLibrary.GetDataAsset(targetPath)
                L("  [6] SGAssetLoadLibrary.GetDataAsset = " .. tostring(dataAsset ~= nil))
            end
        end
    end)
    
    -- Step 7: Try GetMasterMesh + change mesh/material
    pcall(function()
        local masterMesh = weaponObj:GetMasterMesh()
        if masterMesh then
            L("  [7] GetMasterMesh = " .. tostring(masterMesh))
            -- Log mesh info
            pcall(function()
                local mesh = masterMesh:GetSkeletalMeshAsset()
                L("  [7] SkeletalMeshAsset = " .. tostring(mesh))
            end)
            pcall(function()
                local numMats = masterMesh:GetNumMaterials()
                L("  [7] NumMaterials = " .. tostring(numMats))
            end)
        else
            L("  [7] No MasterMesh")
        end
    end)
    
    -- Step 8: List all weapon components
    pcall(function()
        local compTypes = {0,1,2,3,4,5,6,7,8,9,10}
        for _, ct in ipairs(compTypes) do
            pcall(function()
                local comp = weaponObj:GetWeaponComponent(ct)
                if comp and slua_isValid(comp) then
                    L("  [8] WeaponComponent[" .. ct .. "] = " .. tostring(comp))
                end
            end)
        end
    end)
    
    -- Verify
    local newAvatarID = 0
    pcall(function() newAvatarID = weaponObj:GetWeaponAvatarID() end)
    L("  [RESULT] AvatarID: " .. curAvatarID .. " -> " .. newAvatarID)
    
    return putOnOK
end

----------------------------------------------------------------------
-- TRY ALL SKINS IN LIST to find which ones have PAK ready
----------------------------------------------------------------------
local function ScanAvailableSkins(avComp, weaponID)
    L("")
    L("=== SCAN: Which skins have assets ready? ===")
    
    -- Test skins for Classic (10101)
    local testSkins = {}
    if weaponID == 10101 then
        testSkins = {
            101000000, -- Default
            101010400, -- 琉璃幻梦
            101001000, -- 涂鸦艺廊
            101002100, -- 寒冬兵器
            101050600, -- 国王工设
            101001200, -- 樱花
            101002401, -- 源能者危机001
            101004211, -- 紫阙金琅_标准
            101005011, -- 万铀引力辐爆者_标准
            101005110, -- 无垠星环_标准
        }
    elseif weaponID == 10901 then
        -- Test some knife skins
        testSkins = {901000000}
    end
    
    for _, skinID in ipairs(testSkins) do
        local pakRdy = "?"
        local path = "?"
        pcall(function()
            local WeaponUtil = require("Game.Mod.BaseMod.GamePlay.Core.Components.Avatar.WeaponUtil")
            pakRdy = tostring(WeaponUtil:IsAvatarPakRdy(skinID))
        end)
        pcall(function()
            path = avComp:InternalGetDataAssetPath(skinID)
        end)
        L("  Skin " .. skinID .. " | PAK=" .. pakRdy .. " | Path=" .. tostring(path))
    end
end

----------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------
local applied = false
local checkAcc = 0
local checkCount = 0

local function OnTick(dt)
    if applied then return end
    checkAcc = checkAcc + dt
    if checkAcc < 1.0 then return end
    checkAcc = 0
    checkCount = checkCount + 1
    if checkCount > 30 then applied = true L("[TIMEOUT]") return end
    
    local pc = GetPC()
    local ps = GetPS()
    local ch = pc and GetCh(pc)
    if not ch then return end
    
    local wl = nil
    pcall(function() wl = ch:GetWeaponList() end)
    if not wl or wl:Num() == 0 then
        if checkCount <= 5 or checkCount % 5 == 0 then
            L("[WAIT] t=" .. checkCount .. "s weapons=0")
        end
        return
    end
    
    applied = true
    L("")
    L("========================================")
    L("  WEAPONS READY! Count=" .. wl:Num() .. " at t=" .. checkCount .. "s")
    L("========================================")
    
    -- Process each weapon
    for i = 0, wl:Num() - 1 do
        local w = wl:Get(i)
        if w and slua_isValid(w) then
            local wid, avid = 0, 0
            pcall(function() wid = w:GetWeaponID() end)
            pcall(function() avid = w:GetWeaponAvatarID() end)
            L("  Weapon[" .. i .. "] ID=" .. wid .. " AvatarID=" .. avid)
            
            -- Scan available skins for this weapon
            local avComp = nil
            pcall(function() avComp = w.AvatarComp end)
            if avComp and slua_isValid(avComp) then
                ScanAvailableSkins(avComp, wid)
            end
            
            -- Try to change skin
            local targetSkin = CFG.DESIRED_SKINS[wid]
            if targetSkin then
                L("")
                L("=== CHANGING WeaponID=" .. wid .. " to Skin=" .. targetSkin .. " ===")
                TryDirectSkinChange(w, targetSkin)
            end
        end
    end
    
    L("")
    L("=== COMPLETE ===")
end

if ok_tt then
    TT.AddTimerLoop(0.02, OnTick)
    L("[BOOT] Waiting for weapons...")
else
    L("[FATAL] No TimeTicker!")
end
