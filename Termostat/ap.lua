local A = {}
local function url_decode(str)
  if str then
    str = str:gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    str = str:gsub("+", " ")
  end
  return str
end

local function parse_Params(query)
  local params = {}
  for k, v in query:gmatch("([^&=?]+)=([^&]*)") do
    params[k] = url_decode(v)
  end
  return params
end

--Access point
function A.start_ap()
  wifi.setmode(wifi.SOFTAP)
  wifi.ap.config({ssid = "ESP_Setup"})
  print("Started AP mode, IP:", wifi.ap.getip())

  srv = net.createServer(net.TCP)
  srv:listen(80, function(conn)
    conn:on("receive", function(_, request)
      print("HTTP Request:\n", request)

      local _, _, query = request:find("GET /%?(.-) HTTP")
      if query then
        local params = parse_Params(query)
        local ssid = params["ssid"]
        local pwd = params["pwd"]
        local espname = params["name"]

        if ssid and espname then
			print("Saving Wi-Fi settings:")
			print("SSID:", ssid)
			print("PWD :", pwd)
			print("ESP_NAME:", espname)
			
			local cfg = dofile("config.lua")
			cfg.saveConfig(ssid, pwd, espname)
			cfg = nil
			collectgarbage()

          conn:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
          conn:send("<h2>Saved. Rebooting in 5 seconds…</h2>")

          conn:on("sent", function()
            LCD.setCursor(0,0)
            LCD.print("Data saved      ")
            LCD.setCursor(0,1)
            LCD.print("Restart in 5 sec")
            tmr.create():alarm(5000, tmr.ALARM_SINGLE, function() node.restart() end)
          end)
		  return  -- avoid sending form again
        end
      end
      -- No valid query; show config form
      local response = [[
        <html><body>
        <h1>ESP WiFi Setup</h1>
        <form>
          SSID: <input type="text" name="ssid"><br>
          Password: <input type="password" name="pwd"><br>
          ESP Name: <input type="text" name="name"><br>
          <input type="submit" value="Save">
        </form>
        </body></html>
      ]]
      conn:send("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n\r\n")
      conn:send(response)
    end)
  end)
end
return A