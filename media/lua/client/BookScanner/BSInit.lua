-- media/lua/client/BookScanner/BSInit.lua
-- Main entry point for BookScanner mod
-- Loads all modules in correct order

-- Load Config and Logger first
require("BookScanner/BSConfig")
require("BookScanner/BSLogger")

local log = BookScanner.Logger.log
local separator = BookScanner.Logger.separator

separator()
log("Initializing BookScanner mod")
separator()

-- Load other shared modules
log("Loading shared modules...")
require("BookScanner/BSUtils")

-- Load client modules
log("Loading client modules...")
require("BookScanner/BSCore")
require("BookScanner/BSBooks")
require("BookScanner/BSModOptions")
require("BookScanner/BSContext")

-- WARNING Load tests (dev mode only)
-- UNCOMMENT THE LINES BELOW FOR DEVELOPMENT/TESTING
if BookScanner.Config.DEBUG_MODE then
	log("Loading test modules (dev mode)...")
	require("BookScanner/BSTests")
end

separator()
log("All modules loaded successfully")
log("Version: " .. BookScanner.Config.VERSION)
log("Use ModOptions to configure the mod")
separator()
