-- CACHE CLEANER v2 — os.remove + file listing
----------------------------------------------------------------------
local CACHE_PATH = "/data/user/0/com.tencent.tmgp.codev/cache/"
local LOG_PATH = "/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/cache_log.txt"

local function L(m)
    pcall(function()
        local f = io.open(LOG_PATH, "a")
        if f then f:write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(m) .. "\n") f:close() end
    end)
end
pcall(function() local f=io.open(LOG_PATH,"w") if f then f:write("") f:close() end end)
L("╔══════════════════════════════════════╗")
L("║  CACHE CLEANER v2 — Smart Delete    ║")
L("╚══════════════════════════════════════╝")
L("Target: " .. CACHE_PATH)

----------------------------------------------------------------------
-- Check available APIs first
----------------------------------------------------------------------
L("")
L("=== API Check ===")

local hasUCVLib = false
pcall(function() hasUCVLib = (UCVFunctionLibrary ~= nil) end)
L("UCVFunctionLibrary: " .. tostring(hasUCVLib))

local hasCVLib = false
pcall(function() hasCVLib = (CVFunctionLibrary ~= nil) end)
L("CVFunctionLibrary: " .. tostring(hasCVLib))

local hasLFS = false
local lfs = nil
pcall(function() lfs = require("lfs") hasLFS = true end)
L("lfs (LuaFileSystem): " .. tostring(hasLFS))

L("os.remove: " .. tostring(os.remove ~= nil))
L("io.open: " .. tostring(io.open ~= nil))

----------------------------------------------------------------------
-- METHOD A: UCVFunctionLibrary (best — deletes whole directory)
----------------------------------------------------------------------
local function TryUCVLib()
    L("")
    L("=== Method A: UCVFunctionLibrary.DeleteFileOrDirectory ===")
    
    -- Try UCVFunctionLibrary
    if hasUCVLib then
        local ok, result = pcall(function()
            return UCVFunctionLibrary.DeleteFileOrDirectory(CACHE_PATH)
        end)
        L("[A] UCVFunctionLibrary result=" .. tostring(result) .. " ok=" .. tostring(ok))
        if ok then return true end
    end
    
    -- Try CVFunctionLibrary
    if hasCVLib then
        local ok, result = pcall(function()
            return CVFunctionLibrary.DeleteFileOrDirectory(CACHE_PATH)
        end)
        L("[A2] CVFunctionLibrary result=" .. tostring(result) .. " ok=" .. tostring(ok))
        if ok then return true end
    end
    
    -- Try importing
    local ok2, result2 = pcall(function()
        local lib = import_func_lib("CVFunctionLibrary")
        if lib and lib.DeleteFileOrDirectory then
            return lib.DeleteFileOrDirectory(CACHE_PATH)
        end
    end)
    L("[A3] import CVFunctionLibrary result=" .. tostring(result2) .. " ok=" .. tostring(ok2))
    return ok2
end

----------------------------------------------------------------------
-- METHOD B: lfs + os.remove (list files then delete individually)
----------------------------------------------------------------------
local deletedCount = 0
local failedCount = 0

local function DeleteRecursive_LFS(path)
    if not hasLFS then return false end
    
    for entry in lfs.dir(path) do
        if entry ~= "." and entry ~= ".." then
            local fullPath = path .. entry
            local attr = lfs.attributes(fullPath)
            if attr then
                if attr.mode == "directory" then
                    DeleteRecursive_LFS(fullPath .. "/")
                    local ok, err = os.remove(fullPath)
                    if ok then
                        deletedCount = deletedCount + 1
                    else
                        failedCount = failedCount + 1
                    end
                else
                    local ok, err = os.remove(fullPath)
                    if ok then
                        deletedCount = deletedCount + 1
                    else
                        failedCount = failedCount + 1
                        -- Try CVFunctionLibrary as fallback
                        if hasCVLib then
                            pcall(function() CVFunctionLibrary.DeleteFile(fullPath) deletedCount = deletedCount + 1 end)
                        end
                    end
                end
            end
        end
    end
    return true
end

local function TryLFS()
    L("")
    L("=== Method B: lfs.dir + os.remove ===")
    if not hasLFS then
        L("[B] lfs not available!")
        return false
    end
    
    deletedCount = 0
    failedCount = 0
    
    local ok = pcall(function() DeleteRecursive_LFS(CACHE_PATH) end)
    L("[B] Deleted: " .. deletedCount .. " Failed: " .. failedCount)
    
    -- Try to remove the cache directory itself
    pcall(function() os.remove(CACHE_PATH) end)
    
    return ok and deletedCount > 0
end

----------------------------------------------------------------------
-- METHOD C: Brute force known cache subdirectories
----------------------------------------------------------------------
local function TryBruteForce()
    L("")
    L("=== Method C: Brute force common cache files ===")
    
    -- Common cache subdirectories/files in Android apps
    local knownPaths = {
        "http/",
        "image_cache/",
        "webviewCacheChromi/",
        "webviewCacheChromium/",
        "WebView/",
        "okhttp/",
        "GlideCache/",
        "video_cache/",
        "temp/",
        "tmp/",
        "crash/",
        "log/",
        "logs/",
        "bugly/",
        "tbs_tmp/",
        "tencent/",
        "MMKV/",
        "shader_cache/",
    }
    
    local delCount = 0
    for _, sub in ipairs(knownPaths) do
        local fullPath = CACHE_PATH .. sub
        -- Try UCVFunctionLibrary first
        pcall(function()
            if hasUCVLib then
                UCVFunctionLibrary.DeleteFileOrDirectory(fullPath)
                delCount = delCount + 1
            elseif hasCVLib then
                CVFunctionLibrary.DeleteFileOrDirectory(fullPath)
                delCount = delCount + 1
            end
        end)
        -- Try os.remove
        pcall(function()
            os.remove(fullPath)
        end)
    end
    L("[C] Attempted " .. #knownPaths .. " paths, deleted " .. delCount)
    return delCount > 0
end

----------------------------------------------------------------------
-- METHOD D: Read directory via io.open trick
-- Some systems allow reading directory as file to get entries
----------------------------------------------------------------------
local function TryIOScan()
    L("")
    L("=== Method D: io.open scan ===")
    
    -- Check if cache path is accessible
    local testFile = CACHE_PATH .. ".nomedia"
    local f = io.open(testFile, "r")
    if f then
        f:close()
        L("[D] .nomedia exists, deleting...")
        os.remove(testFile)
    else
        L("[D] .nomedia not found")
    end
    
    -- Try to check cache directory exists by writing a test file
    local testWrite = CACHE_PATH .. "_test_delete_"
    local tf = io.open(testWrite, "w")
    if tf then
        tf:write("test")
        tf:close()
        os.remove(testWrite)
        L("[D] Cache directory is writable!")
    else
        L("[D] Cache directory NOT writable (permission denied or doesn't exist)")
    end
    
    return false
end

----------------------------------------------------------------------
-- RUN
----------------------------------------------------------------------
L("")
L("========================================")
L("  STARTING CACHE DELETION")
L("========================================")

local a = TryUCVLib()
local b = TryLFS()
local c = TryBruteForce()
local d = TryIOScan()

L("")
L("=== RESULTS ===")
L("A (UCVFunctionLib):  " .. tostring(a))
L("B (lfs+os.remove):   " .. tostring(b))
L("C (Brute force):     " .. tostring(c))
L("D (IO scan):         " .. tostring(d))
L("=== DONE ===")
