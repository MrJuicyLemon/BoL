local sVersion = '1.00';
local rVersion = GetWebResult('raw.githubusercontent.com', '/MrJuicyLemon/BoL/master/ZzStun.version?no-cache=' .. math.random(1, 25000));

if ((rVersion) and (tonumber(rVersion) ~= nil)) then
	if (tonumber(sVersion) < tonumber(rVersion)) then
		print('<font color="#FF1493"><b>[VayneZzStun]</b> </font><font color="#FFFF00">An update has been found and it is now downloading!</font>');
		DownloadFile('https://raw.githubusercontent.com/MrJuicyLemon/BoL/master/ZzStun.lua?no-cache=' .. math.random(1, 25000), (SCRIPT_PATH.. GetCurrentEnv().FILE_NAME), function()
			print('<font color="#FF1493"><b>[VayneZzStun]</b> </font><font color="#00FF00">Script successfully updated, please double-press F9 to reload!</font>');
		end);
		return;
	end;
else
	print('<font color="#FF1493"><b>[VayneZzStun]</b> </font><font color="#FF0000">Update Error</font>');
end;

if myHero.charName ~= "Vayne" then return end


function message(i)
  do
    print(string.format("<font color=\"#FC5743\"><b>Skin Changer Message: </b></font><font color=\"#E53CD4\">"..i.."</font>"))
  end
end

function LoadMenu()
	ZZVayne = MenuConfig("ZZRotVayne", "ZZRotVayne")
	ZZVayne:KeyBinding("Enable", "Stomp enemy with zzrot pressing:", string.byte("T"))
	ZZVayne:Boolean("ZZRange", "Draw ZZRange", false)
	ZZVayne:Boolean("ZZLand", "Draw Stun Prediction", false)
end

function OnLoad()
	if (FileExist(LIB_PATH.."VPrediction.lua")) then
		require "VPrediction"
	else
	  message("Downloading VPrediction, please don't reload script!")
	  DownloadFile("https://raw.githubusercontent.com/SidaBoL/Scripts/master/Common/VPrediction.lua?rand="..math.random(1, 10000), LIB_PATH.."VPrediction.lua", function() message("Finsihed downloading VPrediction, please reload script!")
	  end)
	end
	eTargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, 350, DAMAGE_PHYSICAL, false, true)
  vPred = VPrediction()
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
end

function GotItemSlot(name)
    for slot = 6, 12 do
        if myHero:GetSpellData(slot).name:lower() == name:lower() then 
        	return true,slot 
        end
    end
    return false
end

function OnTick()
	eTargetSelector:update()
	if ZZVayne.Enable then Stun() end
end

function Stun()
	if not ValidTarget(eTargetSelector.target) then return end
	local CastPosition, HitChance = vPred:GetPredictedPos(eTargetSelector.target, 0.4, 1800, myHero, false)
  local myVector = Vector(CastPosition) + Vector(Vector(CastPosition) - Vector(myHero)):normalized()*60
	local gotIt , slot = GotItemSlot("ItemVoidGate")
  if gotIt then
		if GetInventoryHaveItem(3512) then
			if GetDistance(myHero, GetTarget()) <= 400 then
				if myHero:CanUseSpell(_E) == READY and myHero:CanUseSpell(myHero:getInventorySlot(3512)) == READY then
					--print("h")
					CastSpell(_E, GetTarget())
					DelayAction(function() CastSpell(slot, myVector.x, myVector.z) end, 0.01)
				end
			end
		end
	end
end
function OnDraw()
	if ZZVayne.ZZRange then
		DrawCircle(myHero.x, myHero.y, myHero.z, 400, ARGB(255,255,255,255))
	end
    if ZZVayne.ZZLand and ValidTarget(GetTarget()) then
        local myVector = Vector(GetTarget()) + Vector(Vector(GetTarget()) - Vector(myHero)):normalized() * 60
        DrawCircle(myVector.x, myVector.y, myVector.z, 100, ARGB(255, 255, 255 , 250))
    end
end
