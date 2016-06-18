local Version = "1.01"
function Update()
	local UpdateHost = "raw.githubusercontent.com"
	local ServerPath = "/MrJuicyLemon/BoL/master/"
	local ServerFileName = "GlobalSkinChanger.lua"
	local ServerVersionFileName = "GlobalSkinChanger.version"

	DL = Download()
	local ServerVersionDATA = GetWebResult("raw.githubusercontent.com" , ServerPath..ServerVersionFileName)
	if ServerVersionDATA then
		local ServerVersion = tonumber(ServerVersionDATA)
		if ServerVersion then
			if ServerVersion > tonumber(Version) then
				print("Updating, don't press F9")
				DL:newDL(UpdateHost, ServerPath..ServerFileName, ServerFileName, LIB_PATH, function ()
					print("Skin Changer updated, please reload")
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

SkinNames = {
	["Aatrox"] = {"Classic", "Justicar", "Mecha", "Sea Hunter"},
	["Ahri"] = {"Classic", "Dynasty", "Midnight", "Foxfire", "Popstar", "Challenger", "Academy"},
	["Akali"] = {"Classic", "Stinger", "Crimson", "All-star", "Nurse", "Blood Moon", "Silverfang", "Headhunter"},
	["Alistar"] = {"Classic", "Black", "Golden", "Matador", "Longhorn", "Unchained", "Infernal", "Sweeper", "Marauder"},
	["Amumu"] = {"Classic", "Pharaoh", "Vancouver", "Emumu", "Re-Gifted", "Almost-Prom King", "Little Knight", "Sad Robot", "Surprise Party"},
	["Anivia"] = {"Classic", "Team Spirit", "Bird of Prey", "Noxus Hunter", "Hextech", "Blackfrost", "Prehistoric"},
	["Annie"] = {"Classic", "Goth", "Red Riding", "Annie in Wonderland", "Prom Queen", "Frostfire", "Reverse", "FrankenTibbers", "Panda", "Sweetheart"},
	["Ashe"] = {"Classic", "Freljord", "Sherwood Forest", "Woad", "Queen", "Amethyst", "Heartseeker", "Marauder"},
	["Azir"] = {"Classic", "Galactic", "Gravelord"},
	-- B
	["Bard"] = {"Classic", "Elderwood", "Chroma Pack: Marigold", "Chroma Pack: Ivy", "Chroma Pack: Sage"},
	["Blitzcrank"] = {"Classic", "Rusty", "Goalkeeper", "Boom Boom", "Piltover Customs", "Definitely Not", "iBlitzcrank", "Riot", "Chroma Pack: Molten", "Chroma Pack: Cobalt", "Chroma Pack: Gunmetal", "Battle Boss"},
	["Brand"] = {"Classic", "Apocalyptic", "Vandal", "Cryocore", "Zombie", "Spirit Fire"},
	["Braum"] = {"Classic", "Dragonslayer", "El Tigre", "Lionheart"},
	-- C
	["Caitlyn"] = {"Classic", "Resistance", "Sheriff", "Safari", "Arctic Warfare", "Officer", "Headhunter", "Chroma Pack: Pink", "Chroma Pack: Green", "Chroma Pack: Blue","Lunar"},
	["Cassiopeia"] = {"Classic", "Desperada", "Siren", "Mythic", "Jade Fang", "Chroma Pack: Day", "Chroma Pack: Dusk", "Chroma Pack: Night"},
	["Chogath"] = {"Classic", "Nightmare", "Gentleman", "Loch Ness", "Jurassic", "Battlecast Prime", "Prehistoric"},
	["Corki"] = {"Classic", "UFO", "Ice Toboggan", "Red Baron", "Hot Rod", "Urfrider", "Dragonwing", "Fnatic"},
	-- D
	["Darius"] = {"Classic", "Lord", "Bioforge", "Woad King", "Dunkmaster", "Chroma Pack: Black Iron", "Chroma Pack: Bronze", "Chroma Pack: Copper", "Academy"},
	["Diana"] = {"Classic", "Dark Valkyrie", "Lunar Goddess"},
	["DrMundo"] = {"Classic", "Toxic", "Mr. Mundoverse", "Corporate Mundo", "Mundo Mundo", "Executioner Mundo", "Rageborn Mundo", "TPA Mundo", "Pool Party"},
	["Draven"] = {"Classic", "Soul Reaver", "Gladiator", "Primetime", "Pool Party"},
	-- E
	["Ekko"] = {"Classic", "Sandstorm", "Academy"},
	["Elise"] = {"Classic", "Death Blossom", "Victorious", "Blood Moon"},
	["Evelynn"] = {"Classic", "Shadow", "Masquerade", "Tango", "Safecracker"},
	["Ezreal"] = {"Classic", "Nottingham", "Striker", "Frosted", "Explorer", "Pulsefire", "TPA", "Debonair", "Ace of Spades"},
	-- F
	["FiddleSticks"] = {"Classic", "Spectral", "Union Jack", "Bandito", "Pumpkinhead", "Fiddle Me Timbers", "Surprise Party", "Dark Candy", "Risen"},
	["Fiora"] = {"Classic", "Royal Guard", "Nightraven", "Headmistress", "PROJECT"},
	["Fizz"] = {"Classic", "Atlantean", "Tundra", "Fisherman", "Void", "Chroma Pack: Orange", "Chroma Pack: Black", "Chroma Pack: Red", "Cottontail"},
	-- G
	["Galio"] = {"Classic", "Enchanted", "Hextech", "Commando", "Gatekeeper", "Debonair"},
	["Gangplank"] = {"Classic", "Spooky", "Minuteman", "Sailor", "Toy Soldier", "Special Forces", "Sultan", "Captain"},
	["Garen"] = {"Classic", "Sanguine", "Desert Trooper", "Commando", "Dreadknight", "Rugged", "Steel Legion", "Chroma Pack: Garnet", "Chroma Pack: Plum", "Chroma Pack: Ivory", "Rogue Admiral"},
	["Gnar"] = {"Classic", "Dino", "Gentleman"},
	["Gragas"] = {"Classic", "Scuba", "Hillbilly", "Santa", "Gragas, Esq.", "Vandal", "Oktoberfest", "Superfan", "Fnatic", "Caskbreaker"},
	["Graves"] = {"Classic", "Hired Gun", "Jailbreak", "Mafia", "Riot", "Pool Party", "Cutthroat"},
	-- H
	["Hecarim"] = {"Classic", "Blood Knight", "Reaper", "Headless", "Arcade", "Elderwood"},
	["Heimerdinger"] = {"Classic", "Alien Invader", "Blast Zone", "Piltover Customs", "Snowmerdinger", "Hazmat"},
	-- I
	["Illaoi"] = {"Classic", "Void Bringer"},
	["Irelia"] = {"Classic", "Nightblade", "Aviator", "Infiltrator", "Frostblade", "Order of the Lotus"},
	-- J
	["Janna"] = {"Classic", "Tempest", "Hextech", "Frost Queen", "Victorious", "Forecast", "Fnatic"},
	["JarvanIV"] = {"Classic", "Commando", "Dragonslayer", "Darkforge", "Victorious", "Warring Kingdoms", "Fnatic"},
	["Jax"] = {"Classic", "The Mighty", "Vandal", "Angler", "PAX", "Jaximus", "Temple", "Nemesis", "SKT T1", "Chroma Pack: Cream", "Chroma Pack: Amber", "Chroma Pack: Brick", "Warden"},
	["Jayce"] = {"Classic", "Full Metal", "Debonair", "Forsaken"},
	["Jinx"] = {"Classic", "Mafia", "Firecracker", "Slayer"},
	-- K
	["Kalista"] = {"Classic", "Blood Moon", "Championship"},
	["Karma"] = {"Classic", "Sun Goddess", "Sakura", "Traditional", "Order of the Lotus", "Warden"},
	["Karthus"] = {"Classic", "Phantom", "Statue of", "Grim Reaper", "Pentakill", "Fnatic", "Chroma Pack: Burn", "Chroma Pack: Blight", "Chroma Pack: Frostbite"},
	["Kassadin"] = {"Classic", "Festival", "Deep One", "Pre-Void", "Harbinger", "Cosmic Reaver"},
	["Katarina"] = {"Classic", "Mercenary", "Red Card", "Bilgewater", "Kitty Cat", "High Command", "Sandstorm", "Slay Belle", "Warring Kingdoms"},
	["Kayle"] = {"Classic", "Silver", "Viridian", "Unmasked", "Battleborn", "Judgment", "Aether Wing", "Riot"},
	["Kennen"] = {"Classic", "Deadly", "Swamp Master", "Karate", "Kennen M.D.", "Arctic Ops"},
	["Khazix"] = {"Classic", "Mecha", "Guardian of the Sands"},
	["Kindred"] = {"Classic", "Shadowfire"},
	["KogMaw"] = {"Classic", "Caterpillar", "Sonoran", "Monarch", "Reindeer", "Lion Dance", "Deep Sea", "Jurassic", "Battlecast"},
	-- L
	["Leblanc"] = {"Classic", "Wicked", "Prestigious", "Mistletoe", "Ravenborn"},
	["LeeSin"] = {"Classic", "Traditional", "Acolyte", "Dragon Fist", "Muay Thai", "Pool Party", "SKT T1", "Chroma Pack: Black", "Chroma Pack: Blue", "Chroma Pack: Yellow", "Knockout"},
	["Leona"] = {"Classic", "Valkyrie", "Defender", "Iron Solari", "Pool Party", "Chroma Pack: Pink", "Chroma Pack: Azure", "Chroma Pack: Lemon", "PROJECT"},
	["Lissandra"] = {"Classic", "Bloodstone", "Blade Queen"},
	["Lucian"] = {"Classic", "Hired Gun", "Striker", "Chroma Pack: Yellow", "Chroma Pack: Red", "Chroma Pack: Blue", "PROJECT"},
	["Lulu"] = {"Classic", "Bittersweet", "Wicked", "Dragon Trainer", "Winter Wonder", "Pool Party"},
	["Lux"] = {"Classic", "Sorceress", "Spellthief", "Commando", "Imperial", "Steel Legion", "Star Guardian"},
	-- M
	["Malphite"] = {"Classic", "Shamrock", "Coral Reef", "Marble", "Obsidian", "Glacial", "Mecha", "Ironside"},
	["Malzahar"] = {"Classic", "Vizier", "Shadow Prince", "Djinn", "Overlord", "Snow Day"},
	["Maokai"] = {"Classic", "Charred", "Totemic", "Festive", "Haunted", "Goalkeeper"},
	["MasterYi"] = {"Classic", "Assassin", "Chosen", "Ionia", "Samurai Yi", "Headhunter", "Chroma Pack: Gold", "Chroma Pack: Aqua", "Chroma Pack: Crimson", "PROJECT"},
	["MissFortune"] = {"Classic", "Cowgirl", "Waterloo", "Secret Agent", "Candy Cane", "Road Warrior", "Mafia", "Arcade", "Captain"},
	["Mordekaiser"] = {"Classic", "Dragon Knight", "Infernal", "Pentakill", "Lord", "King of Clubs"},
	["Morgana"] = {"Classic", "Exiled", "Sinful Succulence", "Blade Mistress", "Blackthorn", "Ghost Bride", "Victorious", "Chroma Pack: Toxic", "Chroma Pack: Pale", "Chroma Pack: Ebony","Lunar"},
	-- N
	["Nami"] = {"Classic", "Koi", "River Spirit", "Urf", "Chroma Pack: Sunbeam", "Chroma Pack: Smoke", "Chroma Pack: Twilight"},
	["Nasus"] = {"Classic", "Galactic", "Pharaoh", "Dreadknight", "Riot K-9", "Infernal", "Archduke", "Chroma Pack: Burn", "Chroma Pack: Blight", "Chroma Pack: Frostbite",},
	["Nautilus"] = {"Classic", "Abyssal", "Subterranean", "AstroNautilus", "Warden"},
	["Nidalee"] = {"Classic", "Snow Bunny", "Leopard", "French Maid", "Pharaoh", "Bewitching", "Headhunter", "Warring Kingdoms"},
	["Nocturne"] = {"Classic", "Frozen Terror", "Void", "Ravager", "Haunting", "Eternum"},
	["Nunu"] = {"Classic", "Sasquatch", "Workshop", "Grungy", "Nunu Bot", "Demolisher", "TPA", "Zombie"},
	-- O
	["Olaf"] = {"Classic", "Forsaken", "Glacial", "Brolaf", "Pentakill", "Marauder"},
	["Orianna"] = {"Classic", "Gothic", "Sewn Chaos", "Bladecraft", "TPA", "Winter Wonder"},
	-- P
	["Pantheon"] = {"Classic", "Myrmidon", "Ruthless", "Perseus", "Full Metal", "Glaive Warrior", "Dragonslayer", "Slayer"},
	["Poppy"] = {"Classic", "Noxus", "Lollipoppy", "Blacksmith", "Ragdoll", "Battle Regalia", "Scarlet Hammer"},
	-- Q
	["Quinn"] = {"Classic", "Phoenix", "Woad Scout", "Corsair"},
	-- R
	["Rammus"] = {"Classic", "King", "Chrome", "Molten", "Freljord", "Ninja", "Full Metal", "Guardian of the Sands"},
	["Reksai"] = {"Classic", "Eternum", "Pool Party"},
	["Renekton"] = {"Classic", "Galactic", "Outback", "Bloodfury", "Rune Wars", "Scorched Earth", "Pool Party", "Scorched Earth", "Prehistoric"},
	["Rengar"] = {"Classic", "Headhunter", "Night Hunter", "SSW"},
	["Riven"] = {"Classic", "Redeemed", "Crimson Elite", "Battle Bunny", "Championship", "Dragonblade", "Arcade"},
	["Rumble"] = {"Classic", "Rumble in the Jungle", "Bilgerat", "Super Galaxy"},
	["Ryze"] = {"Classic", "Human", "Tribal", "Uncle", "Triumphant", "Professor", "Zombie", "Dark Crystal", "Pirate", "Whitebeard"},
	-- S
	["Sejuani"] = {"Classic", "Sabretusk", "Darkrider", "Traditional", "Bear Cavalry", "Poro Rider"},
	["Shaco"] = {"Classic", "Mad Hatter", "Royal", "Nutcracko", "Workshop", "Asylum", "Masked", "Wild Card"},
	["Shen"] = {"Classic", "Frozen", "Yellow Jacket", "Surgeon", "Blood Moon", "Warlord", "TPA"},
	["Shyvana"] = {"Classic", "Ironscale", "Boneclaw", "Darkflame", "Ice Drake", "Championship"},
	["Singed"] = {"Classic", "Riot Squad", "Hextech", "Surfer", "Mad Scientist", "Augmented", "Snow Day", "SSW"},
	["Sion"] = {"Classic", "Hextech", "Barbarian", "Lumberjack", "Warmonger"},
	["Sivir"] = {"Classic", "Warrior Princess", "Spectacular", "Huntress", "Bandit", "PAX", "Snowstorm", "Warden", "Victorious"},
	["Skarner"] = {"Classic", "Sandscourge", "Earthrune", "Battlecast Alpha", "Guardian of the Sands"},
	["Sona"] = {"Classic", "Muse", "Pentakill", "Silent Night", "Guqin", "Arcade", "DJ"},
	["Soraka"] = {"Classic", "Dryad", "Divine", "Celestine", "Reaper", "Order of the Banana"},
	["Swain"] = {"Classic", "Northern Front", "Bilgewater", "Tyrant"},
	["Syndra"] = {"Classic", "Justicar", "Atlantean", "Queen of Diamonds"},
	-- T
	["TahmKench"] = {"Classic", "Master Chef"},
	["Talon"] = {"Classic", "Renegade", "Crimson Elite", "Dragonblade", "SSW"},
	["Taric"] = {"Classic", "Emerald", "Armor of the Fifth Age", "Bloodstone"},
	["Teemo"] = {"Classic", "Happy Elf", "Recon", "Badger", "Astronaut", "Cottontail", "Super", "Panda", "Omega Squad"},
	["Thresh"] = {"Classic", "Deep Terror", "Championship", "Blood Moon", "SSW"},
	["Tristana"] = {"Classic", "Riot Girl", "Earnest Elf", "Firefighter", "Guerilla", "Buccaneer", "Rocket Girl", "Chroma Pack: Navy", "Chroma Pack: Purple", "Chroma Pack: Orange", "Dragon Trainer"},
	["Trundle"] = {"Classic", "Lil' Slugger", "Junkyard", "Traditional", "Constable"},
	["Tryndamere"] = {"Classic", "Highland", "King", "Viking", "Demonblade", "Sultan", "Warring Kingdoms", "Nightmare"},
	["TwistedFate"] = {"Classic", "PAX", "Jack of Hearts", "The Magnificent", "Tango", "High Noon", "Musketeer", "Underworld", "Red Card", "Cutpurse"},
	["Twitch"] = {"Classic", "Kingpin", "Whistler Village", "Medieval", "Gangster", "Vandal", "Pickpocket", "SSW"},
	-- U
	["Udyr"] = {"Classic", "Black Belt", "Primal", "Spirit Guard", "Definitely Not"},
	["Urgot"] = {"Classic", "Giant Enemy Crabgot", "Butcher", "Battlecast"},
	-- V
	["Varus"] = {"Classic", "Blight Crystal", "Arclight", "Arctic Ops", "Heartseeker", "Swiftbolt"},
	["Vayne"] = {"Classic", "Vindicator", "Aristocrat", "Dragonslayer", "Heartseeker", "SKT T1", "Arclight", "Chroma Pack: Green", "Chroma Pack: Red", "Chroma Pack: Silver"},
	["Veigar"] = {"Classic", "White Mage", "Curling", "Veigar Greybeard", "Leprechaun", "Baron Von", "Superb Villain", "Bad Santa", "Final Boss"},
	["Velkoz"] = {"Classic", "Battlecast", "Arclight"},
	["Vi"] = {"Classic", "Neon Strike", "Officer", "Debonair", "Demon"},
	["Viktor"] = {"Classic", "Full Machine", "Prototype", "Creator"},
	["Vladimir"] = {"Classic", "Count", "Marquis", "Nosferatu", "Vandal", "Blood Lord", "Soulstealer", "Academy"},
	["Volibear"] = {"Classic", "Thunder Lord", "Northern Storm", "Runeguard", "Captain"},
	-- W
	["Warwick"] = {"Classic", "Grey", "Urf the Manatee", "Big Bad", "Tundra Hunter", "Feral", "Firefang", "Hyena", "Marauder"},
	["MonkeyKing"] = {"Classic", "Volcanic", "General", "Jade Dragon", "Underworld","Radiant"},
	-- X
	["Xerath"] = {"Classic", "Runeborn", "Battlecast", "Scorched Earth", "Guardian of the Sands"},
	["XinZhao"] = {"Classic", "Commando", "Imperial", "Viscero", "Winged Hussar", "Warring Kingdoms", "Secret Agent"},
	-- Y
	["Yasuo"] = {"Classic", "High Noon", "PROJECT"},
	["Yorick"] = {"Classic", "Undertaker", "Pentakill"},
	-- Z
	["Zac"] = {"Classic", "Special Weapon", "Pool Party", "Chroma Pack: Orange", "Chroma Pack: Bubblegum", "Chroma Pack: Honey"},
	["Zed"] = {"Classic", "Shockblade", "SKT T1", "PROJECT"},
	["Ziggs"] = {"Classic", "Mad Scientist", "Major", "Pool Party", "Snow Day", "Master Arcanist"},
	["Zilean"] = {"Classic", "Old Saint", "Groovy", "Shurima Desert", "Time Machine", "Blood Moon"},
	["Zyra"] = {"Classic", "Wildfire", "Haunted", "SKT T1"},
}




-----------------------------------------------------------------------------------------------------------------------------------------------------




function message(i)
  do
    print(string.format("<font color=\"#FC5743\"><b>Universal Skin Changer Message: </b></font><font color=\"#E53CD4\">"..i.."</font>"))
  end
end

function LoadMenu()
	do
	print("hi")
		SkinChanger = MenuConfig("Skin Changer", "Skin Changer")
		SkinChanger:Menu("Settings", "Settings", "user")
		SkinChanger.Settings:Section("Skin Changer")
		SkinChanger.Settings:Menu("me", "My Hero")
		SkinChanger.Settings.me:DropDown("me", "Change "..myHero.charName.." Skin", 1, SkinNames[myHero.charName], function(Val) SetSkin(myHero, Val - 1) end)
		SkinChanger.Settings:Menu("ally", "Allies", "gamepad")
		SkinChanger.Settings:Menu("enemy", "Enemies", "leaf")
		for i = 1,6 do
			if GetEnemyHeroes()[i] ~= nil then
				SkinChanger.Settings.enemy:DropDown("EnemyNumber"..i, "Change "..GetEnemyHeroes()[i].charName.." Skin", 1, SkinNames[GetEnemyHeroes()[i].charName], function(Val) SetSkin(GetEnemyHeroes()[i], Val - 1) end)
			end
			if GetAllyHeroes()[i] ~= nil then
				SkinChanger.Settings.ally:DropDown("AllyNumber"..i, "Change "..GetAllyHeroes()[i].charName.." Skin", 1, SkinNames[GetAllyHeroes()[i].charName], function(Val) SetSkin(GetAllyHeroes()[i], Val - 1) end)
			end
		end
	end
end

function OnLoad()
local GotMenu = 0
	if (FileExist(LIB_PATH.."MenuConfig.lua")) then
		GotMenu = 1
	  require 'MenuConfig'
	else
	  message("Downloading MenuConfig, please don't reload script!")
	  DownloadFile("https://raw.githubusercontent.com/linkpad/BoL/master/Common/MenuConfig.lua?rand="..math.random(1, 10000), LIB_PATH.."MenuConfig.lua", function() message("Finsihed downloading MenuConfig, please reload script!")
	  end)
	end
	if GotMenu == 1 then
		LoadMenu()
	end
	DelayAction(function() message("Maybe I'm missing some skins, if you find a champion that has not all the skins, post it in the thread and i'll add them :) ") end, 5)
end

function OnUnLoad()
	do
		message("I hope to see you soon! Good day/night")
	end
end
