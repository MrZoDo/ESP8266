-- Main application

--Definesc pinii
local pin_BTN_DN = 1 	-- GPIO5  / D1	--Buton scadere temperatura setata
local pin_BTN_UP = 2 	-- GPIO4  / D2	--Buton crestere temperatura setata
local pin_BTN_LCD = 3 	-- GPIO0 -- D3 	--Pin comanda backlight LCD
pin_BTN_RST = 4			-- GPIO2 -- D4	--Pin reset WiFi credentials
--pin_SDA = 5 			-- GPIO14 / D5 
--pin_SCL = 6 			-- GPIO12 / D6
pin_LED_WIFI = 7		-- GPIO13 / D7 	--LED conexiune WiFi
pin_LED_MQTT = 8		-- GPIO15 / D8	--LED conexiune MQTT

--Setez tipul de pini
gpio.mode(pin_BTN_UP, gpio.INT, gpio.PULLUP)
gpio.mode(pin_BTN_DN, gpio.INT, gpio.PULLUP)
gpio.mode(pin_BTN_LCD, gpio.INT, gpio.PULLUP)
gpio.mode(pin_BTN_RST, gpio.INT, gpio.PULLUP)
gpio.mode(pin_LED_WIFI, gpio.OUTPUT)
gpio.mode(pin_LED_MQTT, gpio.OUTPUT)

--Setez valorile implicite
Sensor_ID = "Undefined"
RoomName = "Undefined"
TMP_Current, HUM_Current = 0, 0

--Citesc temperatura setata
local temp = dofile("temp.lua")
TMP_Set = temp.loadTempSet()
temp = nil
collectgarbage()


local function Change_Temp_up()
	local temp = dofile("temp.lua")
	temp.Temp_up()
	temp = nil
	collectgarbage()
end

local function Change_Temp_down()
	local temp = dofile("temp.lua")
	temp.Temp_down()
	temp = nil
	collectgarbage()
end

local function Lcd_Backlight()
	local backlight = dofile("lcd.lua")
	backlight.LCD_on()
	backlight = nil
	collectgarbage()
end

function Reset_WiFi_Credentials()
	local reset = dofile("reset.lua")
	reset.resetCredentials()
	reset = nil
	collectgarbage()
end

-- Create debounce timer
local debounceTimer = tmr.create()

-- Register interrupt callbacks
gpio.trig(pin_BTN_UP, "down", function()
    debounceTimer:stop()
    debounceTimer:alarm(200, tmr.ALARM_SINGLE, function()
        -- Re-check pin state after debounce period
        if gpio.read(pin_BTN_UP) == 0 then
            Change_Temp_up()
        end
    end)
end)

gpio.trig(pin_BTN_DN, "down", function()
    debounceTimer:stop()
    debounceTimer:alarm(200, tmr.ALARM_SINGLE, function()
        -- Re-check pin state after debounce period
        if gpio.read(pin_BTN_DN) == 0 then
            Change_Temp_down()
        end
    end)
end)

gpio.trig(pin_BTN_LCD, "down",  function()   
    debounceTimer:stop()
    debounceTimer:alarm(200, tmr.ALARM_SINGLE, function()
        -- Re-check pin state after debounce period
        if gpio.read(pin_BTN_LCD) == 0 then
            Lcd_Backlight()
        end
    end)
end)
	
gpio.trig(pin_BTN_RST, "down", Reset_WiFi_Credentials)

--Citesc senzorul o data la 10 secunde
SensorTimer = tmr.create()
SensorTimer:register(10000, tmr.ALARM_AUTO,	function() 
	local sensor = dofile("sensor.lua")
	sensor.GetSensorData()
	sensor = nil
	collectgarbage()
end)
SensorTimer:start()

--Connect to WiFi
local config = dofile("config.lua")
local ssid, pass, Sensor_ID, loadedRoomName = config.loadConfig()
if loadedRoomName ~= nil then
	RoomName = loadedRoomName
end
config = nil
collectgarbage()
if ssid ~= nil then
	print("ssid = "..ssid.."\npassword = "..pass.."\nSensor_ID = "..Sensor_ID.."\nRoomName = "..RoomName.."\n")
end


if ssid == nil then
  local accessPoint = dofile("ap.lua")  -- starts AP mode and restarts after saving
  accessPoint.start_ap()
  accessPoint = nil
  collectgarbage()
else
  local wifiConn = dofile("wifi.lua")
  wifiConn.tryConnectWiFi(ssid, pass, Sensor_ID)
  wifiConn = nil
  collectgarbage()
end

-- Watch for Wi-Fi drop
tmr.create():alarm(60000, tmr.ALARM_SINGLE,function() --starts after one minute and runs every 10 seconds
	tmr.create():alarm(10000, tmr.ALARM_AUTO, function()
	  if wifi.sta.getip() == nil and wifi.getmode() == wifi.STATION then
		gpio.write(pin_LED_WIFI, gpio.LOW)
		print("WiFi lost, retrying to connect...")
		local wifiConn = dofile("wifi.lua")
		wifiConn.tryConnectWiFi(ssid, pass, Sensor_ID)
		wifiConn = nil
		collectgarbage()
	  end
	end)
end)

-- Start it up
print("Startup… TMP_Set =", TMP_Set)
print("Free heap:", node.heap())



