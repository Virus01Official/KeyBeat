local playmenu = {}
local menu = require("menu")
local settings = require("settings")
local RatingEffectImageSize = settings.getRatingSize()
local selectedOption = nil
local options = {}
local optionsLoaded = false
local scrollOffset = 0
local visibleOptions = 5
local scoreBreakdown = nil
local mouseX, mouseY = 0, 0
local ModifiersButton = love.graphics.newImage("assets/modifiers.png")
local EnableFPS = settings.getEnableFPS()
local currentMusic = nil
local ModifiersVisible = false
local activeModifiers = {}
local chosenBackground = nil
local AllModifiers = {
    "Sudden Death",
    "No Fail",
    "Speed x1.5",
    "Randomize",
    "Hidden",
}
local searchQuery = ""
local filteredOptions = {}

-- Screen scaling variables
local baseWidth = 1280
local baseHeight = 720
local scaleX, scaleY = 1, 1
local currentWidth, currentHeight = baseWidth, baseHeight

local function updateScreenScale()
    currentWidth, currentHeight = love.graphics.getDimensions()
    scaleX = currentWidth / baseWidth
    scaleY = currentHeight / baseHeight
end

local function getTranslation(key)
    return settings.getTranslation(key)
end

function playmenu.load(breakdown)
    updateScreenScale()
    if not optionsLoaded then
        loadSongs()
        optionsLoaded = true
    end
    scoreBreakdown = breakdown
    EnableFPS = settings.getEnableFPS()
end

function loadSongs()
    local songsFolder = "songs"

    for _, folder in ipairs(love.filesystem.getDirectoryItems(songsFolder)) do
        local chartPath = songsFolder .. "/" .. folder .. "/chart.txt"
        local musicPathMp3 = songsFolder .. "/" .. folder .. "/music.mp3"
        local musicPathOgg = songsFolder .. "/" .. folder .. "/music.ogg"
        local backgroundPathPng = songsFolder .. "/" .. folder .. "/background.png"
        local backgroundPathJpg = songsFolder .. "/" .. folder .. "/background.jpg"
        local backgroundPathJpeg = songsFolder .. "/" .. folder .. "/background.jpeg"
        local musicPath = nil
        local backgroundPath = nil
        local infoPath = songsFolder .. "/" .. folder .. "/info.txt"

        if love.filesystem.getInfo(musicPathMp3) then
            musicPath = musicPathMp3
        elseif love.filesystem.getInfo(musicPathOgg) then
            musicPath = musicPathOgg
        end

        if love.filesystem.getInfo(backgroundPathPng) then
            backgroundPath = backgroundPathPng
        elseif love.filesystem.getInfo(backgroundPathJpg) then
            backgroundPath = backgroundPathJpg
        elseif love.filesystem.getInfo(backgroundPathJpeg) then
            backgroundPath = backgroundPathJpeg
        end

        if love.filesystem.getInfo(chartPath) and musicPath then
            local credits, difficulty = "Unknown", "Unknown"
            if love.filesystem.getInfo(infoPath) then
                local info = love.filesystem.read(infoPath)
                for line in info:gmatch("[^\r\n]+") do
                    local key, value = line:match("([^:]+):%s*(.+)")
                    if key and value then
                        if key == "Credits" then
                            credits = value
                        elseif key == "Difficulty" then
                            difficulty = value
                        end
                    end
                end
            end
            local song = {
                chart = chartPath, 
                music = musicPath, 
                name = folder, 
                credits = credits, 
                difficulty = difficulty, 
                background = backgroundPath
            }
            table.insert(options, song)
            table.insert(filteredOptions, song)
        end
    end
end

