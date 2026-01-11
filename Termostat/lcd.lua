-- lcd.lua: 
	-- handle button actions to turn on LCD backlight for 5 seconds

local L = {}
--Function to turn on LCD screen for 5 sec
function L.LCD_on()
	  print("LCD backlight on for 5 sec")
	  LCD.setBacklight(1)
	  tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() LCD.setBacklight(0) end)
end
return L