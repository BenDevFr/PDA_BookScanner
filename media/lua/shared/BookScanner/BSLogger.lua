-- media/lua/shared/BookScanner/BSLogger.lua
-- Logging system with level-based filtering

require("BookScanner/BSConfig")

BookScanner = BookScanner or {}

local BSLogger = {}
BookScanner.Logger = BSLogger

-- Log format helpers
local function formatLog(level, message)
	return "[BookScanner" .. (level and ":" .. level or "") .. "] " .. message
end

-- Core logging functions
function BSLogger.log(message)
	print(formatLog(nil, message))
end

function BSLogger.error(message)
	print(formatLog("ERROR", message))
end

function BSLogger.debug(message)
	if not BookScanner.Config.debugMode then
		return
	end
	print(formatLog("DEBUG", message))
end

-- Visual separators
function BSLogger.separator()
	BSLogger.log("------------------------------------------------------------")
end

function BSLogger.section(title)
	BSLogger.log("=== " .. title .. " ===")
end

BSLogger.log("BSLogger.lua loaded - Debug mode: " .. tostring(BookScanner.Config.debugMode))
