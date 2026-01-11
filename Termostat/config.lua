-- config.lua: load/save WiFi credentials + Sensor_ID

local M = {}
function M.loadConfig()
  if file.exists("ESP_Config.txt") then
    local s = file.open("ESP_Config.txt")
    local ssid = s:readline():gsub("%s+$","")
    local pwd = s:readline():gsub("%s+$","")
    local sensor_id = s:readline():gsub("%s+$","")
    local roomname = s:readline()
    if roomname then
      roomname = roomname:gsub("%s+$","")
    end
    local sensorname = s:readline()
    if sensorname then
      sensorname = sensorname:gsub("%s+$","")
    end
    s:close()
    return ssid, pwd, sensor_id, roomname, sensorname
  end
  return nil, nil, nil, nil, nil
end
function M.saveConfig(ssid, pwd, sensor_id)
  file.open("ESP_Config.txt","w+")
  file.writeline(ssid)
  file.writeline(pwd)
  file.writeline(sensor_id)
  file.close()
end
function M.saveSensorInfo(roomname, sensorname)
  -- Read existing config
  local ssid, pwd, sensor_id = M.loadConfig()
  if ssid ~= nil then
    -- Write back with room and sensor name
    file.open("ESP_Config.txt","w+")
    file.writeline(ssid)
    file.writeline(pwd)
    file.writeline(sensor_id)
    file.writeline(roomname or "Undefined")
    file.writeline(sensorname or "Undefined")
    file.close()
  end
end
return M
