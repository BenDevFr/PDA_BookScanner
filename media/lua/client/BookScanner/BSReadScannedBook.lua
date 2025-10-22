-- media/lua/client/BookScanner/BSReadScannedBook.lua
require("TimedActions/ISReadABook")

BookScanner = BookScanner or {}

BSReadScannedBook = ISReadABook:derive("BSReadScannedBook")

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
local error = BookScanner.Logger.error

-- Track virtual books for cleanup
BSReadScannedBook.activeVirtualBooks = {}

-- Override update to sync pages continuously
function BSReadScannedBook:update()
	ISReadABook.update(self)

	-- Sync pages read to player data during reading
	if self.item:getNumberOfPages() > 0 then
		local pagesRead = self.item:getAlreadyReadPages()
		self.character:setAlreadyReadPages(self.item:getFullType(), pagesRead)
	end
end

function BSReadScannedBook:stop()
	if self.item:getNumberOfPages() > 0 then
		self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getAlreadyReadPages())
	end

	self.character:setReading(false)
	self.item:setJobDelta(0.0)

	-- Sound
	if SkillBook[self.item:getSkillTrained()] then
		self.character:playSound("CloseBook")
	else
		self.character:playSound("CloseMagazine")
	end

	-- Cleanup virtual book BEFORE calling parent
	if self.isVirtual then
		self:cleanupVirtualBook()
	end

	ISBaseTimedAction.stop(self)
end

function BSReadScannedBook:perform()
	self.character:setReading(false)
	self.item:setJobDelta(0.0)

	-- Save final page count
	if self.item:getNumberOfPages() > 0 then
		if self.item:getAlreadyReadPages() >= self.item:getNumberOfPages() then
			self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getNumberOfPages())
		else
			self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getAlreadyReadPages())
		end
	end

	-- Learn recipes if magazine
	if self.item:getTeachedRecipes() and not self.item:getTeachedRecipes():isEmpty() then
		self.character:getAlreadyReadBook():add(self.item:getFullType())
	end

	-- Cleanup strategy: magazines need cleanup BEFORE ReadLiterature
	local needsCleanup = self.isVirtual
	local isMagazine = not SkillBook[self.item:getSkillTrained()]

	-- Test logging
	if needsCleanup and isMagazine then
		debug("Before ReadLiterature - item in inventory: " ..
		tostring(self.character:getInventory():contains(self.item)))
	end

	-- Cleanup BEFORE ReadLiterature for magazines
	if needsCleanup and isMagazine then
		self:cleanupVirtualBook()
		needsCleanup = false
	end

	-- Apply literature bonus (may remove item from inventory!)
	if isMagazine then
		self.character:ReadLiterature(self.item)
	end

	-- Test logging
	if self.isVirtual and isMagazine then
		debug("After ReadLiterature - item in inventory: " .. tostring(self.character:getInventory():contains(self.item)))
	end

	-- Sound
	if SkillBook[self.item:getSkillTrained()] then
		self.character:playSound("CloseBook")
	else
		self.character:playSound("CloseMagazine")
	end

	-- Cleanup for skill books (after, because no ReadLiterature call)
	if needsCleanup then
		self:cleanupVirtualBook()
	end

	ISBaseTimedAction.perform(self)
end

function BSReadScannedBook:cleanupVirtualBook()
	if not self.isVirtual or not self.item then
		debug("cleanupVirtualBook: not virtual or no item")
		return
	end

	local inventory = self.character:getInventory()

	debug("Attempting to cleanup virtual book: " .. self.item:getFullType())

	if inventory:contains(self.item) then
		inventory:Remove(self.item)
		log("Virtual book removed: " .. self.item:getFullType())
	else
		debug("Virtual book not found in inventory")
	end

	-- Remove from tracking
	local playerNum = self.character:getPlayerNum()
	BSReadScannedBook.activeVirtualBooks[playerNum] = nil
	debug("Removed from tracking")
end

function BSReadScannedBook:newFromScan(character, bookFullType)
	-- Check if already reading a virtual book
	local playerNum = character:getPlayerNum()
	if BSReadScannedBook.activeVirtualBooks[playerNum] then
		debug("Player already reading a virtual book")
		return nil
	end

	local virtualBook = InventoryItemFactory.CreateItem(bookFullType)

	if not virtualBook then
		error("Failed to create virtual book: " .. bookFullType)
		return nil
	end

	-- Configure virtual book
	virtualBook:setActualWeight(0)
	virtualBook:getModData().isVirtualBook = true
	virtualBook:setName("[PDA] " .. virtualBook:getDisplayName())

	-- Restore reading progress
	local pagesRead = character:getAlreadyReadPages(bookFullType)
	virtualBook:setAlreadyReadPages(pagesRead)

	-- Add to inventory
	character:getInventory():AddItem(virtualBook)

	-- Create reading action
	local action = BSReadScannedBook:new(character, virtualBook, 0)
	action.isVirtual = true

	-- Track this virtual book
	BSReadScannedBook.activeVirtualBooks[playerNum] = {
		book = virtualBook,
		action = action,
		timestamp = getTimestamp()
	}

	log("Virtual book created: " .. virtualBook:getDisplayName())
	debug("Pages: " .. pagesRead .. "/" .. virtualBook:getNumberOfPages())

	return action
end

-- Safety cleanup: Remove orphaned virtual books every 10 minutes
local function cleanupOrphanedVirtualBooks()
	for playerNum, data in pairs(BSReadScannedBook.activeVirtualBooks) do
		local player = getSpecificPlayer(playerNum)

		if not player or not player:isReading() then
			local inventory = player and player:getInventory()
			if inventory and data.book and inventory:contains(data.book) then
				inventory:Remove(data.book)
				debug("Orphaned virtual book cleaned up for player " .. playerNum)
			end
			BSReadScannedBook.activeVirtualBooks[playerNum] = nil
		end
	end
end

Events.EveryTenMinutes.Add(cleanupOrphanedVirtualBooks)

log("BSReadScannedBook.lua loaded")
