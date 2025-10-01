-- media/lua/client/BookScanner/BSInit.lua
-- Main entry point for BookScanner mod
-- Loads all modules in correct order

-- Load Config and Logger first (order matters!)
require("BookScanner/BSConfig")
require("BookScanner/BSLogger")

local log = BookScanner.Logger.log
local separator = BookScanner.Logger.separator

separator()
log("Initializing BookScanner mod v" .. BookScanner.Config.VERSION)
separator()

-- Load shared utilities
log("Loading shared modules...")
require("BookScanner/BSUtils")

-- Load client modules
log("Loading client modules...")
require("BookScanner/BSCore")
require("BookScanner/BSBooks")
require("BookScanner/BSStorage")
require("BookScanner/BSContext")
require("BookScanner/BSReadScannedBook")

-- Load tests only in debug mode
if BookScanner.Logger.debugMode then
	log("Debug mode active - Loading test modules...")
	require("BookScanner/BSTests")
else
	log("Normal mode - Test modules disabled")
end

separator()
log("BookScanner initialization complete!")
log("Language: " .. BookScanner.Config.currentLanguage)
separator()
