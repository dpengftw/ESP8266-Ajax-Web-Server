t = require("ds18b20")

wifi.setmode(wifi.STATION)
wifi.sta.config("network","password")
tmr.alarm(1, 1000, 1, function()
  if wifi.sta.getip() == nil then
  print("IP unavailable, waiting...")
 else
  tmr.stop(1)
 print("ESP8266 mode is: " .. wifi.getmode())
 print("The module MAC address is: " .. wifi.ap.getmac())
 print("Config done, IP is ".. wifi.sta.getip())
 end
 end)

-- ESP-01 GPIO Mapping
gpio0 = 3
gpio2 = 4
t.setup(gpio0)
gpio.mode(gpio2, gpio.OUTPUT)
gpio.write(gpio2, gpio.LOW)


sendFileContents = function(conn, filename)
    if file.open(filename, "r") then
        --conn:send(responseHeader("200 OK","text/html"));
        repeat
        local line = file.readline()
        if line then
            conn:send(line);
        end 
        until not line
        file.close();
    else
        conn:send(responseHeader("404 Not Found","text/html"));
        conn:send("Page not found");
    end
end

responseHeader = function(code, type)   
    return "HTTP/1.1 " .. code .. "\r\nConnection: close\r\nServer: nunu-Luaweb\r\nContent-Type: " .. type .. "\r\n\r\n";   
end 
    
-- Set DDNS
tmr.alarm(2,10000, 0, function()
print("Setting DDNS to ".. wifi.sta.getip())
conn=net.createConnection(net.TCP, false) 
conn:on("receive", function(conn, payload) print(payload) end )
conn:connect(80,"104.219.249.25") 
conn:send("GET /update?host=esptemp&domain=peng168.com&password=1640cafe78284552ba4189f75449112e&ip=" .. wifi.sta.getip() .. "\r\n")
conn:on("sent",function(conn)
                      print("Closing namecheap connection")
                      conn:close()
                  end)
conn:on("disconnection", function(conn)
          print("Connection for namecheap DDNS closed")
          end)


-- Setup web server
print("Starting up web server")

srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
    conn:on("receive", function(client,request)
        local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
        if(method == nil)then
            _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
        end
        local _GET = {}
        if (vars ~= nil)then
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
                _GET[k] = v
            end
        end


        if ( path == "/gpio2on" ) then
            gpio.write(gpio2, gpio.HIGH);
        elseif ( path == "/gpio2off" ) then
            gpio.write(gpio2, gpio.LOW);
        elseif ( path == "/gpio2toggle" ) then
            gpio.write(gpio2, gpio.HIGH);
            tmr.alarm(3,250, 0, function()
            gpio.write(gpio2, gpio.LOW)
            end)
        elseif ( path == "/tempc" ) then
            client:send(t.read());
        elseif ( path == "/tempf" ) then
            client:send(t.read(nil, t.F));
        elseif ( path == "/" ) then        
            sendFileContents(conn, "index.html");
        end
        
        client:close();
        collectgarbage();
    end)
end)

end)
