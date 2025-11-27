--Lista fisierelor ce trebuie sa existe
--MAIN.lua
--config.lua
--i2clcdpcf.lua


--Incarc libraria de LCD 
LCD = require("i2clcdpcf")
--initializez pinii
--SDA--pin = 5 -- GPIO14 / D5
--SCL--pin = 6 -- GPIO12 / D6
sda, scl = 5, 6
LCD.begin(sda, scl)
LCD.setBacklight(1)
i2c.setup(0, sda, scl, i2c.SLOW) -- call i2c.setup() only once
LCD.setCursor(0,0)
LCD.print("Start in 5 sec  ")
	
function startup()
	LCD.setCursor(0,0)
	LCD.print("Executing MAIN  ")
    print('Se executa MAIN.lua')
    dofile('main.lua')
end

tmr.create():alarm(5000, tmr.ALARM_SINGLE,startup)