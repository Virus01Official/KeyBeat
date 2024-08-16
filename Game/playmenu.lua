local playmenu = {}
local menu = require("menu")
local settings = require("settings")
local RatingEffectImageSize = settings.getRatingSize()
local selectedOption = nil  -- Change to store selected option index
local options = {}
local optionsLoaded = false  -- Flag to check if options have been loaded
local scrollOffset = 0  -- The current scroll offset
local visibleOptions = 5  -- Number of options visible at a time
local scoreBreakdown = nil
local mouseX, mouseY = 0, 0  -- Variables to store mouse coordinates
local ModifiersButton = love.graphics.newImage("assets/modifiers.png")
local EnableFPS = settings.getEnableFPS()
local currentMusic = nil  -- Track the currently playing music
local FeaturedMapsFolder = "Featured Maps"
local ModifiersVisible = false
local activeModifiers = {}
local AllModifiers = {
    "Sudden Death",
    "No Fail",
    "Speed x1.5",
    --"Double Time",
    "Randomize",
    "Hidden",
}
local searchQuery = ""  -- Store the search query
local filteredOptions = {}  -- Store filtered options based on search query

-- Add a table to store featured maps
local featuredOptions = {}

local function getTranslation(key)
    return settings.getTranslation(key)
end

function playmenu.load(breakdown)
    if not optionsLoaded then
        loadSongs()
        loadFeaturedMaps()  -- Load featured maps as well
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

        -- Check if either .mp3 or .ogg file exists
        if love.filesystem.getInfo(musicPathMp3) then
            musicPath = musicPathMp3
        elseif love.filesystem.getInfo(musicPathOgg) then
            musicPath = musicPathOgg
        end

        -- Check if either .png, .jpg, .jpeg, or .mp4 file exists
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
            local song = {chart = chartPath, music = musicPath, name = folder, credits = credits, difficulty = difficulty, background = backgroundPath}
            table.insert(options, song)
            table.insert(filteredOptions, song)  -- Initialize filteredOptions
        end
    end
end

function loadFeaturedMaps()
    local FeaturedMapsFolder = "Featured Maps"
    for _, folder in ipairs(love.filesystem.getDirectoryItems(FeaturedMapsFolder)) do
        local chartPath = FeaturedMapsFolder .. "/" .. folder .. "/chart.txt"
        local musicPathMp3 = FeaturedMapsFolder .. "/" .. folder .. "/music.mp3"
        local musicPathOgg = FeaturedMapsFolder .. "/" .. folder .. "/music.ogg"
        local backgroundPathPng = FeaturedMapsFolder .. "/" .. folder .. "/background.png"
        local backgroundPathJpg = FeaturedMapsFolder .. "/" .. folder .. "/background.jpg"            
        local backgroundPathJpeg = FeaturedMapsFolder .. "/" .. folder .. "/background.jpeg"
        local musicPath = nil
        local backgroundPath = nil
        local infoPath = FeaturedMapsFolder .. "/" .. folder .. "/info.txt"
    
        -- Check if either .mp3 or .ogg file exists
        if love.filesystem.getInfo(musicPathMp3) then
            musicPath = musicPathMp3
        elseif love.filesystem.getInfo(musicPathOgg) then
            musicPath = musicPathOgg
        end
    
        -- Check if either .png, .jpg, .jpeg, or .mp4 file exists
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
                local song = {chart = chartPath, music = musicPath, name = folder, credits = credits, difficulty = difficulty, background = backgroundPath}
                table.insert(featuredOptions, song)  -- Store featured maps separately
            end
        end
    end

function playmenu.update(dt)
end

