local menu = {}
local settings = require("settings")
local selectedOption = 1
local options = {}
local menuBackgroundsFolder = "menuBackgrounds"
local backgrounds = {}
local currentBackground
local backgroundScaleX, backgroundScaleY
local currentMusic
local currentSongName
local GameLogo = love.graphics.newImage("assets/GameLogo.png")
local EnableFPS = settings.getEnableFPS()
local logoX, logoY
local logoRotation = 0
local logoScale = 0.25  -- Scale down the logo
local animationTime = 0
local animationDuration = 1
local showButtons = false
local animationInProgress = false
local randomTips = {
    "Report any bugs",
    "What is life?",
    "Opera GX is cool",
    "Also try out osu!",
    "Also try out rhythia",
    "'Click the circles'",
    "osu! is a game about circles",
    "Ado my beloved :DDD",
    "Touhou is awesome",
}

local eventTips = {
    "Happy Halloween",
    "Merry Christmas",
    "Happy New Year",
}

local function getTranslation(key)
    return settings.getTranslation(key)
end

-- Function to load songs
local function loadSongs()
    local songsFolder = "songs"
    local songs = {}
    for _, folder in ipairs(love.filesystem.getDirectoryItems(songsFolder)) do
        local musicPathMp3 = songsFolder .. "/" .. folder .. "/music.mp3"
        local musicPathOgg = songsFolder .. "/" .. folder .. "/music.ogg"
        local musicPath = nil

        if love.filesystem.getInfo(musicPathMp3) then
            musicPath = musicPathMp3
        elseif love.filesystem.getInfo(musicPathOgg) then
            musicPath = musicPathOgg
        end

        if musicPath then
            table.insert(songs, {path = musicPath, name = folder})
        end
    end
    return songs
end

