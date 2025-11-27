local M = {}
function M.startMQTT(ESP_Name)
  MQTT_HOST = "192.168.0.110"
  MQTT_PORT = ""		
  mqtt_client = mqtt.Client(ESP_Name, 60, "", "")
  mqtt_client:lwt("/lwt", "Living - OFF", 0, 0)
  mqtt_client:connect(MQTT_HOST, MQTT_PORT, 0, 0)
  mqtt_client:on("connect", function()
    gpio.write(LED_MQTT, gpio.HIGH)
    print("Connected to MQTT broker")
    mqtt_client:subscribe("RoomTemp/Cerere", 0)
    mqtt_client:subscribe("RoomTemp/Set", 0)
	print("Subscribed to topics")
  end)

  mqtt_client:on("message", function(_, topic, msg)
    print("MQTT", topic, msg)
    if topic == "RoomTemp/Cerere" then
		mqtt_client:publish("RoomTemp/Raspuns",
        sjson.encode({ ESP=ESP_Name, TEMP=TMP_Current, HUM=HUM_Current }), 0, 0)
	elseif topic == "RoomTemp/Set" then
		TMP_Set = tonumber(msg)
		local temp = dofile("temp.lua")
		temp.saveTempSet(TMP_Set)
		temp = nil
		collectgarbage()
		print("MQTT set TMP_Set =", TMP_Set)
    end
  end)

end
return M
