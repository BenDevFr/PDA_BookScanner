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

	-- Extraire le nom de la texture
	local textureName = nil
	local texture = item:getTex()
	if texture then
		textureName = texture:getName()
		debug("  - Texture name: " .. tostring(textureName))
	else
		debug("  - getTex() returned nil")
	end

	local numberOfPages = item:getNumberOfPages() or 0

	-- Détecter si c'est un magazine (numberOfPages = -1)
	local isMagazine = (numberOfPages == -1)

	local info = {
		fullType = item:getFullType(),
		displayName = item:getDisplayName(),
		category = item:getCategory(),
		textureName = textureName,
		numberOfPages = numberOfPages,
		isMagazine = isMagazine, -- ← AJOUTER
		alreadyRead = false,
		alreadyReadPages = 0,
		skills = {},
		recipes = {},
		learnedRecipes = {}, -- ← AJOUTER : recettes apprises
	}

	-- Get read progress from player data (if player provided)
	if player and not isMagazine then
		local fullType = item:getFullType()
		info.alreadyReadPages = player:getAlreadyReadPages(fullType) or 0

		if info.alreadyReadPages >= info.numberOfPages then
			info.alreadyRead = true
		end

		debug("Read progress from player: " .. info.alreadyReadPages .. "/" .. info.numberOfPages)
	end

	-- Extract recipes
	debug("Extracting recipes.....")
	local recipeMap = item:getTeachedRecipes()
	if recipeMap and not recipeMap:isEmpty() then
		for i = 0, recipeMap:size() - 1 do
			local recipeName = recipeMap:get(i)
			local recipeStr = tostring(recipeName)
			table.insert(info.recipes, recipeStr)

			-- Pour les magazines, vérifier si la recette est apprise
			if isMagazine and player then
				local recipe = getScriptManager():getRecipe(recipeStr)
				if recipe then
					local isKnown = player:isRecipeKnown(recipe)
					if isKnown then
						table.insert(info.learnedRecipes, recipeStr)
					end
					debug("  Recipe " .. recipeStr .. " known: " .. tostring(isKnown))
				end
			end
		end
	end

	-- Pour les magazines, considérer comme "lu" si toutes les recettes sont apprises
	if isMagazine and #info.recipes > 0 then
		info.alreadyRead = (#info.learnedRecipes == #info.recipes)
		debug("Magazine progress: " .. #info.learnedRecipes .. "/" .. #info.recipes .. " recipes learned")
	end

	-- Extract skills
	debug("Extracting skills.....")
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

		local skillName = tostring(skillTrained)

		-- Si skillName est vide, ne pas l'ajouter
		if skillName ~= "" then
			table.insert(info.skills, {
				name = skillName,
				lvlMin = lvlMin,
				lvlMax = lvlMax,
			})
		end
	end

	debug("Info extracted: " .. item:getDisplayName())
	debug("  - Type: " .. info.fullType)
	debug("  - Is Magazine: " .. tostring(info.isMagazine))
	debug("  - Texture: " .. tostring(info.textureName))
	debug("  - Pages: " .. info.numberOfPages)
	debug("  - Already read: " .. tostring(info.alreadyRead))
	if not isMagazine then
		debug("  - Pages read: " .. info.alreadyReadPages)
	end
	debug("  - Recipes: " .. #info.recipes)
	if isMagazine then
		debug("  - Learned recipes: " .. #info.learnedRecipes)
	end
	for _, skill in ipairs(info.skills) do
		debug("  - Skill: " .. skill.name .. " (" .. skill.lvlMin .. " -> " .. skill.lvlMax .. ")")
	end

	return info
end

log("BSBooks.lua loaded")

return BSBooks
