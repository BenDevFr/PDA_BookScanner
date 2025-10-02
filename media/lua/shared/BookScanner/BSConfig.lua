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

-- Get translated text using Project Zomboid's built-in system
function BookScanner.Config.getText(key, ...)
	local text = getText(key) or key

	-- Replace placeholders with arguments
	if select("#", ...) > 0 then
		local args = { ... }
		for i, arg in ipairs(args) do
			text = text:gsub("%%" .. i, tostring(arg))
		end
	end

	return text
end

-- Load Sandbox options (if available)
function BookScanner.Config.loadSandboxOptions()
	if SandboxVars and SandboxVars.BookScanner then
		-- Future options here
	end
end

-- Initialize on game start
Events.OnGameStart.Add(BookScanner.Config.loadSandboxOptions)
