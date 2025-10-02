-- media/lua/client/BookScanner/BSStorage.lua
-- ModData storage for scanned books with ownership system

require("BookScanner/BSLogger")
require("BookScanner/BSCore")

BookScanner = BookScanner or {}

local BSStorage = {}
BookScanner.Storage = BSStorage

-- Local imports
local log = BookScanner.Logger.log
local error = BookScanner.Logger.error
local debug = BookScanner.Logger.debug

-- Bind PDA to player
function BSStorage.bindPDAToPlayer(pda, player)
	if not pda or not player then
		error("bindPDAToPlayer() - Missing PDA or player")
		return false
	end

	local owner = BookScanner.Core.getStableOwner(player)
	if not owner then
		error("Unable to determine owner identifier")
		return false
	end

	local modData = pda:getModData()

	-- Check if PDA is already bound
	if modData.owner then
		debug("PDA already bound to: " .. modData.owner)
		return false
	end

	-- Bind PDA to player
	modData.owner = owner
	modData.boundTimestamp = os.time()

	-- Initialize scannedBooks table
	if not modData.scannedBooks then
		modData.scannedBooks = {}
	end

	-- Update PDA name to show ownership
	local displayName
	local gameMode = getWorld():getGameMode()

	if gameMode == "Multiplayer" then
		-- Multiplayer: Use Steam username
		displayName = player:getUsername()
	else
		-- Solo: Use character's full name (forename + surname)
		local forename = player:getDescriptor():getForename()
		local surname = player:getDescriptor():getSurname()
		displayName = forename .. " " .. surname
	end

	local pdaName = BookScanner.Config.getText("UI_BookScanner_PDAName", displayName)
	pda:setName(pdaName)

	log("PDA bound to player: " .. owner)
	debug("PDA name set to: " .. pdaName)

	return true
end

-- Unbind PDA from player
function BSStorage.unbindPDA(pda)
	if not pda then
		error("unbindPDA() - PDA is nil")
		return false
	end

	local modData = pda:getModData()

	if not modData.owner then
		debug("PDA is not bound")
		return false
	end

	local previousOwner = modData.owner

	-- Clear ownership
	modData.owner = nil
	modData.boundTimestamp = nil

	-- Reset PDA name to original item name
	local itemScript = getScriptManager():getItem(pda:getFullType())
	if itemScript then
		local originalName = itemScript:getDisplayName()
		pda:setName(originalName)
		log("PDA unbound from: " .. previousOwner)
		debug("PDA name reset to: " .. originalName)
	else
		error("Could not retrieve original item name for: " .. pda:getFullType())
		pda:setName("PDA") -- Fallback
		log("PDA unbound from: " .. previousOwner)
		debug("PDA name reset to fallback: PDA")
	end

	return true
end

-- Save scanned book to PDA ModData
function BSStorage.saveScannedBook(pda, bookInfo)
	if not pda or not bookInfo then
		error("saveScannedBook() - Missing PDA or bookInfo")
		return false
	end

	local modData = pda:getModData()

	-- Initialize scannedBooks if not exists
	if not modData.scannedBooks then
		modData.scannedBooks = {}
		debug("Initialized scannedBooks table")
	end

	local fullType = bookInfo.fullType

	-- Check if already scanned
	if modData.scannedBooks[fullType] then
		debug("Book already in library: " .. fullType)
		return false
	end

	-- Save book data
	modData.scannedBooks[fullType] = {
		fullType = bookInfo.fullType,
		category = bookInfo.category,
		timestamp = os.time(),
	}

	debug("Book saved to ModData: " .. fullType)
	debug("Category: " .. bookInfo.category)

	return true
end

-- Check if book is already scanned
function BSStorage.isBookScanned(pda, fullType)
	if not pda or not fullType then
		error("isBookScanned() - Missing PDA or fullType")
		return false
	end

	local modData = pda:getModData()

	if not modData.scannedBooks then
		return false
	end

	local isScanned = modData.scannedBooks[fullType] ~= nil
	debug("Book scan check: " .. fullType .. " = " .. tostring(isScanned))

	return isScanned
end

-- Get all scanned books from PDA
function BSStorage.getScannedBooks(pda)
	if not pda then
		error("getScannedBooks() - PDA is nil")
		return {}
	end

	local modData = pda:getModData()

	if not modData.scannedBooks then
		debug("No scanned books in PDA")
		return {}
	end

	return modData.scannedBooks
end

-- Get count of scanned books
function BSStorage.getScannedBooksCount(pda)
	local books = BSStorage.getScannedBooks(pda)
	local count = 0

	for _ in pairs(books) do
		count = count + 1
	end

	return count
end

-- Clear all scanned books (for debugging)
function BSStorage.clearLibrary(pda)
	if not pda then
		error("clearLibrary() - PDA is nil")
		return false
	end

	local modData = pda:getModData()

	if not modData.scannedBooks then
		debug("No library to clear")
		return false
	end

	local count = BSStorage.getScannedBooksCount(pda)

	modData.scannedBooks = {}

	log("Library cleared: " .. count .. " book(s) removed")

	return true
end

log("BSStorage.lua loaded")
