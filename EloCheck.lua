local socket = require("socket")
local data2e, data2a

local function MakeRequest(url)
    local tcp = socket.tcp()
	tcp:settimeout(5)
	tcp:connect(GetGameRegion()..".op.gg", "80")
	
	tcp:send("GET /summoner/userName=" .. url .. " HTTP/1.0\r\nHost: "..GetGameRegion()..".op.gg\r\n\r\n")
    local retval = tcp:receive("*a")
	
	repeat until retval ~= nil --??
	tcp:close()
    if retval ~= nil then
		return retval
	else 
		return "error"
	end
end

print("Requesting data...")
--if (not data or data == "error" or not data:find("description")) then print("Error requesting data") return end
for i = 1,6 do
	if GetEnemyHeroes()[i] ~= nil then
		datae = MakeRequest(GetEnemyHeroes()[i].name)
		data2e = datae:find("description")
		datae = datae:sub(data2e+22, data2e+80)
		infoE = {}
		datae:gsub('(.-)/', function(a)
			table.insert(infoE, a)
		end)
	end
	if GetAllyHeroes()[i] ~= nil then
		dataa = MakeRequest(GetAllyHeroes()[i].name)
		data2a = dataa:find("description")
		dataa = dataa:sub(data2a+22, data2a+80)
		infoA = {}
		dataa:gsub('(.-)/', function(b)
			table.insert(infoA, b)
		end)
	end


	-----------------

	data = MakeRequest(myHero.name)

	data2 = data:find("description")
	data = data:sub(data2+22, data2+80)

	info = {}
	data:gsub('(.-)/', function(x)
		table.insert(info, x)
	end)

	----------------------------------
end


function OnLoad()
	do
		if (FileExist(LIB_PATH.."MenuConfig.lua")) then
	    require 'MenuConfig'
	  else
	    message("Downloading MenuConfig, please don't reload script!")
	    DownloadFile("https://raw.githubusercontent.com/linkpad/BoL/master/Common/MenuConfig.lua?rand="..math.random(1, 10000), LIB_PATH.."MenuConfig.lua", function()
	      message("Finsihed downloading MenuConfig, please reload script!")
	  	end)
	  end
		Elo = MenuConfig("Elo Check", "Elo Check")
				Elo:Section("Elo Check", ARGB(255, 114, 223, 230))
				Elo:Menu("me", "My Hero")
				Elo.me:Info("My Division: "..info[2], "Info")
				Elo.me:Info("Win/loss & Win%: "..info[3], "Info")
				Elo:Menu("ally", "Allies", "gamepad")
				Elo:Menu("enemy", "Enemies", "leaf")
				for i = 1,6 do
					if GetEnemyHeroes()[i] ~= nil then
						Elo.enemy:Info(GetEnemyHeroes()[i].charName.." 's Division: "..infoE[2], "Info")
						Elo.enemy:Info(GetEnemyHeroes()[i].charName.." 's Win/loss & Win%: "..infoE[3], "Info")
					end
					if GetAllyHeroes()[i] ~= nil then
						Elo.ally:Info(GetAllyHeroes()[i].charName.." 's Division: "..infoA[2], "Info")
						Elo.ally:Info(GetAllyHeroes()[i].charName.." 's Win/loss & Win%: "..infoA[3], "Info")
					end
				end
	end
end
