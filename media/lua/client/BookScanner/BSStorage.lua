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

	if not modData.scannedBooks then
		modData.scannedBooks = {}
		debug("Initialized scannedBooks table")
	end

	local fullType = bookInfo.fullType

	if modData.scannedBooks[fullType] then
		debug("Book already in library: " .. fullType)
		return false
	end

	-- Save ALL book data
	modData.scannedBooks[fullType] = {
		fullType = bookInfo.fullType,
		displayName = bookInfo.displayName,
		category = bookInfo.category,
		textureName = bookInfo.textureName,
		numberOfPages = bookInfo.numberOfPages,
		isMagazine = bookInfo.isMagazine, -- ← AJOUTER
		skills = bookInfo.skills,
		recipes = bookInfo.recipes,
		learnedRecipes = bookInfo.learnedRecipes, -- ← AJOUTER
		alreadyRead = bookInfo.alreadyRead,
		alreadyReadPages = bookInfo.alreadyReadPages,
		timestamp = os.time(),
	}

	debug("Book saved to ModData: " .. fullType)
	debug("  - Display name: " .. bookInfo.displayName)
	debug("  - Is Magazine: " .. tostring(bookInfo.isMagazine))
	debug("  - Texture: " .. tostring(bookInfo.textureName))
	debug("  - Category: " .. bookInfo.category)
	debug("  - Pages: " .. bookInfo.numberOfPages)
	debug("  - Skills: " .. #bookInfo.skills)
	debug("  - Recipes: " .. #bookInfo.recipes)
	if bookInfo.isMagazine then
		debug("  - Learned recipes: " .. #bookInfo.learnedRecipes)
	end

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

-- Synchronize book progress with player's actual reading progress
function BSStorage.syncBookProgress(pda, player)
	if not pda or not player then
		debug("syncBookProgress: missing pda or player")
		return
	end

	local modData = pda:getModData()

	if not modData.scannedBooks then
		debug("syncBookProgress: no scanned books")
		return
	end

	local updatedCount = 0

	for fullType, bookData in pairs(modData.scannedBooks) do
		if bookData.isMagazine then
			-- Pour les magazines : vérifier les recettes apprises
			debug("Checking magazine: " .. bookData.displayName)
			debug("  Total recipes: " .. #bookData.recipes)

			local learnedRecipes = {}

			for _, recipeName in ipairs(bookData.recipes) do
				-- Utiliser isRecipeKnown avec le nom de la recette (string)
				if player:isRecipeKnown(recipeName) then
					table.insert(learnedRecipes, recipeName)
					debug("  ✓ Recipe learned: " .. recipeName)
				else
					debug("  ✗ Recipe not learned: " .. recipeName)
				end
			end

			-- Vérifier si changement
			local oldCount = bookData.learnedRecipes and #bookData.learnedRecipes or 0
			local newCount = #learnedRecipes

			if oldCount ~= newCount then
				debug("Updating magazine progress: " .. bookData.displayName)
				debug("  Old: " .. oldCount .. "/" .. #bookData.recipes)
				debug("  New: " .. newCount .. "/" .. #bookData.recipes)

				bookData.learnedRecipes = learnedRecipes
				bookData.alreadyRead = (newCount == #bookData.recipes)

				updatedCount = updatedCount + 1
			end
		else
			-- Pour les livres normaux : vérifier les pages
			local currentPages = player:getAlreadyReadPages(fullType) or 0
			local totalPages = bookData.numberOfPages or 0

			if currentPages ~= bookData.alreadyReadPages then
				debug("Updating book progress: " .. bookData.displayName)
				debug("  Old: " .. bookData.alreadyReadPages .. "/" .. totalPages)
				debug("  New: " .. currentPages .. "/" .. totalPages)

				bookData.alreadyReadPages = currentPages
				bookData.alreadyRead = (currentPages >= totalPages)

				updatedCount = updatedCount + 1
			end
		end
	end

	if updatedCount > 0 then
		log("Synchronized " .. updatedCount .. " book(s)/magazine(s) progress")
	else
		debug("All books/magazines already up to date")
	end

	log("Library synchronized with player's reading progress")
end

log("BSStorage.lua loaded")
