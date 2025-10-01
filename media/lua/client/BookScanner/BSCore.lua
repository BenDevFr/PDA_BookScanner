-- media/lua/client/BookScanner/BSCore.lua
-- Stalker PDA detection logic with ownership system

require("BookScanner/BSLogger")
require("BookScanner/BSConfig")
require("BookScanner/BSUtils")

BookScanner = BookScanner or {}

local BSCore = {}
BookScanner.Core = BSCore

-- Local logger imports
local log = BookScanner.Logger.log
local error = BookScanner.Logger.error
local debug = BookScanner.Logger.debug
local section = BookScanner.Logger.section

-- Local utils imports
local getPlayerInfo = BookScanner.Utils.getPlayerInfo
local formatPlayerLog = BookScanner.Utils.formatPlayerLog

-- Get stable owner identifier based on game mode
local function getStableOwner(player)
	if not player then
		error("getStableOwner() - player is nil")
		return nil
	end

	local gameMode = getWorld():getGameMode()

	if gameMode == "Multiplayer" then
		-- Multiplayer: Use Steam username (stable across characters)
		local owner = player:getUsername()
		debug("Owner (Multi): " .. owner)
		return owner
	else
		-- Solo: Use save ID (stable for this save game)
		local owner = getWorld():getWorld()
		debug("Owner (Solo): " .. owner)
		return owner
	end
end

-- Detect ALL PDAs in player inventory
function BSCore.detectAllPDAs(player)
	if not player then
		error("detectAllPDAs() - player is nil")
		return {}
	end

	local inventory = player:getInventory()
	if not inventory then
		error("Player inventory is nil")
		return {}
	end

	local pdas = {}
	local items = inventory:getItems()

	for i = 0, items:size() - 1 do
		local item = items:get(i)
		if item:getFullType() == "Base." .. BookScanner.Config.PDA_TYPE then
			table.insert(pdas, item)
		end
	end

	debug("Found " .. #pdas .. " PDA(s) in inventory")
	return pdas
end

-- Detect player's bound PDA (with auto-merge if multiple found)
function BSCore.detectPlayerPDA(player)
	if not player then
		error("detectPlayerPDA() - player is nil")
		return nil
	end

	local owner = getStableOwner(player)
	if not owner then
		error("Unable to determine owner identifier")
		return nil
	end

	local _, userName, playerID = getPlayerInfo(player)

	section("PDA Detection Start")
	log(formatPlayerLog(player, "Searching for player's PDA"))

	local pdas = BSCore.detectAllPDAs(player)

	if #pdas == 0 then
		log("No PDA found in inventory")
		section("PDA Detection End")
		return nil
	end

	-- Find all PDAs bound to this player
	local linkedPDAs = {}
	for _, pda in ipairs(pdas) do
		local modData = pda:getModData()
		if modData.owner == owner then
			table.insert(linkedPDAs, pda)
		end
	end

	if #linkedPDAs == 0 then
		log("No PDA bound to player")
		debug("Found " .. #pdas .. " unbound PDA(s)")
		section("PDA Detection End")
		return nil
	elseif #linkedPDAs == 1 then
		-- Single PDA found (normal case)
		local pda = linkedPDAs[1]
		local pdaName = pda:getName()
		local pdaModData = pda:getModData()
		log("Player's PDA detected - " .. pdaName)
		debug("PDA Owner: " .. pdaModData.owner)
		section("PDA Detection End")
		return pda
	else
		-- Multiple PDAs bound to same owner - MERGE LIBRARIES
		log("WARNING: Multiple bound PDAs detected (" .. #linkedPDAs .. "), merging libraries...")

		local mainPDA = linkedPDAs[1]
		local mainBooks = mainPDA:getModData().scannedBooks or {}
		local mergedCount = 0

		-- Merge all other PDAs into the first one
		for i = 2, #linkedPDAs do
			local otherPDA = linkedPDAs[i]
			local otherBooks = otherPDA:getModData().scannedBooks or {}

			-- Copy books that don't exist in main PDA
			for fullType, bookData in pairs(otherBooks) do
				if not mainBooks[fullType] then
					mainBooks[fullType] = bookData
					mergedCount = mergedCount + 1
					debug("Merged book: " .. fullType)
				end
			end

			-- Unbind the secondary PDA
			if BookScanner.Storage then
				BookScanner.Storage.unbindPDA(otherPDA)
				debug("Unbound secondary PDA")
			end
		end

		log("Libraries merged: " .. mergedCount .. " new book(s) added")
		log("Main PDA: " .. mainPDA:getName())
		section("PDA Detection End")
		return mainPDA
	end
end

-- Legacy function (alias for compatibility)
function BSCore.detectPDA(player)
	return BSCore.detectPlayerPDA(player)
end

-- Check if player has their bound PDA (fast version)
function BSCore.hasPDA(player)
	if not player then
		return false
	end

	local pda = BSCore.detectPlayerPDA(player)
	local hasPDA = pda ~= nil

	debug(formatPlayerLog(player, "Has bound PDA: " .. tostring(hasPDA)))

	return hasPDA
end

-- Export getStableOwner for use by other modules
BSCore.getStableOwner = getStableOwner

log("BSCore.lua loaded")
