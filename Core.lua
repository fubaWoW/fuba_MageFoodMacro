local addon, ns = ...

local DefaultSettings = {
  options = {
		conjureOnRightClick = true,
		macroName = "MageFoodMacro"
  },
  version = 1,
}

local function CreateDatabase()
  if (not fubaMageFoodMacroDB) or (fubaMageFoodMacroDB == nil) then fubaMageFoodMacroDB = DefaultSettings end
end

local function ReCreateDatabase()
  fubaMageFoodMacroDB = DefaultSettings
end

function fubaPrintDebug(debugtext)
  if fubaMageFoodMacroDB and fubaMageFoodMacroDB.options and fubaMageFoodMacroDB.options.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000fubaDebug\[|r"..debugtext.."|cffff8000\]")
  end
end

if not fubaMageFoodMacroDB then
  CreateDatabase()
  fubaPrintDebug("Database: Create default Database because empty")
end

if fubaMageFoodMacroDB.version and fubaMageFoodMacroDB.version < DefaultSettings.version then
  -- do something if "Database Version" is an older version and maybe need attention?!
  fubaPrintDebug("Database: Old version found")
end

-- actual Code, do not modify except you know what you are doing )
local MageFood = CreateFrame("FRAME", "MageFood", UIParent)
MageFood:RegisterEvent("PLAYER_ENTERING_WORLD")
MageFood:RegisterEvent("BAG_UPDATE")
MageFood:RegisterEvent("CHAT_MSG_LOOT")
MageFood:RegisterEvent("UNIT_AURA")
MageFood:RegisterEvent("PLAYER_REGEN_ENABLED")

local InCombatLockdown = _G.InCombatLockdown
local UnitAffectingCombat = _G.UnitAffectingCombat
local GetSpellLink = _G.GetSpellLink
local GetItemCount = _G.GetItemCount
local GetMacroIndexByName = _G.GetMacroIndexByName
local CreateMacro = _G.CreateMacro
local EditMacro = _G.EditMacro

local GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo -- backward compatibility if needed?
local spellNameConjureRefreshment = GetSpellName(190336) or GetSpellName(42955) or "Conjure Refreshment" -- get Localized Spell Name or just use Conjure Refreshment if nothing found
local TaintableDelayedEvent = false
local MageIsInWorld = false
local forceUpdate = false
local BestMageFoodInBag = 0

local function IsTaintable()
  return (InCombatLockdown() or (UnitAffectingCombat("player") or UnitAffectingCombat("pet")))
end

local MageFoodIDs = {
	113509,	--Conjured Mana Bun
	80618,	--Conjured Mana Fritter
	80610,	--Conjured Mana Pudding
	65517,	--Conjured Mana Lollipop
	65516,	--Conjured Mana Cupcake
	65515,	--Conjured Mana Brownie
	65500,	--Conjured Mana Cookie
	65499,	--Conjured Mana Cake
	43523,	--Conjured Mana Strudel
	43518,	--Conjured Mana Pie
	34062,	--Conjured Mana Biscuit
	--5349		--Conjured Muffin
}

local function CreateOrUpdateMacro()
	if IsTaintable() then
		TaintableDelayedEvent = true
		return
	end

	BestMageFoodInBag = BestMageFoodInBag or 0
	
	local macroName = (fubaMageFoodMacroDB and fubaMageFoodMacroDB.options and fubaMageFoodMacroDB.options.macroName) or DefaultSettings.options.macroName
	local conjureOnRightClick = (fubaMageFoodMacroDB and fubaMageFoodMacroDB.options and fubaMageFoodMacroDB.options.conjureOnRightClick) or DefaultSettings.options.conjureOnRightClick
	local MacroIndex = GetMacroIndexByName(macroName)
	local macroId = 0
	
	if (MacroIndex == 0) then  -- Use "Conjured Mana Biscuit" by default if there is not Mage Item in inventoery
		local macroln1 = ""
		local macroln2 = ""
		local itemUseString = "item:34062" -- use Item by ID (Conjured Mana Biscuit)
		
		macroln1 = "#showtooltip "..itemUseString.."\n"
		if conjureOnRightClick then
			macroln2 = "/use [btn:2]"..spellNameConjureRefreshment..""..itemUseString.."\n"
		else
			macroln2 = "/use "..itemUseString.."\n"
		end
	
		macroId = CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroln1..macroln2, nil)
	else		
		for _,v in ipairs(MageFoodIDs) do
			if GetItemCount(v) > 0 then
				BestMageFoodInBag = v
				break
			end
		end
		if BestMageFoodInBag == 0 then return end
		
		local macroln1 = ""
		local macroln2 = ""
		local itemUseString = "item:"..BestMageFoodInBag

		macroln1 = "#showtooltip "..itemUseString.."\n"
		if conjureOnRightClick then
			macroln2 = "/use [btn:2]"..spellNameConjureRefreshment..""..itemUseString.."\n"
		else
			macroln2 = "/use "..itemUseString.."\n"
		end

			macroId = EditMacro(MacroIndex, macroName, "INV_MISC_QUESTIONMARK", macroln1..macroln2)
	end
