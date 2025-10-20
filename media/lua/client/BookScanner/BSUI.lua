-- media/lua/client/BookScanner/BSUI.lua
-- UI system for library interface

require("BookScanner/BSLogger")
require("BookScanner/BSStorage")
require("BookScanner/BSReadScannedBook")
require("ISUI/ISCollapsableWindow")

BookScanner = BookScanner or {}

local BSUI = {}
BookScanner.UI = BSUI

local log = BookScanner.Logger.log
local debug = BookScanner.Logger.debug

-- ============================================
-- Library Window Class
-- ============================================

BSLibraryWindow = ISCollapsableWindow:derive("BSLibraryWindow")

function BSLibraryWindow:initialise()
    ISCollapsableWindow.initialise(self)
end

function BSLibraryWindow:createChildren()
    ISCollapsableWindow.createChildren(self)

    local padX = 10
    local padY = 40
    local btnHeight = 30

    -- Refresh button (left side)
    local btnWidth = 100
    self.refreshBtn = ISButton:new(
        padX,
        self.height - btnHeight - padY + 20,
        btnWidth,
        btnHeight,
        BookScanner.Config.getText("UI_BookScanner_Refresh"),
        self,
        BSLibraryWindow.onRefresh
    )
    self.refreshBtn:initialise()
    self.refreshBtn:setAnchorTop(false)
    self.refreshBtn:setAnchorBottom(true)
    self:addChild(self.refreshBtn)

    -- Populate tabs (will create tabPanel)
    self:populateTabs()

    -- Close button (right side)
    self.closeBtn = ISButton:new(
        self.width - btnWidth - padX,
        self.height - btnHeight - padY + 20,
        btnWidth,
        btnHeight,
        BookScanner.Config.getText("UI_BookScanner_Close"),
        self,
        BSLibraryWindow.onClose
    )
    self.closeBtn:initialise()
    self.closeBtn:setAnchorTop(false)
    self.closeBtn:setAnchorBottom(true)
    self.closeBtn:setAnchorLeft(false)
    self.closeBtn:setAnchorRight(true)
    self:addChild(self.closeBtn)
end

function BSLibraryWindow:populateTabs()
    -- Remove old tabPanel if exists
    if self.tabPanel then
        self:removeChild(self.tabPanel)
    end

    local padX = 10
    local padY = 40
    local btnHeight = 30
    local btnPadding = 10

    -- Recreate tab panel
    local tabHeight = self.height - padY - btnHeight - btnPadding - 20
    self.tabPanel = ISTabPanel:new(padX, padY, self.width - (padX * 2), tabHeight)
    self.tabPanel:initialise()
    self.tabPanel:setAnchorBottom(true)
    self.tabPanel:setAnchorRight(true)
    self:addChild(self.tabPanel)

    -- Re-categorize books (in case new books added)
    self.categorizedBooks = self:categorizeBooks()

    -- Create "All Books" tab first (skill books only, no recipes)
    local allSkillBooks = {}
    for category, books in pairs(self.categorizedBooks) do
        if category ~= "Recipes" and category ~= "Other" and category ~= "" then
            for _, book in ipairs(books) do
                -- Triple vérification : uniquement les livres avec skills valides
                if book.skills and #book.skills > 0 and book.skills[1].name ~= "" then
                    table.insert(allSkillBooks, book)
                end
            end
        end
    end

    -- Sort all books alphabetically
    table.sort(allSkillBooks, function(a, b)
        return a.displayName < b.displayName
    end)

    if #allSkillBooks > 0 then
        local allBooksTab = self:createSkillTab("AllBooks", allSkillBooks)
        local allBooksLabel = BookScanner.Config.getText("UI_BookScanner_CategoryAllBooks")
        self.tabPanel:addView(allBooksLabel, allBooksTab)
    end

    -- Create tabs for each skill category (sorted alphabetically)
    local sortedCategories = {}
    for skillName, _ in pairs(self.categorizedBooks) do
        if skillName ~= "Other" and skillName ~= "" then
            table.insert(sortedCategories, skillName)
        end
    end
    table.sort(sortedCategories)

    for _, skillName in ipairs(sortedCategories) do
        local books = self.categorizedBooks[skillName]
        local translatedName = self:getTranslatedSkillName(skillName)
        local tabContent = self:createSkillTab(skillName, books)
        self.tabPanel:addView(translatedName, tabContent)
    end

    -- Add "Other" tab at the end if exists
    if self.categorizedBooks["Other"] then
        local translatedName = self:getTranslatedSkillName("Other")
        local tabContent = self:createSkillTab("Other", self.categorizedBooks["Other"])
        self.tabPanel:addView(translatedName, tabContent)
    end
end

function BSLibraryWindow:createSkillTab(skillName, books)
    -- Scrollable list for this skill's books
    local listHeight = self.height - 140
    local list = ISScrollingListBox:new(0, 0, self.width - 40, listHeight)
    list:initialise()
    list:instantiate()
    list:setAnchorBottom(true)
    list:setAnchorRight(true)
    list.itemheight = 60
    list.selected = 0
    list.joypadParent = self
    list.font = UIFont.Small
    list.doDrawItem = self.drawBookItem
    list.drawBorder = true

    -- Reference to the library window
    list.libraryWindow = self

    -- Add books to list
    for _, bookData in ipairs(books) do
        list:addItem(bookData.displayName, bookData)
    end

    return list
end

