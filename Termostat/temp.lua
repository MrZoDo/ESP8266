-- temp.lua: 
	-- handle button actions to increase / decrease room temp
	-- save/load room temp to file

local T = {}

-- Debounce delay in ms
local DEBOUNCE_DELAY = 200
local last_up_press = 0
local last_down_press = 0

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
    local now = tmr.now() / 1000
    if now - last_up_press > DEBOUNCE_DELAY then
        TMP_Set = TMP_Set + 1
        T.saveTempSet(TMP_Set)
		print("TMP_Set =", TMP_Set)
        last_up_press = now
    end
end

-- Functie pentru a scadea TEMP
function T.Temp_down()
    local now = tmr.now() / 1000
    if now - last_down_press > DEBOUNCE_DELAY then
        TMP_Set = TMP_Set - 1
        T.saveTempSet(TMP_Set)
		print("TMP_Set =", TMP_Set)
        last_down_press = now
    end
end
return T