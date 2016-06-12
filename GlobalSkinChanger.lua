SkinChanger = scriptConfig("SkinChanger Skin Changer", "SkinChanger Skin Changer")
SkinChanger:addSubMenu("Settings", "Settings")
SkinChanger.Settings:addSubMenu("My Hero", "me")
SkinChanger.Settings.me:addParam("me", "Change "..myHero.charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
SkinChanger.Settings.me:setCallback("me", function(Val) SetSkin(myHero, Val - 1) end)
SkinChanger.Settings:addSubMenu("Enemies", "enemy")
SkinChanger.Settings:addSubMenu("Allies", "ally")
for i = 1,5 do
	if GetEnemyHeroes()[i] ~= nil then
		SkinChanger.Settings.enemy:addParam("EnemyNumber"..i, "Change "..GetEnemyHeroes()[i].charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
		SkinChanger.Settings.enemy:setCallback("EnemyNumber"..i, function(Val) SetSkin(GetEnemyHeroes()[i], Val - 1) end)
	end
	if GetAllyHeroes()[i] ~= nil then
		SkinChanger.Settings.ally:addParam("AllyNumber"..i, "Change "..GetAllyHeroes()[i].charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
		SkinChanger.Settings.ally:setCallback("AllyNumber"..i, function(Val) SetSkin(GetAllyHeroes()[i], Val - 1) end)
	end
end
