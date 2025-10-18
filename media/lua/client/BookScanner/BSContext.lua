-- media/lua/client/BookScanner/BSContext.lua
-- Context menus for scanning books

require("BookScanner/BSCore")
require("BookScanner/BSBooks")
require("BookScanner/BSStorage")
require("BookScanner/BSLogger")
require("BookScanner/BSConfig")
require("BookScanner/BSUtils")

BookScanner = BookScanner or {}

local BSContext = {}
BookScanner.Context = BSContext

-- Local imports
local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug
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

	-- Check if book is in a container (not main inventory)
	local itemContainer = item:getContainer()
	local playerInventory = player:getInventory()

	if itemContainer and itemContainer ~= playerInventory then
		debug("Book in container, transferring to main inventory...")
		-- Transfer item to player's main inventory
		itemContainer:Remove(item)
		playerInventory:AddItem(item)
		log("Book transferred to main inventory")
	end

	-- Check PDA
	debug("Checking for PDA...")
	local pda = BookScanner.Core.detectPDA(player)
	if not pda then
		player:Say(BookScanner.Config.getText("UI_BookScanner_NoPDAPersonal"))
		log("FAILED: No personal PDA")
		return
	end

	-- Check scannability
	debug("Checking book scannability...")
	if not BookScanner.Books.isBookScannable(item) then
		player:Say(BookScanner.Config.getText("UI_BookScanner_NotScannable"))
		log("FAILED: Book not scannable")
		return
	end

	-- Extract info
	debug("Extracting book info...")
	local bookInfo = BookScanner.Books.extractBookInfo(item, player)
	if not bookInfo then
		error("Unable to extract book info")
		return
	end

	-- Check if already scanned
	debug("Checking for duplicates...")
	if BookScanner.Storage.isBookScanned(pda, bookInfo.fullType) then
		player:Say(BookScanner.Config.getText("UI_BookScanner_AlreadyScanned"))
		log("FAILED: Already scanned - " .. bookName)
		return
	end

	-- Save to PDA ModData
	debug("Saving to PDA ModData...")
	local saved = BookScanner.Storage.saveScannedBook(pda, bookInfo)

	if not saved then
		error("Failed to save book to ModData")
		return
	end

	-- Feedback
	local successMsg = BookScanner.Config.getText("UI_BookScanner_ScanSuccess", bookName)
	player:Say(successMsg)
	log("SUCCESS: Book scanned - " .. bookName)

	-- Stats
	local totalScanned = BookScanner.Storage.getScannedBooksCount(pda)
	debug("Total books in library: " .. totalScanned)

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

	debug(formatPlayerLog(player, "Book context menu"))

	-- Check PDA
	local pda = BookScanner.Core.detectPDA(player)
	if not pda then
		debug("No PDA, no menu")
		return
	end

	-- Process items
	debug("Processing selected items...")
	local itemsArray = items
	if not items.get then
		itemsArray = ISInventoryPane.getActualItems(items)
	end

	if not itemsArray then
		debug("itemsArray is nil")
		return
	end

	local itemCount = itemsArray.size and itemsArray:size() or #itemsArray
	debug("Item count: " .. itemCount)

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
			-- OPTIMIZATION: Early exit if not Literature category
			local itemCategory = item:getCategory()
			if itemCategory == "Literature" then
				local itemName = item:getDisplayName()
				local itemType = item:getType()
				debug("Checking Literature item: " .. itemName .. " (" .. itemType .. ")")

				if BookScanner.Books.isBookScannable(item) then
					debug("Scannable book found: " .. itemName)
					scannableBookFound = true
					targetItem = item
					break
				end
			else
				debug("Skipping non-Literature item: " .. item:getType())
			end
		end
	end

	-- Add option if book found
	if scannableBookFound and targetItem then
		debug("Adding scan option for: " .. targetItem:getDisplayName())

		-- Check if already scanned
		local alreadyScanned = BookScanner.Storage.isBookScanned(pda, targetItem:getFullType())

		if alreadyScanned then
			-- Add grayed out option
			local menuText = BookScanner.Config.getText("UI_BookScanner_ContextAlreadyScanned")
			local option = context:addOption(menuText, targetItem, nil)
			option.notAvailable = true
			debug("Book already scanned - option grayed out")
		else
			-- Add active scan option
			local menuText = BookScanner.Config.getText("UI_BookScanner_ContextScan")
			context:addOption(menuText, targetItem, BSContext.scanBook, player)
			debug("Scan option added")
		end
	end
end

-- Add "Connect to PDA" menu on PDAs
function BSContext.addConnectPDAMenu(playerIndex, context, items)
	local player = getSpecificPlayer(playerIndex)
	if not player then
		return
	end

	debug(formatPlayerLog(player, "PDA context menu"))

	-- Process items
	local itemsArray = items
	if not items.get then
		itemsArray = ISInventoryPane.getActualItems(items)
	end

	if not itemsArray then
		return
	end

	local itemCount = itemsArray.size and itemsArray:size() or #itemsArray

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

		if item and item.getFullType then
			local fullType = item:getFullType()

			-- Check if it's a PDA
			if fullType == "Base." .. BookScanner.Config.PDA_TYPE then
				local modData = item:getModData()

				if modData.owner then
					-- PDA already bound - show PDA name (grayed out, used as separator)
					local pdaName = item:getName()
					local option = context:addOption(pdaName, item, nil)
					option.notAvailable = true

					-- Add "Open Library" option
					local libraryText = BookScanner.Config.getText("UI_BookScanner_OpenLibrary")
					context:addOption(libraryText, item, function(pda)
						BookScanner.UI.openLibrary(player, pda)
					end)

					-- Debug option to unbind
					if BookScanner.Logger.debugMode then
						context:addOption("DEBUG: Unbind PDA", item, function(pda)
							BookScanner.Storage.unbindPDA(pda)
							player:Say("PDA unbound")
							log("DEBUG: PDA manually unbound")
						end)
					end
				else
					-- PDA not bound - add connect option
					local connectText = BookScanner.Config.getText("UI_BookScanner_ConnectPDA")
					context:addOption(connectText, item, function(pda)
						local success = BookScanner.Storage.bindPDAToPlayer(pda, player)
						if success then
							player:Say(BookScanner.Config.getText("UI_BookScanner_ConnectSuccess"))
							log("Player connected to PDA successfully")
						else
							player:Say(BookScanner.Config.getText("UI_BookScanner_ConnectFailed"))
							log("Failed to connect to PDA")
						end
					end)
				end

				break
			end
		end
	end
end

-- Register PDA context menu
Events.OnFillInventoryObjectContextMenu.Add(BSContext.addConnectPDAMenu)

-- Register context menu
Events.OnFillInventoryObjectContextMenu.Add(BSContext.addScanBookMenu)

log("BSContext.lua loaded")
