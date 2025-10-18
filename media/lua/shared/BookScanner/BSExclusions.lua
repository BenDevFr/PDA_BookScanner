-- media/lua/shared/BookScanner/BSExclusions.lua

require("BookScanner/BSLogger")

BookScanner = BookScanner or {}
BookScanner.Exclusions = {}

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug

--- List of excluded book prefixes (for mods where ALL items should be excluded)
-- Format: ["Prefix"] = "Reason"
local EXCLUDED_PREFIXES = {
	--[[
	Example: Books from the mod 'More Books!'
	["Books"] = "Alternative books mod (More Books!)",
	--]]

	-- Add other mod prefixes here
}

--- List of specific excluded books with their reasons
-- Format: ["FullType"] = "Reason displayed in tooltip"
local EXCLUDED_BOOKS = {

	-- ===== Gyde's Trait Magazines =====
	-- Magazines that grant permanent traits
	["Base.NutritionistMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.OutdoorsmanMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.HandyMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.AxeManMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.BurglarMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.SpeedDemonMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.OrganizedMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.FastLearnerMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.FastReaderMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.GracefulMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.DextrousMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.InconspicuousMag"] = "Trait magazine (Gyde's Trait Magazines)",
	["Base.KeenHearingMag"] = "Trait magazine (Gyde's Trait Magazines)",

	-- ===== Future Examples (Commented) =====
	-- ["Base.BookUnlimitedCarryWeight"] = "Cheat item (excluded for balance)",
	-- ["ModName.SpecialBook"] = "Special mechanics incompatible with scanning",
}

--- Check if a book is excluded from scanning
-- @param item InventoryItem|string The item or its fullType
-- @return boolean true if the book is excluded
function BookScanner.Exclusions.isExcluded(item)
	local fullType

	-- Support both item objects and fullType strings
	if type(item) == "string" then
		fullType = item
	elseif item and item.getFullType then
		fullType = item:getFullType()
	else
		return true -- Invalid input, exclude by default
	end

	-- 1. Check exact match in EXCLUDED_BOOKS
	if EXCLUDED_BOOKS[fullType] then
		return true
	end

	-- 2. Check prefixes (after module name like "Base.")
	local module, afterDot = fullType:match("^([^%.]+)%.(.+)$")
	if afterDot then
		for prefix, _ in pairs(EXCLUDED_PREFIXES) do
			if luautils.stringStarts(afterDot, prefix) then
				return true
			end
		end
	end

	return false
end

--- Get the exclusion reason for a book
-- @param item InventoryItem|string The item or its fullType
-- @return string|nil The exclusion reason, or nil if not excluded
function BookScanner.Exclusions.getExclusionReason(item)
	local fullType

	if type(item) == "string" then
		fullType = item
	elseif item and item.getFullType then
		fullType = item:getFullType()
	else
		return nil
	end

	-- Check exact match first
	if EXCLUDED_BOOKS[fullType] then
		return EXCLUDED_BOOKS[fullType]
	end

	-- Check prefixes
	local module, afterDot = fullType:match("^([^%.]+)%.(.+)$")
	if afterDot then
		for prefix, reason in pairs(EXCLUDED_PREFIXES) do
			if luautils.stringStarts(afterDot, prefix) then
				return reason
			end
		end
	end

	return nil
end

--- Get all exclusions (for debug)
-- @return table Copy of the exclusions tables
function BookScanner.Exclusions.getAll()
	return {
		books = BookScanner.Exclusions.getAllBooks(),
		prefixes = BookScanner.Exclusions.getAllPrefixes()
	}
end

--- Get all excluded books
-- @return table Copy of EXCLUDED_BOOKS
function BookScanner.Exclusions.getAllBooks()
	local copy = {}
	for fullType, reason in pairs(EXCLUDED_BOOKS) do
		copy[fullType] = reason
	end
	return copy
end

--- Get all excluded prefixes
-- @return table Copy of EXCLUDED_PREFIXES
function BookScanner.Exclusions.getAllPrefixes()
	local copy = {}
	for prefix, reason in pairs(EXCLUDED_PREFIXES) do
		copy[prefix] = reason
	end
	return copy
end

--- Count total number of exclusions
-- @return table Count of books and prefixes
function BookScanner.Exclusions.count()
	local bookCount = 0
	local prefixCount = 0

	for _ in pairs(EXCLUDED_BOOKS) do
		bookCount = bookCount + 1
	end

	for _ in pairs(EXCLUDED_PREFIXES) do
		prefixCount = prefixCount + 1
	end

	return {
		books = bookCount,
		prefixes = prefixCount,
		total = bookCount + prefixCount
	}
end

local counts = BookScanner.Exclusions.count()
log("BSExclusions.lua loaded - " .. counts.books .. " books + " .. counts.prefixes .. " prefixes excluded")
