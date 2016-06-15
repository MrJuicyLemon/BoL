local GotMenu = 0
function OnLoad()
	do
	  if (FileExist(LIB_PATH.."MenuConfig.lua")) then
	    require 'MenuConfig'
	  else
	    GotMenu = 1
	    message("Downloading MenuConfig, please don't reload script!")
	    DownloadFile("https://raw.githubusercontent.com/linkpad/BoL/master/Common/MenuConfig.lua?rand="..math.random(1, 10000), LIB_PATH.."MenuConfig.lua", function()
	      message("Finsihed downloading MenuConfig, please reload script!")
	  end)

	  if (FileExist(LIB_PATH.."NotificationLib.lua")) then
	    require 'NotificationLib'
	  else
	    message("Downloading NotificationLib, please don't reload script!")
	    DownloadFile("https://raw.githubusercontent.com/LunarBlue/Bol/master/Libraries/NotificationLib.lua?rand="..math.random(1, 10000), LIB_PATH.."NotificationLib.lua", function()
	      message("Finsihed downloading NotificationLib, please reload script!")
	  end)
	  
	  if GotMenu == 1 then
	  	LoadMenu()
	  else
	  	message("Library is being downloaded, please wait.")
	  end
	end
end

function OnUnLoad()
	do
		message("I hope to see you soon! Good day/night")
	end
end

function LoadMenu()
	do
		AFK = MenuConfig("Anti AFK", "Anti AFK")
		AFK:Menu("Settings", "Settings", "adjust-alt")
		AFK.Settings:Slider("ClickDelay", "Click Delay (ms)", 200, 50, 2000, 50)
		AFK.Settings:Boolean("SimulateClick", "Simulate Click with drawing", true)
		AFK.Settings:Info("Command", "To enable Anti AFK write")
		AFK.Settings:Info("Command2", "AFK ON to turn it on")
		AFK.Settings:Info("Command3", "AFK OFF to turn it off")
	end
end

local hasBeenDelayed = false

function AntiAFK()
	do
	  myHero:MoveTo(myHero.x, myHero.y)
	  if AFK.Settings.SimulateClick then
	  	DrawCircle3D(myHero.x, myHero.y, myHero.z, 3, 2, ARGB(255, 255, 120, 78), 32)
	  end
	  DelayAction(hasBeenDelayed = false, (AFK.Settings.ClickDelay/1000)/2)
	end
end

function OnSendChat(p)
	do
		if p = "AFK ON" then
			BlockChat()
			AfkMode = 1
			NotificationLib:AddTile("AntiAFK", "Mode: On", 3)
		end
		if p = "AFK OFF" then
			BlockChat()
			AfkMode = 0
			NotificationLib:AddTile("AntiAFK", "Mode: Off", 3)
		end
	end
end

local AfkMode = 0
function OnTick()
	do
		if AfkMode == 1 then
		  if not hasBeenDelayed then
		    DelayAction(AntiAFK(), (AFK.Settings.ClickDelay/1000)/2)
		    hasBeenDelayed = true
		  end
		end
end
