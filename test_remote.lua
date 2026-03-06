-- Test Remote Script v1
-- If this text appears in the log, remote loading works!
local LOG="/storage/emulated/0/Android/data/com.tencent.tmgp.codev/files/UE4Game/CodeV/CodeV/Saved/Paks/puffer_temp/loader_log.txt"
local function L(m) pcall(function() local f=io.open(LOG,"a") if f then f:write("["..os.date("%H:%M:%S").."] "..tostring(m).."\n") f:close() end end) end
L("========================================")
L("REMOTE SCRIPT LOADED SUCCESSFULLY!")
L("========================================")
L("Time: "..os.date("%Y-%m-%d %H:%M:%S"))
L("GameAPI: "..tostring(GameAPI~=nil))
L("load(): WORKS!")
L("========================================")
