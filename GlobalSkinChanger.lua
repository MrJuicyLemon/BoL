Global = scriptConfig("Global Skin Changer", "Global Skin Changer")
Global:addSubMenu("Settings", "a1st")
Global.a1st:addSubMenu("My Hero", "me")
Global.a1st.me:addParam("me", "Change "..myHero.charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
Global.a1st.me:setCallback("me", function(Val) SetSkin(myHero, Val - 1) end)
Global.a1st:addSubMenu("Enemies", "enemy")
Global.a1st:addSubMenu("Allies", "ally")
for i = 1,5 do
	if GetEnemyHeroes()[i] ~= nil then
		Global.a1st.enemy:addParam("EnemyNumber"..i, "Change "..GetEnemyHeroes()[i].charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
		Global.a1st.enemy:setCallback("EnemyNumber"..i, function(Val) SetSkin(GetEnemyHeroes()[i], Val - 1) end)
	end
	if GetAllyHeroes()[i] ~= nil then
		Global.a1st.ally:addParam("AllyNumber"..i, "Change "..GetAllyHeroes()[i].charName.." Skin", SCRIPT_PARAM_SLICE, 1, 1, 13)
		Global.a1st.ally:setCallback("AllyNumber"..i, function(Val) SetSkin(GetAllyHeroes()[i], Val - 1) end)
	end
end
