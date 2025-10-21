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

    -- Populate tabs
    self:populateTabs()

    -- Close button (right side)
    self.closeBtn = ISButton:new(
        self.width - btnWidth - padX,
        self.height - btnHeight - padY + 20,
        btnWidth,
        btnHeight,
        BookScanner.Config.getText("UI_BookScanner_Close"),
        self,
        BSLibraryWindow.close
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
    local tabWidth = self.width - (padX * 2)

    self.tabPanel = ISTabPanel:new(padX, padY, tabWidth, tabHeight)
    self.tabPanel:initialise()
    self.tabPanel:setAnchorBottom(true)
    self.tabPanel:setAnchorRight(true)
    self:addChild(self.tabPanel)

    -- Re-categorize books
    self.categorizedBooks = self:categorizeBooks()

    -- Create "All Books" tab first (skill books only, no recipes)
    local allSkillBooks = {}
    for category, books in pairs(self.categorizedBooks) do
        if category ~= "Recipes" and category ~= "Other" and category ~= "" then
            for _, book in ipairs(books) do
                if book.skills and #book.skills > 0 and book.skills[1].name ~= "" then
                    table.insert(allSkillBooks, book)
                end
            end
        end
    end

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
    local listHeight = self.height - 140
    local list = ISScrollingListBox:new(0, 0, self.width - 40, listHeight)
    list:initialise()
    list:instantiate()
    list:setAnchorBottom(true)
    list:setAnchorRight(true)
    list.selected = 0
    list.joypadParent = self
    list.font = UIFont.Small
    list.doDrawItem = self.drawBookItem
    list.drawBorder = true

    list.libraryWindow = self

    -- Calculate max height needed for this tab (3 columns fixed)
    local maxHeight = 60 -- Default
    local numColumns = 3 -- Fixed to 3 columns

    for _, bookData in ipairs(books) do
        if bookData.recipes and #bookData.recipes > 0 then
            -- Max 15 recipes shown (5 rows × 3 columns)
            local recipesToShow = math.min(#bookData.recipes, 15)
            local rows = math.ceil(recipesToShow / numColumns)
            local neededHeight = 60 + (rows * 18)

            -- Add extra line if more than 15 recipes
            if #bookData.recipes > 15 then
                neededHeight = neededHeight + 18
            end

            if neededHeight > maxHeight then
                maxHeight = neededHeight
            end
        end
    end

    -- Set the same height for all items in this tab
    list.itemheight = maxHeight

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
    local currentY = y + 5

    -- Book title
    self:drawText(bookData.displayName, x, currentY, 1, 1, 1, a, UIFont.Medium)
    currentY = currentY + 20

    -- Skill info or recipe count
    if bookData.skills and #bookData.skills > 0 then
        local skill = bookData.skills[1]
        local translatedSkillName = self.libraryWindow:getTranslatedSkillName(skill.name)
        local skillText = translatedSkillName .. " " .. skill.lvlMin .. "-" .. skill.lvlMax
        self:drawText(skillText, x, currentY, 0.8, 0.8, 0.5, a, UIFont.Small)
        currentY = currentY + 15
    elseif bookData.recipes and #bookData.recipes > 0 then
        local recipeCount = #bookData.recipes
        local recipeWord = (recipeCount > 1) and
            BookScanner.Config.getText("UI_BookScanner_Recipes") or
            BookScanner.Config.getText("UI_BookScanner_Recipe")

        local recipeText = recipeCount .. " " .. recipeWord
        self:drawText(recipeText, x, currentY, 0.5, 0.8, 0.8, a, UIFont.Small)
        currentY = currentY + 15
    end

    -- Progress
    if bookData.isMagazine then
        local learnedCount = bookData.learnedRecipes and #bookData.learnedRecipes or 0
        local totalRecipes = #bookData.recipes
        local progress = learnedCount .. "/" .. totalRecipes .. " " ..
            BookScanner.Config.getText("UI_BookScanner_RecipesLearned")

        if bookData.alreadyRead then
            progress = "✓ " .. BookScanner.Config.getText("UI_BookScanner_Completed")
            self:drawText(progress, x, currentY, 0.3, 0.9, 0.3, a, UIFont.Small)
        else
            self:drawText(progress, x, currentY, 0.7, 0.7, 0.7, a, UIFont.Small)
        end
        currentY = currentY + 18
    else
        -- Protection contre nil
        local pagesRead = bookData.alreadyReadPages or 0
        local totalPages = bookData.numberOfPages or 0

        local progress = pagesRead .. "/" .. totalPages .. " pages"
        if bookData.alreadyRead then
            progress = "✓ " .. BookScanner.Config.getText("UI_BookScanner_Completed")
            self:drawText(progress, x, currentY, 0.3, 0.9, 0.3, a, UIFont.Small)
        else
            self:drawText(progress, x, currentY, 0.7, 0.7, 0.7, a, UIFont.Small)
        end
        currentY = currentY + 15
    end

    -- Draw recipes in 3 columns (if any)
    if bookData.recipes and #bookData.recipes > 0 then
        local columnWidth = 250
        local numColumns = 3                                  -- Fixed to 3 columns
        local recipesToShow = math.min(#bookData.recipes, 15) -- Max 15 (5 rows × 3 columns)
        local maxRecipeNameLength = 40

        for i = 1, recipesToShow do
            local recipeName = bookData.recipes[i]
            local isLearned = false

            -- Check if learned
            if bookData.learnedRecipes then
                for _, learned in ipairs(bookData.learnedRecipes) do
                    if learned == recipeName then
                        isLearned = true
                        break
                    end
                end
            end

            -- Translate recipe name
            local translatedRecipe = self.libraryWindow:getTranslatedRecipeName(recipeName)

            -- Truncate if too long
            if string.len(translatedRecipe) > maxRecipeNameLength then
                translatedRecipe = string.sub(translatedRecipe, 1, maxRecipeNameLength - 3) .. "..."
            end

            -- Calculate position (3 columns fixed)
            local row = math.floor((i - 1) / numColumns)
            local col = (i - 1) % numColumns
            local recipeX = x + 10 + (col * columnWidth)
            local recipeY = currentY + (row * 18)

            -- Icon + name
            local icon = isLearned and "✓" or "✗"
            local color = isLearned and { r = 0.3, g = 0.9, b = 0.3 } or { r = 0.9, g = 0.3, b = 0.3 }

            self:drawText(icon .. " " .. translatedRecipe, recipeX, recipeY, color.r, color.g, color.b, a, UIFont.Small)
        end

        -- Calculate how many rows were used
        local rowsUsed = math.ceil(recipesToShow / numColumns)
        currentY = currentY + (rowsUsed * 18)

        -- Show "... and X more" if there are more than 15 recipes
        if #bookData.recipes > 15 then
            local remaining = #bookData.recipes - 15
            local moreText = "... " ..
                BookScanner.Config.getText("UI_BookScanner_AndXMore"):gsub("%%1", tostring(remaining))
            self:drawText(moreText, x + 10, currentY, 0.7, 0.7, 0.7, a, UIFont.Small)
        end
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

    local skillMapping = {
        ["FirstAid"] = "Doctor",
    }

    local translationKey = skillMapping[skillName] or skillName
    local vanillaKey = "IGUI_perks_" .. translationKey
    local translated = getText(vanillaKey)

    if translated == vanillaKey then
        return skillName
    end

    return translated
end

function BSLibraryWindow:getTranslatedRecipeName(recipeName)
    -- Try to get recipe display name from game
    local recipe = getScriptManager():getRecipe(recipeName)
    if recipe then
        -- Use getName() for translated name
        local displayName = recipe:getName()
        if displayName and displayName ~= "" then
            return displayName
        end
    end

    -- Fallback to recipe name
    return recipeName
end

function BSLibraryWindow:onRefresh()
    debug("Refreshing library...")

    BookScanner.Storage.syncBookProgress(self.pda, self.player)

    self:populateTabs()
    log("Library refreshed")
end

function BSLibraryWindow:onKeyRelease(key)
    if key == Keyboard.KEY_ESCAPE then
        self:close()
        return
    end
end

function BSLibraryWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
end

function BSLibraryWindow:prerender()
    ISCollapsableWindow.prerender(self)

    -- Check for ESC key
    if isKeyPressed(Keyboard.KEY_ESCAPE) then
        self:close()
    end

    -- Close if player is aiming
    if self.player and self.player:isAiming() then
        self:close()
    end
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
    o.minimumWidth = 850 -- Garantit que 3 colonnes de 250px tiennent
    o.minimumHeight = 400

    o.moveWithMouse = true
    ISLayoutManager.RegisterWindow('bookScannerLibrary', ISCollapsableWindow, o)

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

    for _, books in pairs(categories) do
        table.sort(books, function(a, b)
            return a.displayName < b.displayName
        end)
    end

    return categories
end

function BSLibraryWindow:determineCategory(bookData)
    if bookData.skills and #bookData.skills > 0 then
        local skillName = bookData.skills[1].name

        if skillName and skillName ~= "" then
            debug("Book: " .. bookData.displayName .. " -> Skill: " .. tostring(skillName))
            return skillName
        end
    end

    if bookData.recipes and #bookData.recipes > 0 then
        debug("Book: " .. bookData.displayName .. " -> Recipes")
        return "Recipes"
    end

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

    BookScanner.Storage.syncBookProgress(pda, player)

    local bookCount = BookScanner.Storage.getScannedBooksCount(pda)
    debug("Books in library: " .. bookCount)

    if bookCount == 0 then
        player:Say(BookScanner.Config.getText("UI_BookScanner_NoBooks"))
        return
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    local width = math.max(screenW * 0.5, 600)
    local height = math.max(screenH * 0.7, 400)

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
