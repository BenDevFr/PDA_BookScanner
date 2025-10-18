-- media/lua/client/BookScanner/BSUI.lua
-- UI system for library interface

require("BookScanner/BSLogger")
require("BookScanner/BSStorage")
require("BookScanner/BSReadScannedBook")

BookScanner = BookScanner or {}

local BSUI = {}
BookScanner.UI = BSUI

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug

-- Open library window
function BSUI.openLibrary(player, pda)
    if not player or not pda then
        debug("openLibrary: missing player or pda")
        return
    end

    log("Opening library for player")

    -- Get scanned books
    local scannedBooks = BookScanner.Storage.getScannedBooks(pda)
    local bookCount = BookScanner.Storage.getScannedBooksCount(pda)

    debug("Books in library: " .. bookCount)

    if bookCount == 0 then
        player:Say(BookScanner.Config.getText("UI_BookScanner_NoBooks"))
        return
    end

    -- TODO: Create ISLibraryPanel here
    -- For now, just show a message with book list
    local message = "Library contains " .. bookCount .. " books:\n"
    for fullType, bookData in pairs(scannedBooks) do
        message = message .. "- " .. bookData.displayName .. "\n"
    end

    player:Say(message)
    log("Library opened (temporary debug view)")
end

log("BSUI.lua loaded")

return BSUI
