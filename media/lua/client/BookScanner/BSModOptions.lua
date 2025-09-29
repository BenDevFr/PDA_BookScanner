-- media/lua/client/BookScanner/BSModOptions.lua
-- ModOptions management (changeable in-game)

require("BookScanner/BSConfig")
require("BookScanner/BSLogger")

local log = BookScanner.Logger.log

BookScanner = BookScanner or {}
BookScanner.ModOptions = BookScanner.ModOptions or {}

-- Available log levels
BookScanner.ModOptions.LogLevel = {
	NORMAL = 1,
	DEBUG = 2,
	VERBOSE = 3,
}

-- Current level
BookScanner.ModOptions.currentLogLevel = BookScanner.ModOptions.LogLevel.NORMAL
BookScanner.ModOptions.showScanNotifications = true

-- Initialize ModOptions system
function BookScanner.ModOptions.init()
	if not ModOptions or not ModOptions.getInstance then
		BookScanner.Logger.warn("ModOptions not installed - Advanced options unavailable")
		return
	end

	BookScanner.Logger.log("Initializing ModOptions")

	-- Callback when options change
	local function onModOptionsApply(optionValues)
		local settings = optionValues.settings.options

		-- Log level
		if settings.logLevel ~= nil then
			BookScanner.ModOptions.currentLogLevel = settings.logLevel
			BookScanner.ModOptions.applyLogLevel(settings.logLevel)
		end

		-- Scan notifications
		if settings.showScanNotifications ~= nil then
			BookScanner.ModOptions.showScanNotifications = settings.showScanNotifications
			BookScanner.Logger.log("Scan notifications: " .. tostring(settings.showScanNotifications))
		end
	end

	-- ModOptions configuration
	local SETTINGS = {
		options_data = {
			logLevel = {
				name = "UI_BookScanner_LogLevel",
				tooltip = "UI_BookScanner_LogLevel_Tooltip",
				type = "enum",
				default = 1,
				values = { 1, 2, 3 },
				valueNames = {
					"UI_BookScanner_LogLevel_Normal",
					"UI_BookScanner_LogLevel_Debug",
					"UI_BookScanner_LogLevel_Verbose",
				},
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
			showScanNotifications = {
				name = "UI_BookScanner_ShowNotifications",
				tooltip = "UI_BookScanner_ShowNotifications_Tooltip",
				default = true,
				OnApplyMainMenu = onModOptionsApply,
				OnApplyInGame = onModOptionsApply,
			},
		},
		mod_id = "BookScanner",
		mod_fullname = "Stalker PDA Book Scanner",
	}

	-- Create ModOptions instance
	local optionsInstance = ModOptions:getInstance(SETTINGS)
	ModOptions:loadFile()

	-- Custom handler for log level
	local optionLogLevel = optionsInstance:getData("logLevel")
	if optionLogLevel then
		function optionLogLevel:OnApply(newValue)
			BookScanner.ModOptions.currentLogLevel = newValue
			BookScanner.ModOptions.applyLogLevel(newValue)
		end
	end

	-- Apply options on load
	Events.OnPreMapLoad.Add(function()
		onModOptionsApply({ settings = SETTINGS })
	end)

	BookScanner.Logger.log("ModOptions initialized successfully")
end

-- Apply selected log level
function BookScanner.ModOptions.applyLogLevel(level)
	if level == BookScanner.ModOptions.LogLevel.NORMAL then
		BookScanner.Logger.disableDebug()
		BookScanner.Logger.verboseMode = false
		BookScanner.Logger.log("Log level: Normal")
	elseif level == BookScanner.ModOptions.LogLevel.DEBUG then
		BookScanner.Logger.enableDebug()
		BookScanner.Logger.verboseMode = false
		BookScanner.Logger.log("Log level: Debug")
	elseif level == BookScanner.ModOptions.LogLevel.VERBOSE then
		BookScanner.Logger.enableDebug()
		BookScanner.Logger.verboseMode = true
		BookScanner.Logger.log("Log level: Verbose")
	end
end

-- Load options on game start
Events.OnGameStart.Add(function()
	BookScanner.ModOptions.init()
end)

BookScanner.Logger.log("BSModOptions.lua loaded")
