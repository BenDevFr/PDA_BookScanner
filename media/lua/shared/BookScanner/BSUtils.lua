-- media/lua/shared/BookScanner/BSUtils.lua
-- Common utility functions

BookScanner = BookScanner or {}
BookScanner.Utils = BookScanner.Utils or {}

-- Get player information safely
function BookScanner.Utils.getPlayerInfo(player)
	if not player then
		return nil, "Unknown", -1
	end

	local playerID = player:getID()
	local userName = player:getUsername() or "Unknown"

	return player, userName, playerID
end

-- Format player log message
function BookScanner.Utils.formatPlayerLog(player, message)
	local _, userName, playerID = BookScanner.Utils.getPlayerInfo(player)
	return "PlayerID: " .. playerID .. " (" .. userName .. ") - " .. message
end

-- Check if table contains value
function BookScanner.Utils.tableContains(table, value)
	for _, v in ipairs(table) do
		if v == value then
			return true
		end
	end
	return false
end

-- Count table elements
function BookScanner.Utils.tableCount(table)
	local count = 0
	for _ in pairs(table) do
		count = count + 1
	end
	return count
end

-- Check if string contains another (case insensitive)
function BookScanner.Utils.stringContains(str, search)
	if not str or not search then
		return false
	end
	return string.find(string.lower(str), string.lower(search), 1, true) ~= nil
end

-- Trim whitespace from string
function BookScanner.Utils.trim(str)
	if not str then
		return ""
	end
	return str:match("^%s*(.-)%s*$")
end

-- Deep copy table
function BookScanner.Utils.deepCopy(original)
	local copy
	if type(original) == "table" then
		copy = {}
		for k, v in pairs(original) do
			copy[k] = BookScanner.Utils.deepCopy(v)
		end
	else
		copy = original
	end
	return copy
end

-- Serialize simple table to string (for debug)
function BookScanner.Utils.tableToString(tbl, indent)
	indent = indent or 0
	local result = ""
	local indentStr = string.rep("  ", indent)

	if type(tbl) ~= "table" then
		return tostring(tbl)
	end

	result = "{\n"
	for k, v in pairs(tbl) do
		result = result .. indentStr .. "  [" .. tostring(k) .. "] = "
		if type(v) == "table" then
			result = result .. BookScanner.Utils.tableToString(v, indent + 1)
		else
			result = result .. tostring(v)
		end
		result = result .. ",\n"
	end
	result = result .. indentStr .. "}"
	return result
end
