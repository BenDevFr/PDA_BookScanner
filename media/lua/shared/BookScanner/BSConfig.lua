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

-- Auto-detect game language
function BookScanner.Config.detectLanguage()
	-- Method 1: Try Core language (most reliable at startup)
	if Core and Core.getInstance then
		local coreInstance = Core.getInstance()
		if coreInstance and coreInstance.getOptionLanguageName then
			local lang = coreInstance:getOptionLanguageName()
			if lang then
				if lang == "FR" or lang == "Francais" then
					BookScanner.Config.currentLanguage = "FR"
					return
				elseif lang == "DE" or lang == "Deutsch" then
					BookScanner.Config.currentLanguage = "DE"
					return
				else
					BookScanner.Config.currentLanguage = "EN"
					return
				end
			end
		end
	end

	-- Method 2: Try Translator (may not be available at startup)
	if Translator and Translator.getLanguage then
		local languageObject = Translator.getLanguage()
		if languageObject and languageObject.getName then
			local gameLanguage = languageObject:getName()
			if gameLanguage == "FR" then
				BookScanner.Config.currentLanguage = "FR"
				return
			elseif gameLanguage == "DE" then
				BookScanner.Config.currentLanguage = "DE"
				return
			end
		end
	end

	-- Fallback: English
	BookScanner.Config.currentLanguage = "EN"
end

-- Get translated text via getText()
function BookScanner.Config.getText(key, ...)
	local translatedText = getText(key)

	-- Format with arguments if provided
	if select("#", ...) > 0 then
		return string.format(translatedText, ...)
	end

	return translatedText
end

-- Load Sandbox options (if available)
function BookScanner.Config.loadSandboxOptions()
	if SandboxVars and SandboxVars.BookScanner then
		-- Future options here (e.g., destroy book on scan, storage limit, etc.)
	end
end

-- Initialize on game start
Events.OnGameStart.Add(function()
	BookScanner.Config.detectLanguage()
	BookScanner.Config.loadSandboxOptions()
end)
