local M = {}
function M.startMQTT(Sensor_ID)
  MQTT_HOST = "192.168.0.110"
  MQTT_PORT = ""		
  mqtt_client = mqtt.Client(Sensor_ID, 60, "", "")
  mqtt_client:lwt("/lwt", "Living - OFF", 0, 0)
  mqtt_client:connect(MQTT_HOST, MQTT_PORT, 0, 0)
  mqtt_client:on("connect", function()
    gpio.write(pin_LED_MQTT, gpio.HIGH)
    print("Connected to MQTT broker")
    
    -- Check if room name is undefined
    if RoomName == "Undefined" then
      print("Room name is undefined, requesting from broker...")
      mqtt_client:subscribe("RoomName/Response", 0)
      mqtt_client:publish("RoomName/Get", sjson.encode({ Sensor_ID=Sensor_ID }), 0, 0)
    else
      -- Room name is set, subscribe to topics
      print("Room name is set: "..RoomName)
      mqtt_client:subscribe("RoomTemp/Cerere", 0)
      mqtt_client:subscribe("RoomTemp/Setpoint/"..RoomName, 0)
      print("Subscribed to topics")
    end
  end)

  mqtt_client:on("message", function(_, topic, msg)
    print("MQTT", topic, msg)
    
    if topic == "RoomName/Response" then
      -- Received room name from broker
      print("Received room name response: "..msg)
      local ok, response = pcall(sjson.decode, msg)
      if ok and response.room then
        RoomName = response.room
        print("Extracted room name: "..RoomName)
      else
        print("Error parsing room name response")
        return
      end

      
      -- Save room name to config file
      local config = dofile("config.lua")
      config.saveRoomName(RoomName)
      config = nil
      collectgarbage()
      
      print("Room name saved, reconnecting to MQTT...")
      -- Unsubscribe from RoomName/Response
      mqtt_client:unsubscribe("RoomName/Response")
      
      -- Subscribe to actual topics
      mqtt_client:subscribe("RoomTemp/Cerere", 0)
      mqtt_client:subscribe("RoomTemp/Setpoint/"..RoomName, 0)
      print("Subscribed to topics with room name: "..RoomName)
      
    elseif topic == "RoomTemp/Cerere" then
		mqtt_client:publish("RoomTemp/Raspuns",
        sjson.encode({ ROOM=RoomName, TEMP=TMP_Current, HUM=HUM_Current }), 0, 0)
	elseif topic == "RoomTemp/Setpoint/"..RoomName then
		TMP_Set = tonumber(msg)
		local temp = dofile("temp.lua")
		temp.saveTempSet(TMP_Set)
		temp = nil
		collectgarbage()
		print("MQTT set TMP_Set =", TMP_Set)
		-- Send confirmation message
		mqtt_client:publish("RoomTemp/Setpoint/Confirmation",
			sjson.encode({ ROOM=RoomName, SETPOINT=TMP_Set }), 0, 0)
		print("Sent setpoint confirmation")
    end
  end)

end
return M