-- Modern color palette
local colors = {
    background = {0.13, 0.15, 0.18},
    panel = {0.18, 0.20, 0.23, 0.95},
    accent = {0.22, 0.60, 0.86, 1},
    accentLight = {0.35, 0.75, 1.0, 1},
    text = {0.95, 0.97, 1.0, 1},
    shadow = {0, 0, 0, 0.25},
    selected = {0.22, 0.60, 0.86, 0.15},
    hover = {0.22, 0.60, 0.86, 0.10},
    modifierActive = {0.22, 0.86, 0.60, 0.25},
}

-- Helper for rounded rectangles with shadow
local function drawRoundedRectWithShadow(mode, x, y, w, h, rx, ry)
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle(mode, x+4, y+4, w, h, rx, ry)
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle(mode, x, y, w, h, rx, ry)
end

function drawSearchBar()
    local searchBarWidth = currentWidth / 2
    local searchBarHeight = 36 * scaleY
    local searchBarX = currentWidth / 4
    local searchBarY = currentHeight - 75 * scaleY

    -- Shadow and rounded rectangle
    drawRoundedRectWithShadow("fill", searchBarX, searchBarY, searchBarWidth, searchBarHeight, 18 * scaleY, 18 * scaleY)

    -- Search icon (simple magnifier)
    love.graphics.setColor(colors.accent)
    local iconSize = 18 * scaleY
    local iconX = searchBarX + 10 * scaleX
    local iconY = searchBarY + searchBarHeight/2
    love.graphics.circle("line", iconX, iconY, iconSize/2, 32)
    love.graphics.line(iconX + iconSize/4, iconY + iconSize/4, iconX + iconSize, iconY + iconSize)

    -- Text
    love.graphics.setColor(colors.text)
    local font = love.graphics.newFont(18 * math.min(scaleX, scaleY))
    love.graphics.setFont(font)
    local text = searchQuery == "" and "Search songs..." or searchQuery
    local textColor = searchQuery == "" and {0.7, 0.7, 0.7, 1} or colors.text
    love.graphics.setColor(textColor)
    love.graphics.printf(text, iconX + iconSize + 8 * scaleX, searchBarY + 6 * scaleY, searchBarWidth - iconSize - 20 * scaleX, "left")
end

function drawSongs()
    local startY = 120 * scaleY
    local optionHeight = 90 * scaleY
    local optionSpacing = 18 * scaleY
    local optionWidth = currentWidth / 2
    local optionX = currentWidth / 4

    for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #filteredOptions) do
        local option = filteredOptions[i]
        local bgY = startY + (i - scrollOffset - 1) * (optionHeight + optionSpacing)

        local isMouseOver = mouseX >= optionX and mouseX <= optionX + optionWidth and
                            mouseY >= bgY and mouseY <= bgY + optionHeight

        -- Shadow and rounded rectangle
        drawRoundedRectWithShadow("fill", optionX, bgY, optionWidth, optionHeight, 18 * scaleY, 18 * scaleY)

        -- Highlight border for selected/hover
        if i == selectedOption or isMouseOver then
            love.graphics.setColor(colors.accent)
            love.graphics.setLineWidth(4)
            love.graphics.rectangle("line", optionX, bgY, optionWidth, optionHeight, 18 * scaleY, 18 * scaleY)
        end

        -- Option text
        love.graphics.setColor(colors.text)
        local font = love.graphics.newFont(18 * math.min(scaleX, scaleY))
        love.graphics.setFont(font)
        love.graphics.printf(option.name, optionX, bgY + 12 * scaleY, optionWidth, "center")
        love.graphics.setColor(colors.accentLight)
        love.graphics.printf("Credits: " .. option.credits, optionX, bgY + 38 * scaleY, optionWidth, "center")
        love.graphics.setColor(colors.text)
        love.graphics.printf("Difficulty: " .. option.difficulty, optionX, bgY + 62 * scaleY, optionWidth, "center")
    end
end