function BSLibraryWindow:drawBookItem(y, item, alt)
    local a = 0.9

    -- Background
    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.7, 0.35, 0.15)
    end

    if alt then
        self:drawRect(0, (y), self:getWidth(), self.itemheight, 0.3, 0.6, 0.5, 0.5)
    end

    local bookData = item.item

    -- Book icon
    local iconX = 10
    local iconY = y + 5
    local iconW = 40
    local iconH = 50

    -- Récupérer la texture depuis le nom stocké
    local texture = nil
    if bookData.textureName then
        texture = getTexture(bookData.textureName)
    end

    if texture then
        self:drawTextureScaled(texture, iconX, iconY, iconW, iconH, a, 1, 1, 1)
    else
        self:drawRect(iconX, iconY, iconW, iconH, 1, 0.4, 0.3, 0.2)
        self:drawRectBorder(iconX, iconY, iconW, iconH, a, 0.8, 0.6, 0.4)
    end

    local x = 60

    -- Book title
    self:drawText(bookData.displayName, x, y + 5, 1, 1, 1, a, UIFont.Medium)

    -- Skill info or recipe count
    if bookData.skills and #bookData.skills > 0 then
        local skill = bookData.skills[1]

        -- Traduire le skill name
        local translatedSkillName = self.libraryWindow:getTranslatedSkillName(skill.name)

        local skillText = translatedSkillName .. " " .. skill.lvlMin .. "-" .. skill.lvlMax
        self:drawText(skillText, x, y + 25, 0.8, 0.8, 0.5, a, UIFont.Small)
    elseif bookData.recipes and #bookData.recipes > 0 then
        local recipeText = #bookData.recipes .. " " ..
            (#bookData.recipes > 1 and
                BookScanner.Config.getText("UI_BookScanner_Recipes") or
                BookScanner.Config.getText("UI_BookScanner_Recipe"))
        self:drawText(recipeText, x, y + 25, 0.5, 0.8, 0.8, a, UIFont.Small)
    end

    -- Progress
    local progress = bookData.alreadyReadPages .. "/" .. bookData.numberOfPages .. " pages"
    if bookData.alreadyRead then
        progress = BookScanner.Config.getText("UI_BookScanner_Completed")
        self:drawText(progress, x, y + 40, 0.3, 0.9, 0.3, a, UIFont.Small)
    else
        self:drawText(progress, x, y + 40, 0.7, 0.7, 0.7, a, UIFont.Small)
    end

    return y + self.itemheight
end

function BSLibraryWindow:getTranslatedSkillName(skillName)
    if skillName == "Recipes" then
        return BookScanner.Config.getText("UI_BookScanner_CategoryRecipes")
    end

    if skillName == "Other" then
        return BookScanner.Config.getText("UI_BookScanner_CategoryOther")
    end

    -- Map skill names to vanilla translation keys
    local skillMapping = {
        ["FirstAid"] = "Doctor",
    }

    local translationKey = skillMapping[skillName] or skillName
    local vanillaKey = "IGUI_perks_" .. translationKey
    local translated = getText(vanillaKey)

    -- Fallback to skill name if no translation
    if translated == vanillaKey then
        return skillName
    end

    return translated
end

function BSLibraryWindow:onRefresh()
    debug("Refreshing library...")
    BookScanner.Storage.syncBookProgress(self.pda, self.player)
    log("Library synchronized with player's reading progress")
    self:populateTabs()
    log("Library refreshed")
end

function BSLibraryWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function BSLibraryWindow:new(x, y, width, height, player, pda)
    local o = {}
    o = ISCollapsableWindow:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    o.pda = pda
    o.title = BookScanner.Config.getText("UI_BookScanner_LibraryTitle")
    o.resizable = true
    o.minimumWidth = 600
    o.minimumHeight = 400

    return o
end

function BSLibraryWindow:categorizeBooks()
    local scannedBooks = BookScanner.Storage.getScannedBooks(self.pda)
    local categories = {}

    for fullType, bookData in pairs(scannedBooks) do
        local categoryName = self:determineCategory(bookData)

        if not categories[categoryName] then
            categories[categoryName] = {}
        end

        table.insert(categories[categoryName], bookData)
    end

    -- Sort books alphabetically within each category
    for _, books in pairs(categories) do
        table.sort(books, function(a, b)
            return a.displayName < b.displayName
        end)
    end

    return categories
end

function BSLibraryWindow:determineCategory(bookData)
    -- Skill books (vérifier que le nom n'est pas vide)
    if bookData.skills and #bookData.skills > 0 then
        local skillName = bookData.skills[1].name

        -- CHECK : Si skillName est vide ou nil, c'est pas un skill book
        if skillName and skillName ~= "" then
            debug("Book: " .. bookData.displayName .. " -> Skill: " .. tostring(skillName))
            return skillName
        end
    end

    -- Recipe books
    if bookData.recipes and #bookData.recipes > 0 then
        debug("Book: " .. bookData.displayName .. " -> Recipes")
        return "Recipes"
    end

    -- Other (magazines, etc.)
    debug("Book: " .. bookData.displayName .. " -> Other")
    return "Other"
end

-- ============================================
-- Open library function
-- ============================================

function BSUI.openLibrary(player, pda)
    if not player or not pda then
        debug("openLibrary: missing player or pda")
        return
    end


    log("Opening library for player")

    -- Synchronize book progress with player's actual reading progress
    BookScanner.Storage.syncBookProgress(pda, player)

    -- Check if books exist
    local bookCount = BookScanner.Storage.getScannedBooksCount(pda)
    debug("Books in library: " .. bookCount)

    if bookCount == 0 then
        player:Say(BookScanner.Config.getText("UI_BookScanner_NoBooks"))
        return
    end

    -- Create and show window
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    -- 50% width, 70% height, minimum 600x400
    local width = math.max(screenW * 0.5, 600)
    local height = math.max(screenH * 0.7, 400)

    -- Center on screen
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    local window = BSLibraryWindow:new(x, y, width, height, player, pda)
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    window:setVisible(true)

    log("Library window opened")
end

log("BSUI.lua loaded")

return BSUI
