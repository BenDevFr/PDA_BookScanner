-- media/lua/shared/BookScanner/BSLogger.lua
-- Centralized logging system with auto debug detection

BookScanner = BookScanner or {}
BookScanner.Logger = BookScanner.Logger or {}

-- Detect if game is in debug mode
local function isDebugMode()
	-- Check multiple debug indicators
	if getDebug and getDebug() then
		return true
	end
	if DebugOptions and DebugOptions.instance then
		return true
	end
	if isDebugEnabled and isDebugEnabled() then
		return true
	end
	return false
end

-- Auto-detect debug mode and set log level
BookScanner.Logger.debugMode = isDebugMode()
BookScanner.Logger.logLevel = BookScanner.Logger.debugMode and 3 or 1

-- Log levels:
-- 1 = Normal (user) - essential messages only
-- TODO 2 = Debug - detailed technical info
-- 3 = Verbose - extremely detailed info

-- Normal log (always visible)
function BookScanner.Logger.log(message)
	if BookScanner.Logger.logLevel >= 1 then
		print("[BookScanner] " .. tostring(message))
	end
end

-- Debug log (only in debug mode)
function BookScanner.Logger.debug(message)
	if BookScanner.Logger.logLevel >= 2 then
		print("[BookScanner:DEBUG] " .. tostring(message))
	end
end

-- Verbose log (only in debug mode, ultra detailed)
function BookScanner.Logger.verbose(message)
	if BookScanner.Logger.logLevel >= 3 then
		print("[BookScanner:VERBOSE] " .. tostring(message))
	end
end

-- Warning (always visible)
function BookScanner.Logger.warn(message)
	print("[BookScanner:WARN] " .. tostring(message))
end

-- Error (always visible)
function BookScanner.Logger.error(message)
	print("[BookScanner:ERROR] " .. tostring(message))
end

-- Visual separator
function BookScanner.Logger.separator()
	if BookScanner.Logger.logLevel >= 2 then
		print("[BookScanner] " .. string.rep("-", 60))
	end
end

-- Section header
function BookScanner.Logger.section(title)
	if BookScanner.Logger.logLevel >= 2 then
		print("[BookScanner] === " .. title .. " ===")
	end
end

-- Initial log
if BookScanner.Logger.debugMode then
	BookScanner.Logger.log("Debug mode detected - Full logging enabled")
else
	BookScanner.Logger.log("Normal mode - Essential logging only")
end
