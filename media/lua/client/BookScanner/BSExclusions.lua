--[[
-- media/lua/client/BookScanner/BSExclusions.lua
-- COMMENTED OUT - Will be reintegrated in Phase 3 after refactor
-- This file caused bugs with nil category and PDA name issues
-- Kept as reference for exclusion system architecture

require("BookScanner/BSLogger")

BookScanner = BookScanner or {}
BookScanner.Exclusions = {}

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug

--- List of excluded books with their reasons
-- Format: ["FullType"] = "Reason displayed in tooltip"
local EXCLUDED_BOOKS = {
	-- ===== Gyde Trait Magazines =====
	-- Magazines that grant permanent traits
	["Base.NutritionistMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.OutdoorsmanMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.HandyMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.AxeManMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.BurglarMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.SpeedDemonMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.OrganizedMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.FastLearnerMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.FastReaderMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.GracefulMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.DextrousMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.InconspicuousMag"] = "Trait magazine (Gyde Trait Magazines)",
	["Base.KeenHearingMag"] = "Trait magazine (Gyde Trait Magazines)",

	-- ===== Future Examples (Commented) =====
	-- ["Base.BookUnlimitedCarryWeight"] = "Cheat item (excluded for balance)",
	-- ["ModName.SpecialBook"] = "Special mechanics incompatible with scanning",
}

--- Check if a book is excluded from scanning
-- @param fullType string The full type of the book (e.g., "Base.NutritionistMag")
-- @return boolean true if the book is excluded
function BookScanner.Exclusions.isExcluded(fullType)
	return EXCLUDED_BOOKS[fullType] ~= nil
end

--- Get the exclusion reason for a book
-- @param fullType string The full type of the book
-- @return string|nil The exclusion reason, or nil if not excluded
function BookScanner.Exclusions.getExclusionReason(fullType)
	return EXCLUDED_BOOKS[fullType]
end

--- Add a book to the exclusion list (for future compatibility)
-- @param fullType string The full type of the book
-- @param reason string The reason for exclusion
function BookScanner.Exclusions.addExclusion(fullType, reason)
	if EXCLUDED_BOOKS[fullType] then
		debug("Exclusion already exists for: " .. fullType)
		return
	end

	EXCLUDED_BOOKS[fullType] = reason
	log("Added exclusion: " .. fullType .. " - " .. reason)
end

--- Remove a book from the exclusion list (for debug/testing)
-- @param fullType string The full type of the book
function BookScanner.Exclusions.removeExclusion(fullType)
	if not EXCLUDED_BOOKS[fullType] then
		debug("No exclusion found for: " .. fullType)
		return
	end

	EXCLUDED_BOOKS[fullType] = nil
	log("Removed exclusion: " .. fullType)
end

--- Get all exclusions (for debug)
-- @return table Copy of the exclusions table
function BookScanner.Exclusions.getAll()
	local copy = {}
	for fullType, reason in pairs(EXCLUDED_BOOKS) do
		copy[fullType] = reason
	end
	return copy
end

--- Count total number of exclusions
-- @return number Number of excluded books
function BookScanner.Exclusions.count()
	local count = 0
	for _ in pairs(EXCLUDED_BOOKS) do
		count = count + 1
	end
	return count
end

log("BSExclusions.lua loaded - " .. BookScanner.Exclusions.count() .. " books excluded")
--]]
