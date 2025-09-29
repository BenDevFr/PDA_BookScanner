-- media/lua/client/BookScanner/BSCore.lua
-- Stalker PDA detection logic

require "BookScanner/BSLogger"
require "BookScanner/BSConfig"
require "BookScanner/BSUtils"

BookScanner = BookScanner or {}

local BSCore = {}
BookScanner.Core = BSCore

-- Local logger imports
local log = BookScanner.Logger.log
local error = BookScanner.Logger.error
local debug = BookScanner.Logger.debug
local verbose = BookScanner.Logger.verbose
local section = BookScanner.Logger.section

-- Local utils imports
local getPlayerInfo = BookScanner.Utils.getPlayerInfo
local formatPlayerLog = BookScanner.Utils.formatPlayerLog

-- Detect PDA in player inventory
function BSCore.detectPDA(player)
    if not player then 
        error("detectPDA() - player is nil")
        return nil
    end
    
    local _, userName, playerID = getPlayerInfo(player)
    
    section("PDA Detection Start")
    log(formatPlayerLog(player, "Searching for PDA"))
    
    local inventory = player:getInventory()
    if not inventory then
        error("Player inventory is nil")
        return nil
    end
    
    debug("Inventory found - Item count: " .. inventory:getItems():size())
    
    -- Search for PDA
    verbose("Calling FindAndReturn for " .. BookScanner.Config.PDA_TYPE)
    local pda = inventory:FindAndReturn(BookScanner.Config.PDA_TYPE)
    debug("FindAndReturn() - Result: " .. tostring(pda ~= nil))
    
    -- Secondary check
    verbose("Checking with containsType...")
    local hasPDA = inventory:containsType(BookScanner.Config.PDA_TYPE)
    debug("containsType() - Result: " .. tostring(hasPDA))
    
    -- Result
    if pda then
        local pdaID = pda:getID()
        local pdaName = pda:getDisplayName()
        log("✅ PDA detected - " .. pdaName .. " (ID: " .. pdaID .. ")")
        verbose("PDA position: " .. pda:getX() .. "," .. pda:getY())
    else
        log("❌ No PDA detected")
    end
    
    section("PDA Detection End")
    return pda
end

-- Check if player has PDA (fast version)
function BSCore.hasPDA(player)
    if not player then return false end
    
    local inventory = player:getInventory()
    local hasPDA = inventory:FindAndReturn(BookScanner.Config.PDA_TYPE) ~= nil
    
    debug(formatPlayerLog(player, "Has PDA: " .. tostring(hasPDA)))
    
    return hasPDA
end

log("BSCore.lua loaded")