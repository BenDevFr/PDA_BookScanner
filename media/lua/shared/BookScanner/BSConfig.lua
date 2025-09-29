-- media/lua/shared/BookScanner/BSConfig.lua
-- Global configuration for BookScanner mod

BookScanner = BookScanner or {}
BookScanner.Config = BookScanner.Config or {}

-- Mod version
BookScanner.Config.VERSION = "1.0.0"
BookScanner.Config.MOD_ID = "HephasStalkerPDA_BookScanner"

-- Items
BookScanner.Config.PDA_TYPE = "Hephas_StalkerPDA"

-- Book types to detect
BookScanner.Config.BOOK_TYPES = {
	"Book",
	"Magazine",
	"Newspaper",
}

-- Sounds
BookScanner.Config.SOUNDS = {
	SCAN_SUCCESS = "PDAInteraction",
	SCAN_ERROR = "PDANews",
}

-- Current language (auto-detected)
BookScanner.Config.currentLanguage = "EN"

-- Debug mode (modifiable via ModOptions)
BookScanner.Config.DEBUG_MODE = false

-- Auto-detect game language
function BookScanner.Config.detectLanguage()
	-- Vérifier que Translator existe
	if not Translator or not Translator.getLanguage then
		BookScanner.Config.currentLanguage = "EN"
		return
	end

	local gameLanguage = Translator.getLanguage()

	if gameLanguage == "FR" then
		BookScanner.Config.currentLanguage = "FR"
	elseif gameLanguage == "DE" then
		BookScanner.Config.currentLanguage = "DE"
	else
		BookScanner.Config.currentLanguage = "EN"
	end
end

-- Get translated text via getText()
function BookScanner.Config.getText(key, ...)
	local translatedText = getText(key)

	if select("#", ...) > 0 then
		return string.format(translatedText, ...)
	end

	return translatedText
end

-- Enable/disable debug mode
function BookScanner.Config.setDebugMode(enabled)
	BookScanner.Config.DEBUG_MODE = enabled

	if BookScanner.Logger then
		if enabled then
			BookScanner.Logger.enableDebug()
		else
			BookScanner.Logger.disableDebug()
		end
	end
end

-- Enable/disable verbose logs
function BookScanner.Config.setVerboseMode(enabled)
	if BookScanner.Logger then
		BookScanner.Logger.verboseMode = enabled
	end
end

-- Load Sandbox options (if available)
function BookScanner.Config.loadSandboxOptions()
	if SandboxVars and SandboxVars.BookScanner then
		-- Future options here
	end
end

-- Initialize on game start
Events.OnGameStart.Add(function()
	BookScanner.Config.detectLanguage()
	BookScanner.Config.loadSandboxOptions()
end)