end

MageFood:SetScript("OnEvent", function(self, event, ...)

	-- check for InCombat or any other Taintable situation
	if IsTaintable() then
		TaintableDelayedEvent = true
		return
	end

	BestMageFoodInBag = BestMageFoodInBag or 0
	if GetItemCount(BestMageFoodInBag) > 0 then return end

	if (event=="PLAYER_REGEN_ENABLED") then
		-- event: PLAYER_REGEN_ENABLED
		if (TaintableDelayedEvent == true) then
			CreateOrUpdateMacro()
			TaintableDelayedEvent = false
		end
	elseif (event=="PLAYER_ENTERING_WORLD") then
		-- event: PLAYER_ENTERING_WORLD
		MageIsInWorld = true
		CreateOrUpdateMacro()
	elseif (event=="BAG_UPDATE" and MageIsInWorld == true) then
		-- event: BAG_UPDATE
		CreateOrUpdateMacro()
	elseif (event=="CHAT_MSG_LOOT") then
		-- event: CHAT_MSG_LOOT
		CreateOrUpdateMacro()
	elseif (event=="UNIT_AURA") then
		-- event: UNIT_AURA
		local arg1 = ...
		if (arg1=="player") then
			CreateOrUpdateMacro()
		end

	end

end)

_G['SLASH_' .. addon .. 'Settings' .. 1] = '/mfm'
_G['SLASH_' .. addon .. 'Settings' .. 2] = '/magefoodmacro'
SlashCmdList[addon .. 'Settings'] = function(msg)
	if not msg or type(msg) ~= "string" or msg == "" or msg == "help" then
    print("|cffff8000\nMage Food Macro Usage:\n|r==========================================================\n|cffff8000/mfm|r or |cffff8000/mfm help|r - Show this message\n|cffff8000/mfm name <MacroName>|r or |cffff8000/mfm n <MacroName>|r - Change the Macro Name that is used for Update (Default: MageFoodMacro)\n|cffff8000/mfm conjure|r or |cffff8000/mfm cast|r or |cffff8000/mfm c|r - Toggle \"Cast "..spellNameConjureRefreshment.." when Right-Click the Macro\"\n|cffff8000/mfm reset yes|r - Reset to Default Values\n|r==========================================================")
    return
  end

	local cmd, arg = msg:trim():match("^(%S*)%s*(.-)$") -- split at the first space but keep all following spaces
	cmd = cmd:lower()
	if (cmd == "macroname" or cmd == "name" or cmd == "n") then
		if ( arg and #arg > 0 ) then
			if fubaMageFoodMacroDB and fubaMageFoodMacroDB.options then
				print("|cffff8000[Mage Food Macro]|rMacro Name changed to: |r"..arg)
				fubaMageFoodMacroDB.options.macroName = arg
				CreateOrUpdateMacro()
			end
		end
	elseif (cmd == "conjure" or cmd == "cast" or cmd == "c") then
		if fubaMageFoodMacroDB and fubaMageFoodMacroDB.options then
			if fubaMageFoodMacroDB.options.conjureOnRightClick == true then
				print("|cffff8000[Mage Food Macro]|rRight-Click the Macro to cast "..spellNameConjureRefreshment..": |cffFF0000Disabled|r")
				fubaMageFoodMacroDB.options.conjureOnRightClick = false
				CreateOrUpdateMacro()
			else
				print("|cffff8000[Mage Food Macro]|rRight-Click the Macro to cast "..spellNameConjureRefreshment..": |cff00FF00Enabled|r")
				fubaMageFoodMacroDB.options.conjureOnRightClick = true
				CreateOrUpdateMacro()
			end
		end
	elseif (cmd == "reset") and (arg and arg == "yes") then
		ReCreateDatabase()
		CreateOrUpdateMacro()
		print("|cffff8000[Mage Food Macro]|rDatabase reset to Default values.")
	end
end