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

function drawModifiers()
    local modifiersWidth = 200 * scaleX
    local modifierHeight = 40 * scaleY
    local modifierSpacing = 10 * scaleY
    
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", currentWidth - modifiersWidth, 0, modifiersWidth, currentHeight)
    
    local modifierStartY = 100 * scaleY
    for i, modifier in ipairs(AllModifiers) do
        local modifierY = modifierStartY + (i - 1) * (modifierHeight + modifierSpacing)
        if activeModifiers[modifier] then
            love.graphics.setColor(0.2, 0.8, 0.2, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        love.graphics.rectangle("fill", currentWidth - modifiersWidth + 10 * scaleX, modifierY, 
                              modifiersWidth - 20 * scaleX, modifierHeight)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(modifier, currentWidth - modifiersWidth + 10 * scaleX, modifierY + 10 * scaleY, 
                           modifiersWidth - 20 * scaleX, "center")
    end
end

function drawScoreBreakdown()
    local fontSize = 24 * math.min(scaleX, scaleY)
    local font = love.graphics.newFont(fontSize)
    love.graphics.setFont(font)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(getTranslation("Score Breakdown:"), 0, 100 * scaleY, currentWidth, "center")
    love.graphics.printf(getTranslation("Score: ") .. scoreBreakdown.score, 0, 150 * scaleY, currentWidth, "center")
    love.graphics.printf(getTranslation("Hits: ") .. scoreBreakdown.hits, 0, 200 * scaleY, currentWidth, "center")
    love.graphics.printf(getTranslation("Misses: ") .. scoreBreakdown.misses, 0, 250 * scaleY, currentWidth, "center")
    love.graphics.printf(getTranslation("Accuracy: ") .. string.format("%.2f", scoreBreakdown.accuracy) .. "%", 
                        0, 300 * scaleY, currentWidth, "center")
    love.graphics.printf(getTranslation("Total Notes: ") .. scoreBreakdown.totalNotes, 0, 350 * scaleY, currentWidth, "center")
    
    local gradeImage = love.graphics.newImage("skins/default/" .. scoreBreakdown.grade .. ".png")
    local scaledRatingSize = RatingEffectImageSize * math.min(scaleX, scaleY)
    local x = currentWidth / 2 - scaledRatingSize / 2
    local y = 400 * scaleY
    love.graphics.draw(gradeImage, x, y, 0, 
                      scaledRatingSize / gradeImage:getWidth(), 
                      scaledRatingSize / gradeImage:getHeight())

    love.graphics.printf(getTranslation("Press SPACE to continue..."), 0, currentHeight - 50 * scaleY, currentWidth, "center")
end

function drawSearchBar()
    local searchBarWidth = currentWidth / 2
    local searchBarHeight = 30 * scaleY
    local searchBarX = currentWidth / 4
    local searchBarY = currentHeight - 75 * scaleY
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", searchBarX, searchBarY, searchBarWidth, searchBarHeight)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(searchQuery, searchBarX + 5 * scaleX, searchBarY, searchBarWidth - 10 * scaleX, "left")
end

function drawPlaymenu()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, currentHeight - 725 * scaleY, currentWidth, 125 * scaleY)
    love.graphics.rectangle("fill", 0, currentHeight - 100 * scaleY, currentWidth, 100 * scaleY)

    if scoreBreakdown then
        drawScoreBreakdown()
    else
        if ModifiersVisible then
            drawModifiers()
        end

        drawSearchBar()

        if EnableFPS then
            love.graphics.print("FPS: " .. love.timer.getFPS(), 10 * scaleX, 10 * scaleY)
        end

        drawSongs()
        drawModifierButton()
    end
end

function drawSongs()
    local startY = 100 * scaleY
    local optionHeight = 80 * scaleY
    local optionSpacing = 20 * scaleY
    local optionWidth = currentWidth / 2
    local optionX = currentWidth / 4
    
    for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #filteredOptions) do
        local option = filteredOptions[i]
        local bgY = startY + (i - scrollOffset - 1) * (optionHeight + optionSpacing)
        
        local mouseXCenter = mouseX
        local mouseYCenter = mouseY
        local isMouseOver = mouseXCenter >= optionX and mouseXCenter <= optionX + optionWidth and
                           mouseYCenter >= bgY and mouseYCenter <= bgY + optionHeight
        
        if i == selectedOption or isMouseOver then
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        
        love.graphics.rectangle("fill", optionX, bgY, optionWidth, optionHeight)
        
        local fontSize = 16 * math.min(scaleX, scaleY)
        local font = love.graphics.newFont(fontSize)
        love.graphics.setFont(font)
        
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(option.name, optionX, bgY + 10 * scaleY, optionWidth, "center")
        love.graphics.printf("Credits: " .. option.credits, optionX, bgY + 30 * scaleY, optionWidth, "center")
        love.graphics.printf("Difficulty: " .. option.difficulty, optionX, bgY + 50 * scaleY, optionWidth, "center")
    end
end

function drawModifierButton()
    local buttonSize = 80 * math.min(scaleX, scaleY)
    local buttonX = currentWidth - 100 * scaleX
    local buttonY = currentHeight - 100 * scaleY
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ModifiersButton, buttonX, buttonY, 0, 
                      buttonSize / ModifiersButton:getWidth(), 
                      buttonSize / ModifiersButton:getHeight())
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
            local modifiersWidth = 200 * scaleX
            local modifierHeight = 40 * scaleY
            local modifierSpacing = 10 * scaleY
            local modifierStartY = 100 * scaleY
            
            for i, modifier in ipairs(AllModifiers) do
                local modifierY = modifierStartY + (i - 1) * (modifierHeight + modifierSpacing)
                if x >= currentWidth - modifiersWidth + 10 * scaleX and 
                   x <= currentWidth - 10 * scaleX and
                   y >= modifierY and y <= modifierY + modifierHeight then
                    activeModifiers[modifier] = not activeModifiers[modifier]
                    return
                end
            end
        end

        -- Check song selection
        local startY = 100 * scaleY
        local optionHeight = 80 * scaleY
        local optionSpacing = 20 * scaleY
        local optionWidth = currentWidth / 2
        local optionX = currentWidth / 4
        
        for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #filteredOptions) do
            local bgY = startY + (i - scrollOffset - 1) * (optionHeight + optionSpacing)
            if x >= optionX and x <= optionX + optionWidth and
               y >= bgY and y <= bgY + optionHeight then
                if selectedOption == i + scrollOffset then
                    local selected = filteredOptions[selectedOption]
                    stopMusic()
                    startGame(selected.chart, selected.music, selected.background)
                else
                    selectedOption = i + scrollOffset
                    local selected = filteredOptions[selectedOption]
                    menu.stopMusic()
                    playMusic(selected.music)
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