function drawModifiers()
    local modifiersWidth = 260 * scaleX
    local modifierHeight = 44 * scaleY
    local modifierSpacing = 14 * scaleY

    -- Semi-transparent overlay
    love.graphics.setColor(0, 0, 0, 0.35)
    love.graphics.rectangle("fill", 0, 0, currentWidth, currentHeight)

    -- Panel with shadow
    local panelX = currentWidth - modifiersWidth - 24 * scaleX
    local panelY = 80 * scaleY
    local panelH = #AllModifiers * (modifierHeight + modifierSpacing) + 40 * scaleY
    drawRoundedRectWithShadow("fill", panelX, panelY, modifiersWidth, panelH, 18 * scaleY, 18 * scaleY)

    -- Title
    love.graphics.setColor(colors.accent)
    local font = love.graphics.newFont(22 * math.min(scaleX, scaleY))
    love.graphics.setFont(font)
    love.graphics.printf("Modifiers", panelX, panelY + 10 * scaleY, modifiersWidth, "center")

    -- Modifier toggles
    for i, modifier in ipairs(AllModifiers) do
        local modifierY = panelY + 40 * scaleY + (i - 1) * (modifierHeight + modifierSpacing)
        local isMouseOver = mouseX >= panelX + 12 * scaleX and mouseX <= panelX + modifiersWidth - 12 * scaleX and
                            mouseY >= modifierY and mouseY <= modifierY + modifierHeight

        -- Toggle background
        if activeModifiers[modifier] then
            love.graphics.setColor(colors.modifierActive)
        elseif isMouseOver then
            love.graphics.setColor(colors.hover)
        else
            love.graphics.setColor(colors.selected)
        end
        love.graphics.rectangle("fill", panelX + 12 * scaleX, modifierY, modifiersWidth - 24 * scaleX, modifierHeight, 12 * scaleY, 12 * scaleY)

        -- Toggle border
        love.graphics.setColor(colors.accent)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", panelX + 12 * scaleX, modifierY, modifiersWidth - 24 * scaleX, modifierHeight, 12 * scaleY, 12 * scaleY)

        -- Modifier text
        love.graphics.setColor(colors.text)
        local font = love.graphics.newFont(18 * math.min(scaleX, scaleY))
        love.graphics.setFont(font)
        love.graphics.printf(modifier, panelX + 12 * scaleX, modifierY + 10 * scaleY, modifiersWidth - 24 * scaleX, "center")
    end
end

function drawModifierButton()
    local buttonSize = 80 * math.min(scaleX, scaleY)
    local buttonX = currentWidth - 100 * scaleX
    local buttonY = currentHeight - 100 * scaleY

    -- Shadow and rounded rectangle
    drawRoundedRectWithShadow("fill", buttonX, buttonY, buttonSize, buttonSize, buttonSize/2, buttonSize/2)

    -- Icon
    love.graphics.setColor(colors.accent)
    love.graphics.draw(ModifiersButton, buttonX + 8 * scaleX, buttonY + 8 * scaleY, 0,
        (buttonSize - 16 * scaleX) / ModifiersButton:getWidth(),
        (buttonSize - 16 * scaleY) / ModifiersButton:getHeight())
end

function drawPlaymenu()
    love.graphics.setBackgroundColor(colors.background)
    -- Top and bottom panels
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle("fill", 0, 0, currentWidth, 100 * scaleY, 0, 0, 18 * scaleY, 18 * scaleY)
    love.graphics.rectangle("fill", 0, currentHeight - 100 * scaleY, currentWidth, 100 * scaleY, 18 * scaleY, 18 * scaleY)

        if ModifiersVisible then
            drawModifiers()
        end

        drawSearchBar()

        if EnableFPS then
            love.graphics.setColor(colors.text)
            love.graphics.print("FPS: " .. love.timer.getFPS(), 18 * scaleX, 18 * scaleY)
        end

        drawSongs()
        drawModifierButton()
end

function playmenu.update(dt)
    updateScreenScale()
end

function playmenu.draw()
    drawPlaymenu()
end

