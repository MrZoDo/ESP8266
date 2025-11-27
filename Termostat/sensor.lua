local S = {}
--Definesc functia de citire senzor
function S.GetSensorData()
	print( "Citesc valorile de la senzor" )
	--i2c.setup(0, sda, scl, i2c.SLOW) --> i2c.setup() was called in 'init.lua' . We only call this once
	am2320.setup()
	rh, t = am2320.read()
	HUM_Current = rh / 10	-- doua unitai si o zecimala: XX.X
	TMP_Current = t / 10	-- doua unitai si o zecimala: XX.X
	
	--Afisez in consola datele citite
	print(string.format("Humidity: %s%%", HUM_Current))
	print(string.format("Temperature: %s degrees C", TMP_Current))

	--Afisez datele citite pe LCD (Max 16 caractere pe rand)
	LCD.setCursor(0,0)
	LCD.print("T: "..TMP_Current.." C | "..TMP_Set.." C  ")
	LCD.setCursor(0,1)
	LCD.print("H: "..HUM_Current.." %         ")
	
	--Scriu valorile citite in fisier
    file.open("CurrentTemp.txt","w+"); file.write(TMP_Current); file.close()
    file.open("CurrentHumid.txt","w+"); file.write(HUM_Current); file.close()
end	
return S