-- config.lua: load/save WiFi credentials + ESP_Name

local M = {}
function M.loadConfig()
  if file.exists("ESP_Config.txt") then
    local s = file.open("ESP_Config.txt")
    local ssid = s:readline():gsub("%s+$","")
    local pwd = s:readline():gsub("%s+$","")
    local espname = s:readline():gsub("%s+$","")
    s:close()
    return ssid, pwd, espname
  end
  return nil, nil, nil
end
function M.saveConfig(ssid, pwd, espname)
  file.open("ESP_Config.txt","w+")
  file.writeline(ssid)
  file.writeline(pwd)
  file.writeline(espname)
  file.close()
end
return M
