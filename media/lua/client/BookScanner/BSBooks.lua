-- media/lua/client/BookScanner/BSBooks.lua
-- Book detection and information extraction

require("BookScanner/BSLogger")

BookScanner = BookScanner or {}

local BSBooks = {}
BookScanner.Books = BSBooks

-- Local imports
local log = BookScanner.Logger.log
local error = BookScanner.Logger.error
local debug = BookScanner.Logger.debug

-- Check if an item is a scannable book
function BSBooks.isBookScannable(item)
	if not item then
		error("isBookScannable() - item is nil")
		return false
	end

	debug("Checking scannability: " .. item:getDisplayName() .. " (" .. item:getType() .. ")")

	-- Check if item is Literature category
	if item:getCategory() ~= "Literature" then
		debug("  ✗ NOT Literature category")
		return false
	end

	-- Check if it's a skill book
	local skillTrained = item:getSkillTrained()
	if skillTrained and skillTrained ~= "" then
		debug("  ✓ USEFUL skill book: " .. skillTrained)
		return true
	end

	-- Check if it has recipes
	local recipes = item:getTeachedRecipes()
	if recipes and not recipes:isEmpty() then
		debug("  ✓ USEFUL book with " .. recipes:size() .. " recipe(s)")
		return true
	end

	-- Useless book (no skills or recipes)
	debug("  ✗ USELESS book (no recipes or skills)")
	return false
end

-- Extract detailed information from a book
function BSBooks.extractBookInfo(item)
	if not item then
		error("extractBookInfo() - item is nil")
		return nil
	end

	debug("Extracting info for: " .. item:getDisplayName())

	local bookInfo = {
		fullType = item:getFullType(),
		displayName = item:getDisplayName(),
		type = item:getType(),
		category = item:getCategory(),
		pages = item:getNumberOfPages() or 0,
		skillTrained = nil,
		skillFrom = -1,
		skillTo = -1,
		recipes = {},
	}

	-- Extract recipes if available
	local recipes = item:getTeachedRecipes()
	if recipes and not recipes:isEmpty() then
		debug("Extracting recipes...")
		for i = 0, recipes:size() - 1 do
			local recipe = recipes:get(i)
			table.insert(bookInfo.recipes, recipe)
		end
	end

	-- Extract skill training info
	local skillTrained = item:getSkillTrained()
	if skillTrained and skillTrained ~= "" then
		debug("Extracting skills...")
		bookInfo.skillTrained = skillTrained

		local lvlMin = item:getLvlSkillTrained()
		local lvlMax = item:getMaxLevelTrained()

		bookInfo.skillFrom = lvlMin or -1
		bookInfo.skillTo = lvlMax or -1
	end

	-- Debug output
	debug("Info extracted: " .. bookInfo.displayName)
	debug("  - Type: " .. bookInfo.type)
	debug("  - Pages: " .. bookInfo.pages)
	debug("  - Recipes: " .. #bookInfo.recipes)
	debug(
		"  - Skill: "
			.. (bookInfo.skillTrained or "")
			.. " ("
			.. bookInfo.skillFrom
			.. " -> "
			.. bookInfo.skillTo
			.. ")"
	)

	return bookInfo
end

-- Detect all scannable books in player inventory
function BSBooks.detectScannableBooks(player)
	if not player then
		error("detectScannableBooks() - player is nil")
		return {}
	end

	local inventory = player:getInventory()
	if not inventory then
		error("Player inventory is nil")
		return {}
	end

	local scannableBooks = {}
	local items = inventory:getItems()

	log("Scanning " .. items:size() .. " items")

	for i = 0, items:size() - 1 do
		local item = items:get(i)
		debug("Item " .. i .. ": " .. item:getDisplayName() .. " (" .. item:getType() .. ")")

		if BSBooks.isBookScannable(item) then
			local bookInfo = BSBooks.extractBookInfo(item)
			if bookInfo then
				table.insert(scannableBooks, bookInfo)
				log(" ✓ Book added: " .. bookInfo.displayName)
			end
		end
	end

	return scannableBooks
end

log("BSBooks.lua loaded")
