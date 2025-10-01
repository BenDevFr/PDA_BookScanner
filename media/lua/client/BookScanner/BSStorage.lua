-- media/lua/client/BookScanner/BSStorage.lua
-- ModData storage management for scanned books

require("BookScanner/BSLogger")
require("BookScanner/BSConfig")


BookScanner = BookScanner or {}

local BSStorage = {}
BookScanner.Storage = BSStorage

-- Local imports
local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
local verbose = BookScanner.Logger.verbose
local error = BookScanner.Logger.error

-- Get PDA's scanned books data
function BSStorage.getScannedBooks(pda)
	if not pda then
		error("getScannedBooks() - pda is nil")
		return nil
	end

	local modData = pda:getModData()

	-- Initialize if doesn't exist
	if not modData.scannedBooks then
		verbose("Initializing scannedBooks in PDA ModData")
		modData.scannedBooks = {}
	end

	return modData.scannedBooks
end

-- Check if book already scanned
function BSStorage.isBookScanned(pda, bookFullType)
	if not pda or not bookFullType then
		error("isBookScanned() - invalid parameters")
		return false
	end

	local scannedBooks = BSStorage.getScannedBooks(pda)
	local isScanned = scannedBooks[bookFullType] ~= nil

	debug("Check " .. bookFullType .. " -> " .. tostring(isScanned))

	return isScanned
end

-- Save scanned book to PDA
function BSStorage.saveScannedBook(pda, bookInfo)
	if not pda then
		error("saveScannedBook() - pda is nil")
		return false
	end

	if not bookInfo or not bookInfo.fullType then
		error("saveScannedBook() - invalid bookInfo")
		return false
	end

	verbose("Saving book: " .. bookInfo.fullType)

	local scannedBooks = BSStorage.getScannedBooks(pda)

	-- Check if already exists
	if scannedBooks[bookInfo.fullType] then
		debug("Book already scanned, skipping save")
		return false
	end

	-- Determine category for UI filtering
	local category = "recipe"
	if bookInfo.skillTrained and bookInfo.skillTrained ~= "" then
		category = "skill"
	end

	-- Minimal storage: only metadata
	scannedBooks[bookInfo.fullType] = {
		fullType = bookInfo.fullType,
		scannedDate = os.time(),
		category = category,
	}

	log("Book saved: " .. bookInfo.name .. " (" .. category .. ")")
	debug("Total scanned books: " .. BookScanner.Utils.tableCount(scannedBooks))

	return true
end

-- Get specific scanned book metadata
function BSStorage.getScannedBook(pda, bookFullType)
	if not pda or not bookFullType then
		error("getScannedBook() - invalid parameters")
		return nil
	end

	local scannedBooks = BSStorage.getScannedBooks(pda)
	return scannedBooks[bookFullType]
end

-- Get count of scanned books
function BSStorage.getScannedBooksCount(pda)
	if not pda then
		error("getScannedBooksCount() - pda is nil")
		return 0
	end

	local scannedBooks = BSStorage.getScannedBooks(pda)
	return BookScanner.Utils.tableCount(scannedBooks)
end

-- Delete scanned book (for testing/admin commands)
function BSStorage.deleteScannedBook(pda, bookFullType)
	if not pda or not bookFullType then
		error("deleteScannedBook() - invalid parameters")
		return false
	end

	local scannedBooks = BSStorage.getScannedBooks(pda)

	if scannedBooks[bookFullType] then
		scannedBooks[bookFullType] = nil
		log("Book deleted from library: " .. bookFullType)
		return true
	end

	debug("Book not found for deletion: " .. bookFullType)
	return false
end

-- Clear all scanned books (for testing)
function BSStorage.clearAllBooks(pda)
	if not pda then
		error("clearAllBooks() - pda is nil")
		return false
	end

	local modData = pda:getModData()
	modData.scannedBooks = {}
	log("All scanned books cleared")
	return true
end

-- Bind PDA to player (set ownership)
function BSStorage.bindPDAToPlayer(pda, player)
	if not pda or not player then
		error("bindPDAToPlayer() - invalid parameters")
		return false
	end

	local owner = BookScanner.Core.getStableOwner(player)
	if not owner then
		error("Unable to determine owner identifier")
		return false
	end

	local modData = pda:getModData()

	-- Check if already bound
	if modData.owner then
		debug("PDA already bound to: " .. modData.owner)
		return false
	end

	-- Check if player already has a bound PDA
	local existingPDA = BookScanner.Core.detectPlayerPDA(player)
	if existingPDA and existingPDA ~= pda then
		log("Player already has a bound PDA, refusing to bind another")
		return false
	end

	-- Set ownership
	modData.owner = owner

	-- Rename PDA with player's username (visible name)
	local displayName = player:getUsername()
	local newName = "PDA de " .. displayName
	pda:setName(newName)

	log("PDA bound to player")
	debug("Owner ID: " .. owner)
	debug("PDA renamed to: " .. newName)

	return true
end

-- Unbind PDA from player (reset ownership)
function BSStorage.unbindPDA(pda)
	if not pda then
		error("unbindPDA() - pda is nil")
		return false
	end

	local modData = pda:getModData()

	if not modData.owner then
		debug("PDA not bound to anyone")
		return false
	end

	local oldOwner = modData.owner
	modData.owner = nil
	pda:setName("PDA")

	log("PDA unbound from: " .. oldOwner)

	return true
end

log("BSStorage.lua loaded")
