-- media/lua/client/BookScanner/BSBooks.lua

require("BookScanner/BSLogger")
require("BookScanner/BSExclusions")

BookScanner = BookScanner or {}

local BSBooks = {}
BookScanner.Books = BSBooks

-- Local imports
local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug

--- Check if a book is scannable
-- @param item InventoryItem The item to check
-- @return boolean true if the book can be scanned
function BSBooks.isBookScannable(item)
	if not item then
		return false
	end

	debug("Checking scannability: " .. item:getDisplayName() .. " (" .. item:getType() .. ")")

	-- Early filter: Must be Literature category
	if item:getCategory() ~= "Literature" then
		debug("   NOT Literature category")
		return false
	end

	-- Check exclusions (GTM, etc.)
	if BookScanner.Exclusions.isExcluded(item) then
		debug("   EXCLUDED by mod filter")
		return false
	end

	-- Check if it teaches a skill
	local skillTrained = item:getSkillTrained()
	if skillTrained then
		debug("   USEFUL skill book: " .. tostring(skillTrained))
		return true
	end

	-- Check if it contains recipes
	local recipes = item:getTeachedRecipes()
	if recipes and recipes:size() > 0 then
		debug("   Contains recipes")
		return true
	end

	debug("   NOT a skill/recipe book")
	return false
end

--- Detect all scannable books in player inventory and containers
-- @param player IsoPlayer The player
-- @return table Array of scannable book items
function BSBooks.detectScannableBooks(player)
	if not player then
		return {}
	end

	local scannableBooks = {}
	local inventory = player:getInventory()
	local items = inventory:getItems()

	log("Scanning " .. items:size() .. " items")

	for i = 0, items:size() - 1 do
		local item = items:get(i)
		debug("Item " .. i .. ": " .. item:getDisplayName() .. " (" .. item:getType() .. ")")

		if BSBooks.isBookScannable(item) then
			local bookInfo = BSBooks.extractBookInfo(item, player)
			table.insert(scannableBooks, bookInfo)
			log("  Book added: " .. item:getDisplayName())
		end
	end

	return scannableBooks
end

--- Extract complete information from a book
-- @param item InventoryItem The book item
-- @param player IsoPlayer Optional - to get read progress
-- @return table Book information
function BSBooks.extractBookInfo(item, player)
	if not item then
		debug("extractBookInfo: item is nil")
		return nil
	end

	debug("Extracting info for: " .. item:getDisplayName())

	local info = {
		fullType = item:getFullType(),
		displayName = item:getDisplayName(),
		category = item:getCategory(),
		numberOfPages = item:getNumberOfPages() or 0,
		alreadyRead = false,
		alreadyReadPages = 0,
		skills = {},
		recipes = {},
	}

	-- Get read progress from player data (if player provided)
	if player then
		local fullType = item:getFullType()
		info.alreadyReadPages = player:getAlreadyReadPages(fullType) or 0

		-- Check if fully read
		if info.alreadyReadPages >= info.numberOfPages then
			info.alreadyRead = true
		end

		debug("Read progress from player: " .. info.alreadyReadPages .. "/" .. info.numberOfPages)
	end

	-- Extract recipes
	debug("Extracting recipes....")
	local recipes = item:getTeachedRecipes()
	if recipes then
		for i = 0, recipes:size() - 1 do
			table.insert(info.recipes, tostring(recipes:get(i)))
		end
	end

	-- Extract skills
	debug("Extracting skills....")
	local skillTrained = item:getSkillTrained()
	if skillTrained then
		local lvlMin = 0
		local lvlMax = 0

		if item.getLvlSkillTrained then
			lvlMin = item:getLvlSkillTrained()
		elseif item.getLvlMin then
			lvlMin = item:getLvlMin()
		end

		if item.getMaxLevelTrained then
			lvlMax = item:getMaxLevelTrained()
		elseif item.getLvlMax then
			lvlMax = item:getLvlMax()
		end

		table.insert(info.skills, {
			name = tostring(skillTrained),
			lvlMin = lvlMin,
			lvlMax = lvlMax,
		})
	end

	-- Debug log
	debug("Info extracted: " .. info.displayName)
	debug("  - Type: " .. info.fullType)
	debug("  - Pages: " .. info.numberOfPages)
	debug("  - Already read: " .. tostring(info.alreadyRead))
	debug("  - Pages read: " .. info.alreadyReadPages)
	debug("  - Recipes: " .. #info.recipes)
	if #info.skills > 0 then
		local skill = info.skills[1]
		debug("  - Skill: " .. skill.name .. " (" .. skill.lvlMin .. " -> " .. skill.lvlMax .. ")")
	end

	return info
end

log("BSBooks.lua loaded")

return BSBooks
