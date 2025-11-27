local R = {}
local PRESS_DURATION = 10  -- seconds
local CHECK_INTERVAL = 100  -- ms
local checkTimer = tmr.create()
local pressTime = 0

local function stopMonitoring()
    checkTimer:stop()
    gpio.trig(pin_BTN_RST, "down", Reset_WiFi_Credentials)  -- re-enable interrupt
    pressTime = 0
end

function R.resetCredentials()
    gpio.trig(pin_BTN_RST)  -- disable further interrupts during monitoring
	print("Reset button pressed")
    checkTimer:alarm(CHECK_INTERVAL, tmr.ALARM_AUTO, function()
        if gpio.read(pin_BTN_RST) == 0 then
            pressTime = pressTime + (CHECK_INTERVAL / 1000)
            if pressTime >= PRESS_DURATION then
                print("Button held for 10 seconds. Clearing ESP_Config.txt...")
                file.remove("ESP_Config.txt")
                --file.open("ESP_Config.txt", "w+")
                --file.close()
                stopMonitoring()
            end
        else
            print("Button released before 10 seconds.")
            stopMonitoring()
        end
    end)
end
return R

