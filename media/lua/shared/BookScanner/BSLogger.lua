-- media/lua/shared/BookScanner/BSLogger.lua
-- Centralized logging system for BookScanner

BookScanner = BookScanner or {}
BookScanner.Logger = BookScanner.Logger or {}

-- Log levels
BookScanner.Logger.Level = {
    ERROR = 1,
    INFO = 2,
    DEBUG = 3
}

-- Current level
BookScanner.Logger.currentLevel = BookScanner.Logger.Level.INFO
BookScanner.Logger.verboseMode = false

-- Constant prefix
local LOG_PREFIX = "[BookScanner]"

-- Standard log
function BookScanner.Logger.log(message)
    if BookScanner.Logger.currentLevel >= BookScanner.Logger.Level.INFO then
        print(LOG_PREFIX .. " " .. tostring(message))
    end
end

-- Error log (always shown)
function BookScanner.Logger.error(message)
    print(LOG_PREFIX .. " ERROR: " .. tostring(message))
end

-- Warning log (always shown)
function BookScanner.Logger.warn(message)
    print(LOG_PREFIX .. " WARNING: " .. tostring(message))
end

-- Debug log (only if enabled)
function BookScanner.Logger.debug(message)
    if BookScanner.Logger.currentLevel >= BookScanner.Logger.Level.DEBUG then
        print(LOG_PREFIX .. " [DEBUG] " .. tostring(message))
    end
end

-- Verbose log (ultra detailed, for hardcore dev)
function BookScanner.Logger.verbose(message)
    if BookScanner.Logger.verboseMode and BookScanner.Logger.currentLevel >= BookScanner.Logger.Level.DEBUG then
        print(LOG_PREFIX .. " [VERBOSE] " .. tostring(message))
    end
end

-- Visual separator
function BookScanner.Logger.separator()
    print(LOG_PREFIX .. " " .. string.rep("=", 50))
end

-- Section header
function BookScanner.Logger.section(title)
    print(LOG_PREFIX .. " === " .. tostring(title) .. " ===")
end

-- Enable debug mode
function BookScanner.Logger.enableDebug()
    BookScanner.Logger.currentLevel = BookScanner.Logger.Level.DEBUG
    BookScanner.Logger.log("Debug mode enabled")
end

-- Disable debug mode
function BookScanner.Logger.disableDebug()
    BookScanner.Logger.currentLevel = BookScanner.Logger.Level.INFO
    BookScanner.Logger.log("Debug mode disabled")
end