function playmenu.draw()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2) -- Dark background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 725, love.graphics.getWidth(), love.graphics.getHeight() - 600)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), love.graphics.getHeight() - 600)

    if scoreBreakdown then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(getTranslation("Score Breakdown:"), 0, 100, love.graphics.getWidth(), "center")
        love.graphics.printf(getTranslation("Score: ") .. scoreBreakdown.score, 0, 150, love.graphics.getWidth(), "center")
        love.graphics.printf(getTranslation("Hits: ") .. scoreBreakdown.hits, 0, 200, love.graphics.getWidth(), "center")
        love.graphics.printf(getTranslation("Misses: ") .. scoreBreakdown.misses, 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf(getTranslation("Accuracy: ") .. string.format("%.2f", scoreBreakdown.accuracy) .. "%", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.printf(getTranslation("Total Notes: ") .. scoreBreakdown.totalNotes, 0, 350, love.graphics.getWidth(), "center")
        
        local gradeImage = love.graphics.newImage("skins/default/" .. scoreBreakdown.grade .. ".png")
        local x = love.graphics.getWidth() / 2 - RatingEffectImageSize / 2
        local y = 400
        love.graphics.draw(gradeImage, x, y, 0, RatingEffectImageSize / gradeImage:getWidth(), RatingEffectImageSize / gradeImage:getHeight())

        love.graphics.printf(getTranslation("Press SPACE to continue..."), 0, love.graphics.getHeight() - 50, love.graphics.getWidth(), "center")
    else
        if ModifiersVisible then
            love.graphics.setColor(0, 0, 0, 0.5)  -- Set color to black with 50% opacity
            love.graphics.rectangle("fill", love.graphics.getWidth() - 200, 0, 200, love.graphics.getHeight())

            -- Draw the modifier buttons
            love.graphics.setColor(1, 1, 1, 1)  -- Set color to white
            local modifierStartY = 100
            local modifierHeight = 40
            for i, modifier in ipairs(AllModifiers) do
                local modifierY = modifierStartY + (i - 1) * (modifierHeight + 10)
                if activeModifiers[modifier] then
                    love.graphics.setColor(0.2, 0.8, 0.2, 1)  -- Green for active modifiers
                else
                    love.graphics.setColor(1, 1, 1, 1)  -- White for inactive modifiers
                end
                love.graphics.rectangle("fill", love.graphics.getWidth() - 190, modifierY, 180, modifierHeight)
                love.graphics.setColor(0, 0, 0, 1)  -- Black text color
                love.graphics.printf(modifier, love.graphics.getWidth() - 190, modifierY + 10, 180, "center")
            end
        end

        -- Draw search bar
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, love.graphics.getHeight() - 75, love.graphics.getWidth() / 2, 30)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(searchQuery, love.graphics.getWidth() / 4 + 5, love.graphics.getHeight() - 75, love.graphics.getWidth() / 2 - 10, "left")

    -- Draw tab buttons
    love.graphics.setColor(currentTab == "all" and {0.8, 0.8, 0.8} or {1, 1, 1})
    love.graphics.rectangle("fill", 10, love.graphics.getHeight() - 75, 100, 30)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("All Maps", 10, love.graphics.getHeight() - 70, 100, "center")

    love.graphics.setColor(currentTab == "featured" and {0.8, 0.8, 0.8} or {1, 1, 1})
    love.graphics.rectangle("fill", 120, love.graphics.getHeight() - 75, 120, 30)
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf("Featured Maps", 120, love.graphics.getHeight() - 70, 120, "center")

    -- Filtered options based on search query
    local filteredOptions = {}
    for _, option in ipairs(options) do
        if string.find(string.lower(option.name), string.lower(searchQuery)) then
            table.insert(filteredOptions, option)
        end
    end

    -- Ensure the color is reset to white before drawing the image
    love.graphics.setColor(1, 1, 1, 1)

    -- Calculate the scaling factors
    local desiredWidth = 80
    local desiredHeight = 80
    local scaleX = desiredWidth / ModifiersButton:getWidth()
    local scaleY = desiredHeight / ModifiersButton:getHeight()

    -- Draw the modifier button with scaling
    love.graphics.draw(ModifiersButton, love.graphics.getWidth() - 100, love.graphics.getHeight() - 100, 0, scaleX, scaleY)

    if EnableFPS == true then
        love.graphics.print("FPS: " .. love.timer.getFPS(), 0, 0)
    end

    -- Draw maps based on the active tab
    local mapsToDisplay = (currentTab == "featured") and featuredOptions or filteredOptions

    local startY = 100
    for i = scrollOffset + 1, math.min(scrollOffset + visibleOptions, #mapsToDisplay) do
        local option = mapsToDisplay[i]
        local bgY = startY + (i - scrollOffset - 1) * 100

        local mouseXCenter = love.mouse.getX()
        local mouseYCenter = love.mouse.getY()
        local optionTopY = bgY
        local optionBottomY = bgY + 80
        local optionLeftX = love.graphics.getWidth() / 4
        local optionRightX = love.graphics.getWidth() / 4 + love.graphics.getWidth() / 2

        local isMouseOver = mouseXCenter >= optionLeftX and mouseXCenter <= optionRightX and
                             mouseYCenter >= optionTopY and mouseYCenter <= optionBottomY

        if i == selectedOption or isMouseOver then
            love.graphics.setColor(0.7, 0.7, 0.7, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end

        love.graphics.rectangle("fill", love.graphics.getWidth() / 4, bgY, love.graphics.getWidth() / 2, 80)

        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf(option.name, love.graphics.getWidth() / 4, bgY + 10, love.graphics.getWidth() / 2, "center")
        love.graphics.printf("Credits: " .. option.credits, love.graphics.getWidth() / 4, bgY + 30, love.graphics.getWidth() / 2, "center")
        love.graphics.printf("Difficulty: " .. option.difficulty, love.graphics.getWidth() / 4, bgY + 50, love.graphics.getWidth() / 2, "center")
    end
end
end

function playmenu.wheelmoved(x, y)
    if not scoreBreakdown then
        -- Scroll the options list
        scrollOffset = scrollOffset - y
        -- Ensure scrollOffset stays within bounds
        scrollOffset = math.max(0, math.min(#options - visibleOptions, scrollOffset))
    end
end

function playmenu.mousepressed(x, y, button)
    if scoreBreakdown then
        if button == 1 then  -- Left mouse button
            scoreBreakdown = nil
        end
    else
        if button == 1 then  -- Left mouse button
            -- Check if tab buttons were clicked
            if x >= 10 and x <= 110 and y >= love.graphics.getHeight() - 75 and y <= love.graphics.getHeight() - 45 then
                currentTab = "all"
                scrollOffset = 0
                return
            elseif x >= 120 and x <= 240 and y >= love.graphics.getHeight() - 75 and y <= love.graphics.getHeight() - 45 then
                currentTab = "featured"
                scrollOffset = 0
                return
            end

            -- Check if any modifier buttons were clicked
            local modifiersButtonX = love.graphics.getWidth() - 100
            local modifiersButtonY = love.graphics.getHeight() - 100
            local modifiersButtonWidth = 80
            local modifiersButtonHeight = 80

            if x >= modifiersButtonX and x <= modifiersButtonX + modifiersButtonWidth and
               y >= modifiersButtonY and y <= modifiersButtonY + modifiersButtonHeight then
                -- Toggle visibility of the modifiers menu
                ModifiersVisible = not ModifiersVisible
                return
            end

            -- Check if any modifier buttons were clicked
            if ModifiersVisible then
                local modifierStartY = 100
                local modifierHeight = 40
                for i, modifier in ipairs(AllModifiers) do
                    local modifierY = modifierStartY + (i - 1) * (modifierHeight + 10)
                    if x >= love.graphics.getWidth() - 190 and x <= love.graphics.getWidth() - 10 and
                       y >= modifierY and y <= modifierY + modifierHeight then
                        -- Toggle the active state of the clicked modifier
                        activeModifiers[modifier] = not activeModifiers[modifier]
                        return
                    end
                end
            end

            -- Calculate which option was clicked
            local mapsToDisplay = (currentTab == "featured") and featuredOptions or filteredOptions
            local startY = 100
            local indexClicked = math.floor((y - startY) / 100) + 1 + scrollOffset

            if indexClicked >= 1 and indexClicked <= #mapsToDisplay then
                if selectedOption == indexClicked then
                    -- If the same map is clicked again, start the game
                    local selected = mapsToDisplay[selectedOption]
                    stopMusic()
                    startGame(selected.chart, selected.music, selected.background)
                else
                    -- Select a new map and play its music
                    selectedOption = indexClicked
                    local selected = mapsToDisplay[selectedOption]
                    menu.stopMusic()
                    playMusic(selected.music)
                end
            else
                -- Deselect if clicking outside options
                selectedOption = nil
                stopMusic()
            end
        end
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
end

-- Function to play music
function playMusic(musicPath)
    if currentMusic then
        currentMusic:stop()
    end
    currentMusic = love.audio.newSource(musicPath, "stream")
    currentMusic:setLooping(true)
    currentMusic:play()
end

-- Function to stop the current music
function stopMusic()
    if currentMusic then
        currentMusic:stop()
    end
end

function playmenu.getModifiers()
    return activeModifiers
end

return playmenu
