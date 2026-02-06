local M = {}
function M.startMQTT(clientName,Sensor_ID)
  MQTT_HOST = "192.168.0.110"
  MQTT_PORT = ""		
  mqtt_client = mqtt.Client(clientName, 60, "", "")
  mqtt_client:lwt("/lwt", clientName.." - OFF", 0, 0)
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
      mqtt_client:subscribe("RoomStatus/Cerere", 0)
      mqtt_client:publish("RoomStatus/Raspuns", sjson.encode({ ROOM=RoomName, Status="Online" }), 0, 0)
      print("Subscribed to topics and sent Online status")
    end
  end)

  mqtt_client:on("message", function(_, topic, msg)
    print("MQTT", topic, msg)
    
    if topic == "RoomName/Response" then
      -- Received room name from broker
      print("Received room name response: "..msg)
      local ok, response = pcall(sjson.decode, msg)
      if ok and response.room and response.sensor_name then
        RoomName = response.room
        SensorName = response.sensor_name
        print("Extracted room name: "..RoomName)
        print("Extracted sensor name: "..SensorName)
      else
        print("Error parsing room name response or missing fields")
        return
      end

      -- Save room name and sensor name to config file
      local config = dofile("config.lua")
      config.saveSensorInfo(RoomName, SensorName)
      config = nil
      collectgarbage()
      
      print("Room name and sensor name saved")

      -- Unsubscribe from RoomName/Response
      mqtt_client:unsubscribe("RoomName/Response")
      
      -- Close current connection
      mqtt_client:close()
      
      -- Reconnect with sensor name as client ID
      mqtt_client = mqtt.Client(SensorName, 60, "", "")
      mqtt_client:lwt("/lwt", RoomName.." - OFF", 0, 0)
      mqtt_client:connect(MQTT_HOST, MQTT_PORT, 0, 0)
      mqtt_client:on("connect", function()
        gpio.write(pin_LED_MQTT, gpio.HIGH)
        print("Reconnected to MQTT broker with sensor name: "..SensorName)
        
        -- Subscribe to actual topics
        mqtt_client:subscribe("RoomTemp/Cerere", 0)
        mqtt_client:subscribe("RoomTemp/Setpoint/"..RoomName, 0)
        mqtt_client:subscribe("RoomStatus/Cerere", 0)
        mqtt_client:publish("RoomStatus/Raspuns", sjson.encode({ ROOM=RoomName, Status="Online" }), 0, 0)
        print("Subscribed to topics and sent Online status with room name: "..RoomName)
      end)
      
      -- Re-register message handler for the new client
      mqtt_client:on("message", function(_, topic, msg)
        print("MQTT", topic, msg)
        
        if topic == "RoomTemp/Cerere" then
          mqtt_client:publish("RoomTemp/Raspuns",
            sjson.encode({ ROOM=RoomName, TEMP=TMP_Current, HUM=HUM_Current }), 0, 0)
        elseif topic == "RoomStatus/Cerere" then
          mqtt_client:publish("RoomStatus/Raspuns",
            sjson.encode({ ROOM=RoomName, Status="Online" }), 0, 0)
          print("Sent room status response")
        elseif topic == "RoomTemp/Setpoint/"..RoomName then
          local ok, response = pcall(sjson.decode, msg)
          if ok and response.SETPOINT then
            TMP_Set = tonumber(response.SETPOINT)
            local temp = dofile("temp.lua")
            temp.saveTempSet(TMP_Set)
            temp = nil
            collectgarbage()
            print("MQTT set TMP_Set =", TMP_Set)
            -- Send confirmation message
            mqtt_client:publish("RoomTemp/Setpoint/Confirmation",
              sjson.encode({ ROOM=RoomName, SETPOINT=TMP_Set }), 0, 0)
            print("Sent setpoint confirmation")
          else
            print("Error parsing setpoint JSON or missing SETPOINT field")
          end
        end
      end)
      
    elseif topic == "RoomTemp/Cerere" then
		mqtt_client:publish("RoomTemp/Raspuns",
        sjson.encode({ ROOM=RoomName, TEMP=TMP_Current, HUM=HUM_Current }), 0, 0)
    elseif topic == "RoomStatus/Cerere" then
      mqtt_client:publish("RoomStatus/Raspuns",
        sjson.encode({ ROOM=RoomName, Status="Online" }), 0, 0)
      print("Sent room status response")
    elseif topic == "RoomTemp/Setpoint/"..RoomName then
      local ok, response = pcall(sjson.decode, msg)
      if ok and response.SETPOINT then
        TMP_Set = tonumber(response.SETPOINT)
        local temp = dofile("temp.lua")
        temp.saveTempSet(TMP_Set)
        temp = nil
        collectgarbage()
        print("MQTT set TMP_Set =", TMP_Set)
        -- Send confirmation message
        mqtt_client:publish("RoomTemp/Setpoint/Confirmation",
          sjson.encode({ ROOM=RoomName, SETPOINT=TMP_Set }), 0, 0)
        print("Sent setpoint confirmation")
      else
        print("Error parsing setpoint JSON or missing SETPOINT field")
      end
    end
  end)

end
return M
