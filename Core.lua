--------------------------------------------------------------------------------
-- Turn-in Totals: one line at the top of the quest log with the XP and gold
-- of every quest that is ready to turn in.
--------------------------------------------------------------------------------

local L = {
	label = "Ready to turn in",
	quest = "quest",
	quests = "quests",
	optionName = "Show in the quest log",
	optionTooltip = "Shows the total XP and gold of the quests ready to turn in at the top of the quest log.\n\nOff: the line leaves right away. After a /reload with it off, the addon doesn't touch the quest log at all.",
}
if GetLocale() == "ptBR" then
	L.label = "Prontas para entregar"
	L.quest = "missão"
	L.quests = "missões"
	L.optionName = "Mostrar no registro de missões"
	L.optionTooltip = "Mostra o total de XP e ouro das missões prontas para entregar no topo do registro de missões.\n\nDesligado: a linha sai na hora. Depois de um /reload com a opção desligada, o addon não mexe mais no registro de missões."
end

local function Call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, a, b = pcall(fn, ...)
	if ok then return a, b end
end

local function IsReady(questID)
	if C_QuestLog.ReadyForTurnIn and Call(C_QuestLog.ReadyForTurnIn, questID) then return true end
	return Call(C_QuestLog.IsComplete, questID) and true or false
end

-- totals over the whole log (ignores the search box filter)
local function Collect()
	local count, xp, money, pending = 0, 0, 0, false
	local numEntries = Call(C_QuestLog.GetNumQuestLogEntries) or 0
	for index = 1, numEntries do
		local info = Call(C_QuestLog.GetInfo, index)
		local questID = info and info.questID
		if questID and questID > 0 and not info.isHeader and not info.isHidden and IsReady(questID) then
			count = count + 1
			if HaveQuestRewardData and not Call(HaveQuestRewardData, questID) then
				pending = true
				Call(C_QuestLog.RequestLoadQuestByID, questID)
			end
			xp = xp + (Call(GetQuestLogRewardXP, questID) or 0)
			money = money + (Call(GetQuestLogRewardMoney, questID) or 0)
		end
	end
	return count, xp, money, pending
end

local function FormatMoney(copper)
	if GetMoneyString then return GetMoneyString(copper, true) end
	return C_CurrencyInfo.GetCoinTextureString(copper)
end

local function FormatNumber(n)
	return BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n)
end

--------------------------------------------------------------------------------
-- The row above the quest list. Blizzard code never reads anything we write:
-- the row is our own frame (not a child of the list's layout) and room is made
-- only by moving the list's scroll frame down (geometry doesn't carry taint).
-- With the option off at login nothing is created or hooked.
--------------------------------------------------------------------------------

local ROW_HEIGHT = 40

local line      -- our row, above the search box
local hooked    -- hooksecurefunc can't be undone; the hook does nothing while disabled
local enabled = false
local original  -- the scroll frame's own anchors, to put back exactly

local function SaveAnchors(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do points[i] = { frame:GetPoint(i) } end
	return points
end

-- shift = 0 puts the list back where Blizzard had it
local function ShiftList(shift)
	if not original then return end
	local scroll = QuestScrollFrame
	scroll:ClearAllPoints()
	for _, p in ipairs(original) do
		local point, relativeTo, relativePoint, x, y = unpack(p)
		if point == "TOPLEFT" or point == "TOP" or point == "TOPRIGHT" then
			y = y - shift
		end
		scroll:SetPoint(point, relativeTo, relativePoint, x, y)
	end
end

local function Refresh()
	if not (enabled and line) then return end
	local count, xp, money, pending = Collect()

	if count > 0 then
		local parts = {}
		if xp > 0 then table.insert(parts, FormatNumber(xp) .. " XP") end
		if money > 0 then table.insert(parts, FormatMoney(money)) end
		if #parts == 0 then table.insert(parts, pending and "..." or "-") end
		line.Label:SetFormattedText("%s (%d %s)", L.label, count, count == 1 and L.quest or L.quests)
		line.Value:SetText(table.concat(parts, "   "))
		if not line:IsShown() then
			line:Show()
			ShiftList(ROW_HEIGHT)
		end
	elseif line:IsShown() then
		line:Hide()
		ShiftList(0)
	end
end

local function CreateLine(parent)
	line = CreateFrame("Frame", nil, parent)
	line:SetPoint("TOPLEFT", 0, 0)
	line:SetPoint("TOPRIGHT", 0, 0)
	line:SetHeight(ROW_HEIGHT)
	line:Hide()

	line.Label = line:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	line.Label:SetPoint("TOPLEFT", 10, -4)
	line.Label:SetPoint("RIGHT", -4, 0)
	line.Label:SetJustifyH("LEFT")
	line.Label:SetWordWrap(false)

	-- values on their own line: the label alone fills the width on ptBR / big UI scales
	line.Value = line:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	line.Value:SetPoint("TOPLEFT", line.Label, "BOTTOMLEFT", 0, -4)
	line.Value:SetPoint("RIGHT", -4, 0)
	line.Value:SetJustifyH("LEFT")
	line.Value:SetWordWrap(false)
end

local function Install()
	local parent = QuestMapFrame and QuestMapFrame.QuestsFrame
	if not (parent and QuestScrollFrame) then return end
	if not original then original = SaveAnchors(QuestScrollFrame) end
	if not line then CreateLine(parent) end
	enabled = true
	if not hooked then
		hooksecurefunc("QuestLogQuests_Update", Refresh)
		hooked = true
	end
	Refresh()
end

local function Uninstall()
	enabled = false
	if line and line:IsShown() then
		line:Hide()
		ShiftList(0)
	end
end

local function SetEnabled(value)
	TurnInTotalsDB.showInQuestLog = value and true or false
	if value then Install() else Uninstall() end
end

--------------------------------------------------------------------------------
-- Options panel (Esc > Options > AddOns > Turn-in Totals)
--------------------------------------------------------------------------------

local function BuildOptions()
	if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
	local category = Settings.RegisterVerticalLayoutCategory("Turn-in Totals")
	local varType = Settings.VarType and Settings.VarType.Boolean or "boolean"
	local setting = Settings.RegisterProxySetting(category, "TurnInTotals_showInQuestLog", varType,
		L.optionName, true,
		function() return TurnInTotalsDB.showInQuestLog end,
		SetEnabled)
	Settings.CreateCheckbox(category, setting, L.optionTooltip)
	Settings.RegisterAddOnCategory(category)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_DATA_LOAD_RESULT")
events:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		TurnInTotalsDB = TurnInTotalsDB or {}
		if TurnInTotalsDB.showInQuestLog == nil then TurnInTotalsDB.showInQuestLog = true end
		pcall(BuildOptions)
		if TurnInTotalsDB.showInQuestLog then Install() end
	elseif enabled and QuestMapFrame and QuestMapFrame:IsVisible() then
		Refresh()
	end
end)

SLASH_TURNINTOTALS1 = "/tit"
SlashCmdList.TURNINTOTALS = function()
	local count, xp, money = Collect()
	print(("|cffffd100Turn-in Totals|r: %d %s, %s XP, %s"):format(
		count, count == 1 and L.quest or L.quests, FormatNumber(xp), FormatMoney(money)))
end
