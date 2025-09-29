-- media/lua/client/BookScanner/BSBooks.lua
-- Book detection and analysis

require "BookScanner/BSCore"
require "BookScanner/BSLogger"
require "BookScanner/BSConfig"
require "BookScanner/BSUtils"

BookScanner = BookScanner or {}

local BSBooks = {}
BookScanner.Books = BSBooks

-- Local imports
local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
local verbose = BookScanner.Logger.verbose
local section = BookScanner.Logger.section
local error = BookScanner.Logger.error
local formatPlayerLog = BookScanner.Utils.formatPlayerLog

-- Check if item is a scannable book
function BSBooks.isBookScannable(item)
    if not item then 
        debug("isBookScannable: item is nil")
        return false 
    end
    
    local itemType = item:getType()
    local itemName = item:getDisplayName()
    
    verbose("Checking scannability: " .. itemName .. " (" .. itemType .. ")")
    
    -- Must have recipes OR valid skills
    local hasRecipes = item.getTeachedRecipes and item:getTeachedRecipes() and item:getTeachedRecipes():size() > 0
    local hasSkill = item.getSkillTrained and item:getSkillTrained() and item:getSkillTrained() ~= ""
    
    if hasRecipes then
        debug("  → USEFUL book with " .. item:getTeachedRecipes():size() .. " recipe(s)")
        return true
    end
    
    if hasSkill then
        debug("  → USEFUL skill book: " .. item:getSkillTrained())
        return true
    end
    
    verbose("  → USELESS book (no recipes or skills)")
    return false
end

-- Extract detailed book information
function BSBooks.extractBookInfo(item)
    if not item then 
        debug("extractBookInfo: item is nil")
        return nil 
    end
    
    verbose("Extracting info for: " .. item:getDisplayName())
    
    local bookInfo = {
        id = item:getID(),
        name = item:getDisplayName(),
        type = item:getType(),
        fullType = item:getFullType(),
        pages = (item.getNumberOfPages and item:getNumberOfPages()) or 0,
        alreadyRead = (item.isAlreadyRead and item:isAlreadyRead()) or false,
        teachedRecipes = {},
        skillTrained = nil,
        lvlSkillTrained = 0,
        maxLevelTrained = 0
    }
    
    -- Get taught recipes
    if item.getTeachedRecipes and item:getTeachedRecipes() then
        verbose("Extracting recipes...")
        for i = 0, item:getTeachedRecipes():size() - 1 do
            table.insert(bookInfo.teachedRecipes, item:getTeachedRecipes():get(i))
        end
    end
    
    -- Get skill info
    if item.getSkillTrained and item:getSkillTrained() then
        verbose("Extracting skills...")
        bookInfo.skillTrained = item:getSkillTrained()
        bookInfo.lvlSkillTrained = (item.getLvlSkillTrained and item:getLvlSkillTrained()) or 0
        bookInfo.maxLevelTrained = (item.getMaxLevelTrained and item:getMaxLevelTrained()) or 0
    end
    
    debug("Info extracted: " .. bookInfo.name)
    debug("  - Type: " .. bookInfo.type)
    debug("  - Pages: " .. bookInfo.pages)
    debug("  - Recipes: " .. #bookInfo.teachedRecipes)
    if bookInfo.skillTrained then
        debug("  - Skill: " .. bookInfo.skillTrained .. " (" .. bookInfo.lvlSkillTrained .. " -> " .. bookInfo.maxLevelTrained .. ")")
    end
    
    return bookInfo
end

-- Detect all scannable books in inventory
function BSBooks.detectBooks(player)
    if not player then 
        error("detectBooks() - player is nil")
        return {}
    end
    
    section("Book Detection Start")
    log(formatPlayerLog(player, "Scanning for books"))
    
    local inventory = player:getInventory()
    if not inventory then
        error("Player inventory is nil")
        return {}
    end
    
    local books = {}
    local items = inventory:getItems()
    
    log("Scanning " .. items:size() .. " items")
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        local itemName = item:getDisplayName()
        local itemType = item:getType()
        
        verbose("Item " .. i .. ": " .. itemName .. " (" .. itemType .. ")")
        
        if BSBooks.isBookScannable(item) then
            local bookInfo = BSBooks.extractBookInfo(item)
            if bookInfo then
                table.insert(books, bookInfo)
                log("✅ Book added: " .. bookInfo.name)
            end
        end
    end
    
    section("Book Detection Result")
    log("Scannable books: " .. #books)
    
    for i, book in ipairs(books) do
        local info = "Pages: " .. book.pages
        if book.skillTrained then
            info = "Skill: " .. book.skillTrained
        elseif #book.teachedRecipes > 0 then
            info = #book.teachedRecipes .. " recipe(s)"
        end
        debug(i .. ". " .. book.name .. " (" .. info .. ")")
    end
    
    section("Book Detection End")
    
    return books
end

log("BSBooks.lua loaded")