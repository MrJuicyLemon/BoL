local Version = "1.00"


local CopyRight = "MrJuicyLemon"



function Update()

	local UpdateHost = "raw.githubusercontent.com"
	local ServerPath = "/MrJuicyLemon/BoL/master/"
	local ServerFileName = "UniversalLeveler.lua"
	local ServerVersionFileName = "UniversalLeveler.version"

	DL = Download()
	local ServerVersionDATA = GetWebResult("raw.githubusercontent.com" , ServerPath..ServerVersionFileName)
	if ServerVersionDATA then
		local ServerVersion = tonumber(ServerVersionDATA)
		if ServerVersion then
			if ServerVersion > tonumber(Version) then
				print("Updating, don't press F9")
				DL:newDL(UpdateHost, ServerPath..ServerFileName, ServerFileName, LIB_PATH, function ()
					print("Universal Leveler updated, please reload")
				end)
			end
		else
			print("An error occured, while updating, please reload")
		end
	else
		print("Could not connect to update Server")
	end
end

class "Download"
function Download:__init()
	socket = require("socket")
	self.aktivedownloads = {}
	self.callbacks = {}

	AddTickCallback(function ()
		self:RemoveDone()
	end)

	class("Async")
	function Async:__init(host, filepath, localname, drawoffset, localpath)
		self.progress = 0
		self.host = host
		self.filepath = filepath
		self.localname = localname
		self.offset = drawoffset
		self.localpath = localpath
		self.CRLF = '\r\n'

		self.headsocket = socket.tcp()
		self.headsocket:settimeout(1)
		self.headsocket:connect(self.host, 80)
		self.headsocket:send('HEAD '..self.filepath..' HTTP/1.1'.. self.CRLF ..'Host: '..self.host.. self.CRLF ..'User-Agent: Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'.. self.CRLF .. self.CRLF)

		self.HEADdata = ""
		self.DLdata = ""
		self.StartedDownload = false
		self.canDL = true

		AddTickCallback(function ()
			self:tick()
		end)
		AddDrawCallback(function ()
			self:draw()
		end)
	end

	function Async:tick()
		if self.progress == 100 then return end
		if self.HEADcStatus ~= "timeout" and self.HEADcStatus ~= "closed" then
			self.HEADfString, self.HEADcStatus, self.HEADpString = self.headsocket:receive(16);
			if self.HEADfString then
				self.HEADdata = self.HEADdata..self.HEADfString
			elseif self.HEADpString and #self.HEADpString > 0 then
				self.HEADdata = self.HEADdata..self.HEADpString
			end
		elseif self.HEADcStatus == "timeout" then
			self.headsocket:close()
			--Find Lenght
			local begin = string.find(self.HEADdata, "Length: ")
			if begin then
				self.HEADdata = string.sub(self.HEADdata,begin+8)
				local n = 0
				local _break = false
				for i=1, #self.HEADdata do
					local c = tonumber(string.sub(self.HEADdata,i,i))
					if c and _break == false then
						n = n+1
					else
						_break = true
					end
				end
				self.HEADdata = string.sub(self.HEADdata,1,n)
				self.StartedDownload = true
				self.HEADcStatus = "closed"
			end
		end
		if self.HEADcStatus == "closed" and self.StartedDownload == true and self.canDL == true then --Double Check
			self.canDL = false
			self.DLsocket = socket.tcp()
			self.DLsocket:settimeout(1)
			self.DLsocket:connect(self.host, 80)
			--Start Main Download
			self.DLsocket:send('GET '..self.filepath..' HTTP/1.1'.. self.CRLF ..'Host: '..self.host.. self.CRLF ..'User-Agent: Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'.. self.CRLF .. self.CRLF)
		end
		
		if self.DLsocket and self.DLcStatus ~= "timeout" and self.DLcStatus ~= "closed" then
			self.DLfString, self.DLcStatus, self.DLpString = self.DLsocket:receive(1024);
			
			if ((self.DLfString) or (self.DLpString and #self.DLpString > 0)) then
				self.DLdata = self.DLdata .. (self.DLfString or self.DLpString)
			end

		elseif self.DLcStatus and self.DLcStatus == "timeout" then
			self.DLsocket:close()
			self.DLcStatus = "closed"
			self.DLdata = string.sub(self.DLdata,#self.DLdata-tonumber(self.HEADdata)+1)

			local file = io.open(self.localpath.."\\"..self.localname, "w+b")
			file:write(self.DLdata)
			file:close()
			self.progress = 100
		end

		if self.progress ~= 100 and self.DLdata and #self.DLdata > 0 then
			self.progress = (#self.DLdata/tonumber(self.HEADdata))*100
		end
	end

	function Async:draw()
		if self.progress < 100 then
			DrawTextA("Downloading: "..self.localname,15,50,35+self.offset)
			DrawRectangleOutline(49,50+self.offset,250,20, ARGB(255,255,255,255),1)
			if self.progress ~= 100 then
				DrawLine(50,60+self.offset,50+(2.5*self.progress),60+self.offset,18,ARGB(150,255-self.progress*2.5,self.progress*2.5,255-self.progress*2.5))
				DrawTextA(tostring(math.round(self.progress).." %"), 15,150,52+self.offset)
			end
		end
	end

end

function Download:newDL(host, file, name, path, callback)
	local offset = (#self.aktivedownloads+1)*40
	self.aktivedownloads[#self.aktivedownloads+1] = Async(host, file, name, offset-40, path)
	if not callback then
		callback = (function ()
		end)
	end

	self.callbacks[#self.callbacks+1] = callback

end

function Download:RemoveDone()
	if #self.aktivedownloads == 0 then return end
	local x = {}
	for k, v in pairs(self.aktivedownloads) do
		if math.round(v.progress) < 100 then
			v.offset = k*40-40
			x[#x+1] = v
		else
			self.callbacks[k]()
		end
	end
	self.aktivedownloads = {}
	self.aktivedownloads = x
end

-- i'll add more skill level up combinations
LevelOrder = {
	["Aatrox"] = {
	[1] = {_Q, _W, _E, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Ahri"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _W, _W},
	},
	["Akali"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Alistar"] = {
		[1] = {_Q, _E, _W, _Q, _E, _R, _Q, _E, _Q, _E, _R, _Q, _E, _W, _W, _R, _W, _W},
	},
	["Amumu"] = {
		[1] = {_W, _E, _E, _Q, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Anivia"] = {
		[1] = {_Q, _E, _Q, _E, _E, _R, _E, _W, _E, _W, _R, _Q, _Q, _Q, _W, _R, _W, _W},
	},
	["Annie"] = {
		[1] = {_W, _Q, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Ashe"] = {
		[1] = {_W, _E, _W, _Q, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["AurelionSol"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Azir"] = {
		[1] = {_W, _Q, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Bard"] = {
		[1] = {_W, _Q, _W, _Q, _E, _R, _W, _W, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Blitzcrank"] = {
		[1] = {_Q, _E, _W, _E, _W, _R, _E, _W, _E, _W, _R, _E, _W, _Q, _Q, _R, _Q, _Q},
	},
	["Brand"] = {
		[1] = {_W, _E, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Braum"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Caitlyn"] = {
		[1] = {_W, _Q, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Cassiopeia"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Chogath"] = {
		[1] = {_Q, _E, _W, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Corki"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Darius"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E},
	},
	["Diana"] = {
		[1] = {_W, _Q, _W, _E, _Q, _R, _Q, _Q, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["DrMundo"] = {
		[1] = {_W, _Q, _E, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Draven"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Ekko"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Elise"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Evelynn"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W}
	},
	["Ezreal"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Fiddlesticks"] = {
		[1] = {_E, _W, _W, _Q, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Fiora"] = {
		[1] = {_W, _Q, _E, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Fizz"] = {
		[1] = {_E, _Q, _W, _Q, _W, _R, _Q, _Q, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Galio"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _E, _E, _W, _W, _R, _E, _E},
	},
	["Gangplank"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Garen"] = {
		[1] = {_Q, _W, _E, _E, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Gnar"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Gragas"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E},
	},
	["Graves"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Hecarim"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Heimerdinger"] = {
		[1] = {_Q, _W, _W, _Q, _Q, _R, _E, _W, _W, _W, _R, _Q, _Q, _E, _E, _R, _Q, _Q},
	},
	["Illaoi"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Irelia"] = {
		[1] = {_E, _Q, _W, _W, _W, _R, _W, _E, _W, _E, _R, _Q, _Q, _E, _Q, _R, _E, _Q},
	},
	["Janna"] = {
		[1] = {_E, _Q, _E, _W, _E, _R, _E, _W, _E, _W, _Q, _W, _W, _Q, _Q, _Q, _R, _R},
	},
	["JarvanIV"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _W, _Q, _R, _E, _E, _E, _W, _R, _W, _W},
	},
	["Jax"] = {
		[1] = {_E, _W, _Q, _W, _W, _R, _W, _E, _W, _E, _R, _Q, _E, _Q, _Q, _R, _E, _Q},
	},
	["Jayce"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Jhin"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Jinx"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Kalista"] = {
		[1] = {_E, _W, _Q, _E, _E, _R, _E, _E, _W, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["Karma"] = {
		[1] = {_Q, _E, _Q, _W, _E, _Q, _E, _Q, _E, _Q, _E, _Q, _E, _W, _W, _W, _W, _W},
	},
	["Karthus"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Kassadin"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Katarina"] = {
		[1] = {_Q, _E, _W, _W, _W, _R, _W, _E, _W, _Q, _R, _Q, _Q, _Q, _E, _R, _E, _E},
	},
	["Kayle"] = {
		[1] = {_E, _W, _E, _Q, _E, _R, _E, _W, _E, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["Kennen"] = {
		[1] = {_Q, _E, _W, _W, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Khazix"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Kindred"] = {
		[1] = {_W, _Q, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["KogMaw"] = {
		[1] = {_W, _E, _W, _Q, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Leblanc"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E},
	},
	["LeeSin"] = {
		[1] = {_E, _Q, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Leona"] = {
		[1] = {_Q, _E, _W, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Lissandra"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Lucian"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Lulu"] = {
		[1] = {_E, _W, _Q, _E, _E, _R, _E, _W, _E, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["Lux"] = {
		[1] = {_E, _Q, _E, _W, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Malphite"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _W, _E, _W, _R, _W, _W},
	},
	["Malzahar"] = {
		[1] = {_Q, _E, _E, _W, _E, _R, _Q, _E, _Q, _E, _R, _W, _Q, _W, _Q, _R, _W, _W},
	},
	["Maokai"] = {
		[1] = {_E, _Q, _W, _E, _E, _R, _E, _W, _E, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["MasterYi"] = {
		[1] = {_E, _Q, _E, _Q, _E, _R, _E, _Q, _E, _Q, _R, _Q, _W, _W, _W, _R, _W, _W},
	},
	["MissFortune"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["MonkeyKing"] = {
		[1] = {_E, _Q, _W, _Q, _Q, _R, _E, _Q, _E, _Q, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Mordekaiser"] = {
		[1] = {_E, _Q, _E, _W, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Morgana"] = {
		[1] = {_Q, _W, _W, _E, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Nami"] = {
		[1] = {_Q, _W, _E, _W, _W, _R, _W, _W, _E, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Nasus"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E},
	},
	["Nautilus"] = {
		[1] = {_W, _E, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Nidalee"] = {
		[1] = {_W, _E, _Q, _E, _Q, _R, _E, _W, _E, _Q, _R, _E, _Q, _Q, _W, _R, _W, _W},
	},
	["Nocturne"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Nunu"] = {
		[1] = {_E, _Q, _E, _W, _Q, _R, _E, _Q, _E, _Q, _R, _Q, _E, _W, _W, _R, _W, _W},
	},
	["Olaf"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Orianna"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Pantheon"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _W, _E, _W, _R, _W, _W},
	},
	["Poppy"] = {
		[1] = {_E, _W, _Q, _Q, _Q, _R, _Q, _W, _Q, _W, _W, _W, _E, _E, _E, _E, _R, _R},
	},
	["Quinn"] = {
		[1] = {_E, _Q, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Rammus"] = {
		[1] = {_Q, _W, _E, _E, _E, _R, _E, _W, _E, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["RekSai"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Renekton"] = {
		[1] = {_W, _Q, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Rengar"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _W, _Q, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Riven"] = {
		[1] = {_Q, _E, _W, _Q, _E, _R, _Q, _Q, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Rumble"] = {
		[1] = {_E, _Q, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Ryze"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Sejuani"] = {
		[1] = {_W, _Q, _E, _E, _W, _R, _E, _W, _E, _E, _R, _W, _Q, _W, _Q, _R, _Q, _Q},
	},
	["Shaco"] = {
		[1] = {_W, _E, _Q, _E, _E, _R, _E, _W, _E, _W, _R, _W, _W, _Q, _Q, _R, _Q, _Q},
	},
	["Shen"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Shyvana"] = {
		[1] = {_W, _Q, _W, _E, _W, _R, _W, _E, _W, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q},
	},
	["Singed"] = {
		[1] = {_Q, _E, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _E, _W, _E, _W, _R, _W, _E},
	},
	["Sion"] = {
		[1] = {_Q, _E, _E, _W, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Sivir"] = {
		[1] = {_W, _Q, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Skarner"] = {
		[1] = {_Q, _W, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _E, _E, _R, _E, _E},
	},
	["Sona"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Soraka"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _E, _R, _W, _E, _W, _E, _R, _W, _E},
	},
	["Swain"] = {
		[1] = {_W, _E, _E, _Q, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Syndra"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["TahmKench"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _E, _W, _E, _R, _E, _E},
	},
	["Talon"] = {
		[1] = {_W, _E, _Q, _W, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Taric"] = {
		[1] = {_E, _W, _Q, _W, _W, _R, _Q, _W, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Teemo"] = {
		[1] = {_Q, _E, _W, _E, _Q, _R, _E, _E, _E, _Q, _R, _W, _W, _Q, _W, _R, _W, _Q},
	},
	["Thresh"] = {
		[1] = {_Q, _E, _W, _W, _W, _R, _W, _E, _W, _E, _R, _E, _E, _Q, _Q, _R, _Q, _Q},
	},
	["Tristana"] = {
		[1] = {_E, _W, _W, _E, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _Q, _E, _R, _E, _E},
	},
	["Trundle"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _E, _R, _W, _E, _W, _E, _R, _W, _E},
	},
	["Tryndamere"] = {
		[1] = {_E, _Q, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["TwistedFate"] = {
		[1] = {_W, _Q, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Twitch"] = {
		[1] = {_E, _W, _Q, _E, _E, _R, _E, _Q, _E, _Q, _R, _Q, _Q, _W, _W, _R, _W, _W},
	},
	["Udyr"] = {
		[1] = {_R, _W, _E, _R, _R, _W, _R, _W, _R, _W, _W, _Q, _E, _E, _E, _E, _Q, _Q},
	},
	["Urgot"] = {
		[1] = {_E, _Q, _Q, _W, _Q, _R, _Q, _W, _Q, _E, _R, _W, _E, _W, _E, _R, _W, _E},
	},
	["Varus"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Vayne"] = {
		[1] = {_Q, _E, _W, _Q, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Veigar"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _W, _W, _W, _W, _R, _E, _Q, _Q, _E, _R, _E, _E},
	},
	["VelKoz"] = {
		[1] = {_Q, _W, _E, _W, _W, _R, _W, _Q, _W, _Q, _R, _Q, _Q, _E, _E, _R, _E, _E},
	},
	["Vi"] = {
		[1] = {_W, _E, _Q, _Q, _Q, _R, _Q, _W, _Q, _Q, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Viktor"] = {
		[1] = {_E, _W, _E, _Q, _E, _R, _E, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W},
	},
	["Vladimir"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Volibear"] = {
		[1] = {_W, _E, _W, _Q, _W, _R, _E, _W, _Q, _W, _R, _E, _Q, _E, _Q, _R, _E, _Q},
	},
	["Warwick"] = {
		[1] = {_W, _Q, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _E, _W, _R, _W, _W},
	},
	["Xerath"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["XinZhao"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Yasuo"] = {
		[1] = {_Q, _E, _Q, _W, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Yorick"] = {
		[1] = {_W, _E, _Q, _E, _E, _R, _E, _W, _E, _Q, _R, _W, _Q, _W, _Q, _R, _W, _Q},
	},
	["Zac"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Zed"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Ziggs"] = {
		[1] = {_Q, _W, _E, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	},
	["Zilean"] = {
		[1] = {_Q, _W, _Q, _E, _Q, _R, _Q, _W, _Q, _W, _R, _W, _W, _E, _E, _R, _E, _E},
	},
	["Zyra"] = {
		[1] = {_E, _W, _Q, _Q, _Q, _R, _Q, _E, _Q, _E, _R, _E, _E, _W, _W, _R, _W, _W},
	}
}


Universal = scriptConfig("UniversalLeveler", "Universal Leveler")
Universal:addSubMenu("Settings", "Settings")
Universal.Settings:addParam("LevelUp", "Level Up Skills", SCRIPT_PARAM_ONOFF, true)
Universal.Settings:addParam("StartLevel", "Level to enable lvlUP", SCRIPT_PARAM_SLICE, 1, 1, 17)
Universal.Settings:addParam("autoLvl", "Skill order", SCRIPT_PARAM_LIST, 1, {"Soon"})
Universal.Settings:addParam("Humanizer", "Enable Level Up Humanizer", SCRIPT_PARAM_ONOFF, true)
Universal.Settings:addParam("Info", "Author: "..CopyRight, SCRIPT_PARAM_INFO, "")
Universal.Settings:addSubMenu("Delay", "Delay")
Universal.Settings.Delay:addParam("Min", "Min level up delay (ms)", SCRIPT_PARAM_SLICE, 255, 100, 399)
Universal.Settings.Delay:addParam("Max", "Max level up delay (ms)", SCRIPT_PARAM_SLICE, 665, 400, 2000)

function message(i)
  do
    print(string.format("<font color=\"#FC5743\"><b>UniversalLeveler Message: </b></font><font color=\"#E53CD4\">"..i.."</font>"))
  end
end

function Autolvl()
	do
		SkillOrder = LevelOrder[myHero.charName][Universal.Settings.autoLvl][myHero.level]
		if Universal.Settings.LevelUp and myHero.level >= Universal.Settings.StartLevel then
		    if Universal.Settings.Humanizer then
		      DelayAction(function()LevelSpell(SkillOrder) end, math.random(Universal.Settings.Delay.Min, Universal.Settings.Delay.Max))
		    else
		      LevelSpell(SkillOrder)
		    end
		end
	end
end

function OnTick()
local LastLevel = 0
	if myHero.level ~= LastLevel then
		Autolvl()
		DelayAction(function()
			LastLevel = myHero.level
			end, 1)
	end
end

message("Script loaded succesfully, Good Luck " ..GetUser())
