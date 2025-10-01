-- media/lua/client/BookScanner/BSReadScannedBook.lua
require("TimedActions/ISReadABook")

BookScanner = BookScanner or {}

BSReadScannedBook = ISReadABook:derive("BSReadScannedBook")

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
local error = BookScanner.Logger.error

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

	if self.isVirtual and self.character:getInventory():contains(self.item) then
		self.character:getInventory():Remove(self.item)
		debug("Virtual book removed (interrupted)")
	end

	self.character:setReading(false)
	self.item:setJobDelta(0.0)

	if SkillBook[self.item:getSkillTrained()] then
		self.character:playSound("CloseBook")
	else
		self.character:playSound("CloseMagazine")
	end

	ISBaseTimedAction.stop(self)
end

function BSReadScannedBook:perform()
	self.character:setReading(false)

	if not self.isVirtual and self.item:getContainer() then
		self.item:getContainer():setDrawDirty(true)
	end

	self.item:setJobDelta(0.0)

	-- Save final page count
	if self.item:getNumberOfPages() > 0 then
		if self.item:getAlreadyReadPages() >= self.item:getNumberOfPages() then
			-- Book finished, set to max to prevent re-reading
			self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getNumberOfPages())
		else
			self.character:setAlreadyReadPages(self.item:getFullType(), self.item:getAlreadyReadPages())
		end
	end

	if self.item:getTeachedRecipes() and not self.item:getTeachedRecipes():isEmpty() then
		self.character:getAlreadyReadBook():add(self.item:getFullType())
	end

	if not SkillBook[self.item:getSkillTrained()] then
		self.character:ReadLiterature(self.item)
	end

	if self.isVirtual and self.character:getInventory():contains(self.item) then
		self.character:getInventory():Remove(self.item)
		debug("Virtual book removed (completed)")
	end

	if SkillBook[self.item:getSkillTrained()] then
		self.character:playSound("CloseBook")
	else
		self.character:playSound("CloseMagazine")
	end

	-- Skip GTM override for virtual books
	if self.isVirtual then
		ISBaseTimedAction.perform(self)
	else
		ISReadABook.perform(self)
	end
end

function BSReadScannedBook:newFromScan(character, bookFullType)
	local virtualBook = InventoryItemFactory.CreateItem(bookFullType)

	if not virtualBook then
		error("Failed to create virtual book: " .. bookFullType)
		return nil
	end

	virtualBook:setName("[VIRTUAL] " .. virtualBook:getDisplayName())

	local pagesRead = character:getAlreadyReadPages(bookFullType)
	virtualBook:setAlreadyReadPages(pagesRead)

	character:getInventory():AddItem(virtualBook)

	local action = BSReadScannedBook:new(character, virtualBook, 0)
	action.isVirtual = true

	log("Virtual book created for reading: " .. virtualBook:getDisplayName())
	debug("Pages already read: " .. pagesRead .. "/" .. virtualBook:getNumberOfPages())

	return action
end

log("BSReadScannedBook.lua loaded")
