-- media/lua/client/BookScanner/BSContext.lua
-- Context menus for scanning books

require "BookScanner/BSCore"
require "BookScanner/BSBooks"
require "BookScanner/BSLogger"
require "BookScanner/BSConfig"
require "BookScanner/BSUtils"

BookScanner = BookScanner or {}

local BSContext = {}
BookScanner.Context = BSContext

-- Local imports
local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
local verbose = BookScanner.Logger.verbose
local section = BookScanner.Logger.section
local error = BookScanner.Logger.error
local formatPlayerLog = BookScanner.Utils.formatPlayerLog

-- Scan book action
function BSContext.scanBook(item, player)
    section("BOOK SCAN START")
    debug("Item: " .. tostring(item))
    debug("Player: " .. tostring(player))
    
    if not player then
        error("Player is nil")
        return
    end
    
    log(formatPlayerLog(player, "Attempting to scan book"))
    
    if not item then
        error("Item to scan is nil")
        return
    end
    
    local bookName = item:getDisplayName()
    local bookType = item:getType()
    debug("Book: " .. bookName .. " (" .. bookType .. ")")
    
    -- Check PDA
    verbose("Checking for PDA...")
    if not BookScanner.Core.hasPDA(player) then
        player:Say(BookScanner.Config.getText("UI_BookScanner_NeedPDA"))
        log("FAILED: No PDA")
        return
    end
    
    -- Check scannability
    verbose("Checking book scannability...")
    if not BookScanner.Books.isBookScannable(item) then
        player:Say(BookScanner.Config.getText("UI_BookScanner_NotScannable"))
        log("FAILED: Book not scannable")
        return
    end
    
    -- TODO Phase 2: Check if already scanned
    
    -- Extract info
    verbose("Extracting book info...")
    local bookInfo = BookScanner.Books.extractBookInfo(item)
    if not bookInfo then
        error("Unable to extract book info")
        return
    end
    
    -- TODO Phase 2: Store in PDA
    
    -- Feedback
    local successMsg = BookScanner.Config.getText("UI_BookScanner_ScanSuccess", bookName)
    player:Say(successMsg)
    log("SUCCESS: Book scanned - " .. bookName)
    
    -- Sound
    player:getEmitter():playSound(BookScanner.Config.SOUNDS.SCAN_SUCCESS)
    
    section("BOOK SCAN END")
end

-- Add "Scan with PDA" option to books
function BSContext.addScanBookMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        debug("addScanBookMenu: Unable to get player")
        return
    end
    
    verbose(formatPlayerLog(player, "Book context menu"))
    
    -- Check PDA
    if not BookScanner.Core.hasPDA(player) then
        verbose("No PDA, no menu")
        return
    end
    
    -- Process items
    verbose("Processing selected items...")
    local itemsArray = items
    if not items.get then
        itemsArray = ISInventoryPane.getActualItems(items)
    end
    
    if not itemsArray then
        debug("itemsArray is nil")
        return
    end
    
    local itemCount = itemsArray.size and itemsArray:size() or #itemsArray
    verbose("Item count: " .. itemCount)
    
    local scannableBookFound = false
    local targetItem = nil
    
    for i = 1, itemCount do
        local item
        if itemsArray.get then
            item = itemsArray:get(i - 1)
        else
            item = itemsArray[i]
        end
        
        -- Extract item if wrapped
        if item and type(item) == "table" and item.items then
            item = item.items[1]
        end
        
        if item and item.getDisplayName then
            local itemName = item:getDisplayName()
            local itemType = item:getType()
            verbose("Item: " .. itemName .. " (" .. itemType .. ")")
            
            if BookScanner.Books.isBookScannable(item) then
                debug("Scannable book: " .. itemName)
                scannableBookFound = true
                targetItem = item
                break
            end
        end
    end
    
    -- Add option if book found
    if scannableBookFound and targetItem then
        debug("Adding scan option for: " .. targetItem:getDisplayName())
        
        -- TODO Phase 2: Check if already scanned and show grayed option
        
        local menuText = BookScanner.Config.getText("UI_BookScanner_ContextScan")
        context:addOption(menuText, targetItem, BSContext.scanBook, player)
    end
end

-- Register context menu
Events.OnFillInventoryObjectContextMenu.Add(BSContext.addScanBookMenu)

log("BSContext.lua loaded")