function menu.load()
    randomIndex = love.math.random(1, #randomTips)
    options = {getTranslation("Start Game"), getTranslation("Settings"), getTranslation("Credits"), getTranslation("Chart Editor")}
    showButtons = false

    -- Load all images from the menuBackgrounds folder
    local files = love.filesystem.getDirectoryItems(menuBackgroundsFolder)
    for _, file in ipairs(files) do
        local filePath = menuBackgroundsFolder .. "/" .. file
        local image = love.graphics.newImage(filePath)
        table.insert(backgrounds, image)
    end

    -- Select a random background only if it's not already set
    if not currentBackground then
        currentBackground = backgrounds[love.math.random(#backgrounds)]
    end

    EnableFPS = settings.getEnableFPS()

    -- Calculate the scale factors
    updateBackgroundScale()

    -- Load songs and select a random one
    local songs = loadSongs()
    if #songs > 0 then
        -- Stop previous music if it's playing
        if currentMusic then
            currentMusic:stop()
        end

        -- Select a random song
        local selectedSong = songs[love.math.random(#songs)]
        currentMusic = love.audio.newSource(selectedSong.path, "stream")
        currentSongName = selectedSong.name
        currentMusic:setLooping(true)
        currentMusic:play()
    end

    -- Initialize logo position
    logoX = love.graphics.getWidth() / 2
    logoY = love.graphics.getHeight() / 2
end

function drawMenu()
    local currentDate = os.date("*t")  -- Returns a table with the current date and time

    local text = nil

    if currentDate.month == 10 then
        local translatedEventTip = getTranslation(eventTips[1])
        text = translatedEventTip
    elseif currentDate.month == 12 then
        local translatedEventTip = getTranslation(eventTips[2])
        text = translatedEventTip
    elseif currentDate.month == 1 and currentDate.day == 1 then
        local translatedEventTip = getTranslation(eventTips[3])
        text = translatedEventTip
    else
        local translatedTips = getTranslation(randomTips[randomIndex])
        text = translatedTips
    end

    local textWidth = love.graphics.getFont():getWidth(text)
    -- Calculate the x-coordinate to center the text
    local x = (love.graphics.getWidth() - textWidth) / 2

    -- Draw the current background scaled to the window size
    love.graphics.draw(currentBackground, 0, 0, 0, backgroundScaleX, backgroundScaleY)

    -- Draw the dimming overlay
    love.graphics.setColor(0, 0, 0, 0.5)  -- Set color to black with 50% opacity
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(1, 1, 1, 1)  -- Reset color to white with 100% opacity
    
    -- Draw the game logo
    love.graphics.draw(GameLogo, logoX, logoY, logoRotation, logoScale, logoScale, GameLogo:getWidth() / 2, GameLogo:getHeight() / 2)

    -- Draw the rest of the assets
    local translatedVer = getTranslation("Version: ")
    love.graphics.print(translatedVer .. currentVersion, 0, love.graphics.getHeight() - 50, 0, 1)
    love.graphics.print(text, x, love.graphics.getHeight() - 50, 0, 1)
end

function drawButton()
    local mouseX, mouseY = love.mouse.getPosition()
    for i, option in ipairs(options) do
        local translatedOption = getTranslation(option)
        local optionX = 0
        local optionY = love.graphics.getHeight() / 2 - 50 + i * 30
        local optionWidth = love.graphics.getWidth()
        local optionHeight = 30  -- Assume each option has a height of 30 pixels

        -- Check if the mouse is hovering over this option
        if mouseX >= optionX and mouseX <= optionX + optionWidth and mouseY >= optionY and mouseY <= optionY + optionHeight then
            selectedOption = i  -- Highlight this option
        end

        if i == selectedOption then
            love.graphics.printf("-> " .. translatedOption, optionX, optionY, optionWidth, "center")
        else
            love.graphics.printf(translatedOption, optionX, optionY, optionWidth, "center")
        end
    end 
end

function songPlayingText()
    local translatedNP = getTranslation("Now Playing: ")
    love.graphics.printf(translatedNP .. currentSongName, 0, 0, love.graphics.getWidth(), "center")
end

function menu.update(dt)
    -- Check if the window size has changed
    local windowWidth, windowHeight = love.graphics.getDimensions()
    if windowWidth ~= previousWindowWidth or windowHeight ~= previousWindowHeight then
        updateBackgroundScale()
        previousWindowWidth = windowWidth
        previousWindowHeight = windowHeight
    end

    if animationInProgress then
        animationTime = animationTime + dt
        if animationTime > animationDuration then
            animationTime = animationDuration
            animationInProgress = false
            showButtons = true
        end

        local t = animationTime / animationDuration
        logoRotation = t * math.pi * 2
        logoX = love.graphics.getWidth() / 2 - love.graphics.getWidth() * 0.15 * t
    end
end

function menu.draw()
    drawMenu()

    if EnableFPS == true then
        love.graphics.print("FPS: " .. love.timer.getFPS(), 0, 0)
    end

    -- Draw the menu options if animation is done
    if showButtons then
       drawButton()
    end

    -- Draw the current song name
    if currentSongName then
        songPlayingText()
    end
end

function menu.mousepressed(x, y, button)
    if button == 1 then
        if not animationInProgress and not showButtons then
            -- Check if the click is within the bounds of the GameLogo
            local logoWidth = GameLogo:getWidth() * logoScale
            local logoHeight = GameLogo:getHeight() * logoScale
            if x >= logoX - logoWidth / 2 and x <= logoX + logoWidth / 2 and y >= logoY - logoHeight / 2 and y <= logoY + logoHeight / 2 then
                animationInProgress = true
                animationTime = 0
            end
        elseif showButtons then
            -- Check if an option was clicked
            for i, option in ipairs(options) do
                local optionX = 0
                local optionY = love.graphics.getHeight() / 2 - 50 + i * 30
                local optionWidth = love.graphics.getWidth()
                local optionHeight = 30  -- Assume each option has a height of 30 pixels

                if x >= optionX and x <= optionX + optionWidth and y >= optionY and y <= optionY + optionHeight then
                    selectedOption = i
                    -- Trigger the selected option
                    if options[selectedOption] == getTranslation("Start Game") then
                        goToPlayMenu()
                    elseif options[selectedOption] == getTranslation("Settings") then
                        goToSettings()
                    elseif options[selectedOption] == getTranslation("Credits") then
                        goToCredits()
                    elseif options[selectedOption] == getTranslation("Chart Editor") then
                        gotoChartEditor()
                        currentMusic:stop()
                    end
                end
            end
        end
    end
end

function menu.keypressed(key)
    if showButtons then
        if key == "up" then
            selectedOption = selectedOption - 1
            if selectedOption < 1 then
                selectedOption = #options
            end
        elseif key == "down" then
            selectedOption = selectedOption + 1
            if selectedOption > #options then
                selectedOption = 1
            end
        elseif key == "return" or key == "space" then
            if options[selectedOption] == getTranslation("Start Game") then
                goToPlayMenu()
            elseif options[selectedOption] == getTranslation("Settings") then
                goToSettings()
            elseif options[selectedOption] == getTranslation("Credits") then
                goToCredits()
            elseif options[selectedOption] == getTranslation("Chart Editor") then
                gotoChartEditor()
                currentMusic:stop()
            end
        elseif key == "escape" then
            love.event.quit()
        end
    end
end

function updateBackgroundScale()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    backgroundScaleX = windowWidth / currentBackground:getWidth()
    backgroundScaleY = windowHeight / currentBackground:getHeight()
end

function menu.stopMusic()
    if currentMusic then
        currentMusic:stop()
    end
end

return menu
