-- media/lua/client/BookScanner/BSTests.lua
--WARNING Development tests (remove in production)

require("BookScanner/BSCore")
require("BookScanner/BSBooks")
require("BookScanner/BSLogger")
require("BookScanner/BSConfig")
require("BookScanner/BSUtils")

BookScanner = BookScanner or {}

local BSTests = {}
BookScanner.Tests = BSTests

-- Local imports
local log = BookScanner.Logger.log
local separator = BookScanner.Logger.separator
local formatPlayerLog = BookScanner.Utils.formatPlayerLog

-- Test PDA detection
function BSTests.testPDADetection(playerIndex)
	separator()
	log("TEST PDA DETECTION - PlayerIndex: " .. tostring(playerIndex))
	separator()

	local player = getSpecificPlayer(playerIndex)
	if not player then
		log("ERROR: Unable to get player")
		return
	end

	local pda = BookScanner.Core.detectPDA(player)

	if pda then
		player:Say("PDA detected: " .. pda:getDisplayName())
		log("TEST PASSED: PDA detected")
	else
		player:Say("No PDA found")
		log("TEST FAILED: No PDA")
	end

	separator()
	log("PDA DETECTION TEST END")
	separator()
end

-- Test book detection
function BSTests.testBooksDetection(playerIndex)
	separator()
	log("TEST BOOKS DETECTION - PlayerIndex: " .. tostring(playerIndex))
	separator()

	local player = getSpecificPlayer(playerIndex)
	if not player then
		log("ERROR: Unable to get player")
		return
	end

	local books = BookScanner.Books.detectScannableBooks(player)

	local msg = BookScanner.Config.getText("UI_BookScanner_BooksFound", #books)
	player:Say(msg)

	if #books > 0 then
		log("TEST PASSED: " .. #books .. " book(s)")
	else
		log("TEST: No books")
	end

	separator()
	log("BOOKS DETECTION TEST END")
	separator()
end

-- Complete test PDA + Books
function BSTests.testComplete(playerIndex)
	separator()
	log("COMPLETE TEST - PlayerIndex: " .. tostring(playerIndex))
	separator()

	local player = getSpecificPlayer(playerIndex)
	if not player then
		log("ERROR: Unable to get player")
		return
	end

	-- Test PDA
	local hasPDA = BookScanner.Core.hasPDA(player)

	-- Test Books
	local books = BookScanner.Books.detectScannableBooks(player)

	-- Summary
	local message = "PDA: " .. (hasPDA and "YES" or "NO") .. " | Books: " .. #books
	player:Say(message)
	log("Result: " .. message)

	separator()
	log("COMPLETE TEST END")
	separator()
end

-- Temporary test context menu
local function onTestContextMenu(playerIndex, context, items)
	local player = getSpecificPlayer(playerIndex)
	if not player then
		return
	end

	local _, userName, playerID = BookScanner.Utils.getPlayerInfo(player)
	log("Test menu - PlayerID: " .. playerID .. " (" .. userName .. ")")

	-- Add test options
	context:addOption("TEST: Detect PDA", playerIndex, BSTests.testPDADetection)
	context:addOption("TEST: Detect Books", playerIndex, BSTests.testBooksDetection)
	context:addOption("TEST: Complete (PDA+Books)", playerIndex, BSTests.testComplete)

	log("Test options added")
end

-- Register test menu
Events.OnFillInventoryObjectContextMenu.Add(onTestContextMenu)

log("BSTests.lua loaded")