function playmenu.wheelmoved(x, y)
    if not scoreBreakdown then
        scrollOffset = scrollOffset - y
        scrollOffset = math.max(0, math.min(#filteredOptions - visibleOptions, scrollOffset))
    end
end

function playmenu.mousepressed(x, y, button)
    mouseX, mouseY = x, y
    
    if scoreBreakdown then
        if button == 1 then
            scoreBreakdown = nil
        end
    else
        -- Check modifier button
        local buttonSize = 80 * math.min(scaleX, scaleY)
        local buttonX = currentWidth - 100 * scaleX
        local buttonY = currentHeight - 100 * scaleY
        
        if x >= buttonX and x <= buttonX + buttonSize and
           y >= buttonY and y <= buttonY + buttonSize then
            ModifiersVisible = not ModifiersVisible
            return
        end

        -- Check modifiers
        if ModifiersVisible then
            local modifiersWidth = 260 * scaleX
            local modifierHeight = 44 * scaleY
            local modifierSpacing = 14 * scaleY
            local panelX = currentWidth - modifiersWidth - 24 * scaleX
            local panelY = 80 * scaleY

            for i, modifier in ipairs(AllModifiers) do
                local modifierY = panelY + 40 * scaleY + (i - 1) * (modifierHeight + modifierSpacing)
                local btnX = panelX + 12 * scaleX
                local btnW = modifiersWidth - 24 * scaleX
                if x >= btnX and x <= btnX + btnW and
                   y >= modifierY and y <= modifierY + modifierHeight then
                    activeModifiers[modifier] = not activeModifiers[modifier]
                    return
                end
            end
        end

        -- Check song selection
        local startY = 120 * scaleY
        local optionHeight = 90 * scaleY
        local optionSpacing = 18 * scaleY
        local optionWidth = currentWidth / 2
        local optionX = currentWidth / 4
        
        for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #filteredOptions) do
            local bgY = startY + (i - scrollOffset - 1) * (optionHeight + optionSpacing)
            if x >= optionX and x <= optionX + optionWidth and
               y >= bgY and y <= bgY + optionHeight then
                if selectedOption == i then
                    local selected = filteredOptions[i]
                    if selected then
                        stopMusic()
                        startGame(selected.chart, selected.music, selected.background)
                    end
                else
                    selectedOption = i
                    local selected = filteredOptions[i]
                    if selected then
                        menu.stopMusic()
                        playMusic(selected.music)
                    end
                end
                return
            end
        end
        
        selectedOption = nil
        stopMusic()
    end
end

function playmenu.mousemoved(x, y, dx, dy, istouch)
    mouseX, mouseY = x, y
end

function playmenu.keypressed(key)
    if scoreBreakdown then
        if key == "space" then
            scoreBreakdown = nil
        end
    else
        if key == "backspace" then
            searchQuery = searchQuery:sub(1, -2)
            filterOptions()
        elseif key == "return" or key == "space" then
            if selectedOption then
                local selected = filteredOptions[selectedOption]
                stopMusic()
                startGame(selected.chart, selected.music, selected.background)
            end
        elseif key == "escape" then
            stopMusic()
            backToMenu()
        end
    end
end

function playmenu.textinput(text)
    searchQuery = searchQuery .. text
    filterOptions()
end

function filterOptions()
    filteredOptions = {}
    for _, option in ipairs(options) do
        if option.name:lower():find(searchQuery:lower()) then
            table.insert(filteredOptions, option)
        end
    end
    scrollOffset = 0
end

function playMusic(musicPath)
    if currentMusic then
        currentMusic:stop()
    end
    currentMusic = love.audio.newSource(musicPath, "stream")
    currentMusic:setLooping(true)
    currentMusic:setVolume(settings.getVolume())
    currentMusic:play()
end

function stopMusic()
    if currentMusic then
        currentMusic:stop()
    end
end

function playmenu.getModifiers()
    return activeModifiers
end

function love.resize(w, h)
    updateScreenScale()
end

return playmenu