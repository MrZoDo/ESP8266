local W = {}
local retryCount = 0
function W.tryConnectWiFi(ssid, pass, ESP_Name)
	print("Try connect to WiFi")
	wifi_timer = tmr.create()
	station_cfg={}
	station_cfg.ssid=ssid
	station_cfg.pwd=pass
	station_cfg.save=false
	wifi.setmode(wifi.STATION)
	wifi.sta.config(station_cfg)
	wifi.sta.autoconnect(1)
	wifi_timer:alarm(3000, tmr.ALARM_AUTO, function()
	  if wifi.sta.getip() then
		wifi_timer:stop()
		ip, nm, gw=wifi.sta.getip()
		print("IP: "..ip.."\nNetmask: "..nm.."\nGateway: "..gw.."\n")
		gpio.write(pin_LED_WIFI, gpio.HIGH)
		--Continue with MQTT connect
		local MQTT = dofile("mqtt.lua")
		MQTT.startMQTT(ESP_Name)
		MQTT = nil
		collectgarbage()
	  elseif retryCount >= 5 then
		wifi_timer:stop()
		print("Connection failed, check WiFi credentials")
		retryCount = 0
		local accessPoint = dofile("ap.lua")  -- starts AP mode and restarts after saving
		accessPoint.start_ap()
		accessPoint = nil
		collectgarbage()
	  else
		retryCount = retryCount + 1
		print("WiFi connection attempt - ", retryCount)
	  end
	end)
end
return W