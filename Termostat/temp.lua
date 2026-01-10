-- temp.lua: 
	-- handle button actions to increase / decrease room temp
	-- save/load room temp to file

local T = {}

--Functie pentru a citi temperatura setata
function T.loadTempSet()
  if file.exists("TempSet.txt") then
	file.open("TempSet.txt", "r")
	local content = file.read(2) --the Set Temp only has two digits
	file.close()
	return content
  end
  return 20
end

--Functie pentru a salva temperatura setata
function T.saveTempSet(t)
  file.open("TempSet.txt","w+")
  file.writeline(t)
  file.close()
  --Afisez datele citite pe LCD (Max 16 caractere pe rand)
  LCD.setCursor(0,0)
  LCD.print("T: "..TMP_Current.." C | "..TMP_Set.." C  ")
  LCD.setCursor(0,1)
  LCD.print("H: "..HUM_Current.." %         ")
end

-- Functie pentru a creste TEMP
function T.Temp_up()
	TMP_Set = TMP_Set + 1
	T.saveTempSet(TMP_Set)
	print("TMP_Set =", TMP_Set)
	-- Publish MQTT message if client is connected
	if mqtt_client ~= nil and RoomName ~= "Undefined" then
		mqtt_client:publish("RoomTemp/ChangeSetpoint", 
			sjson.encode({ ROOM=RoomName, SETPOINT=TMP_Set }), 0, 0)
		print("Published setpoint change to MQTT")
	end
end

-- Functie pentru a scadea TEMP
function T.Temp_down()
	TMP_Set = TMP_Set - 1
	T.saveTempSet(TMP_Set)
	print("TMP_Set =", TMP_Set)
	-- Publish MQTT message if client is connected
	if mqtt_client ~= nil and RoomName ~= "Undefined" then
		mqtt_client:publish("RoomTemp/ChangeSetpoint", 
			sjson.encode({ ROOM=RoomName, SETPOINT=TMP_Set }), 0, 0)
		print("Published setpoint change to MQTT")
	end
end
return T