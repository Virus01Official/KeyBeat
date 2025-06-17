local settings = {}

-- Define table.indexOf function
function table.indexOf(t, value)
    for i, v in ipairs(t) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Screen scaling variables
local baseWidth = 1280
local baseHeight = 720
local scaleX, scaleY = 1, 1
local currentWidth, currentHeight = baseWidth, baseHeight

-- Define categories
local categories = {"Audio", "Gameplay", "Display", "General"}

-- Update options to include category information
local options = {
    Audio = {"Volume"},
    Gameplay = {"Note Speed", "Note Size", "Skins", "Scroll Velocity"},
    Display = {"Background Dim", "Rating Effect Size", "Fullscreen", "Enable FPS", "Show Character"},
    General = {"Language"}
}
local selectedCategory = "Audio"
local selectedOption = 1
local volume = 1
local hoveredOption = nil
local noteSpeed = 300
local noteSize = 20
local RatingEffectImageSize = 150
local skins = {}
local selectedSkin = 1
local scrollVelocity = 1.0
local backgroundDim = 0.5
local isFullscreen = false
local character = true
local enableFPS = false
local selectedLanguage = "en"

local translations = {}
local languages = {"en", "pl", "de", "es"}
local json = require("dkjson")

-- Screen scaling function
local function updateScreenScale()
    currentWidth, currentHeight = love.graphics.getDimensions()
    scaleX = currentWidth / baseWidth
    scaleY = currentHeight / baseHeight
end

local function loadTranslations()
    for _, lang in ipairs(languages) do
        local filePath = "Translations/" .. lang .. ".json"
        if love.filesystem.getInfo(filePath) then
            local content = love.filesystem.read(filePath)
            translations[lang] = json.decode(content)
        end
    end
end

local function getTranslation(key)
    return translations[selectedLanguage][key] or key
end

local function saveSettings()
    local data = {
        volume = volume,
        noteSpeed = noteSpeed,
        noteSize = noteSize,
        selectedSkin = selectedSkin,
        backgroundDim = backgroundDim,
        RatingEffectImageSize = RatingEffectImageSize,
        isFullscreen = isFullscreen,
        enableFPS = enableFPS,
        character = character,
        selectedLanguage = selectedLanguage,
        scrollVelocity = scrollVelocity
    }

    local encodedData = json.encode(data)
    local byteData = love.data.encode("string", "base64", encodedData)
    local compressedData = love.data.compress("string", "lz4", byteData)
    love.filesystem.write("settings.txt", compressedData)
end

local function loadSettings()
    if love.filesystem.getInfo("settings.txt") then
        local compressedData = love.filesystem.read("settings.txt")
        if compressedData then
            local success, decompressedData = pcall(function()
                return love.data.decompress("string", "lz4", compressedData)
            end)
            if success then
                local jsonStr = love.data.decode("string", "base64", decompressedData)
                local data = json.decode(jsonStr)
                if data then
                    volume = data.volume or volume
                    noteSpeed = data.noteSpeed or noteSpeed
                    noteSize = data.noteSize or noteSize
                    selectedSkin = data.selectedSkin or selectedSkin
                    backgroundDim = data.backgroundDim or backgroundDim
                    RatingEffectImageSize = data.RatingEffectImageSize or RatingEffectImageSize
                    isFullscreen = data.isFullscreen or isFullscreen
                    enableFPS = data.enableFPS or enableFPS
                    character = data.character or character
                    selectedLanguage = data.selectedLanguage or selectedLanguage
                    scrollVelocity = data.scrollVelocity or scrollVelocity
                    
                    if selectedLanguage == "jp" then
                        local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24 * math.min(scaleX, scaleY))
                        love.graphics.setFont(japaneseFont)
                    else
                        local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24 * math.min(scaleX, scaleY))
                        love.graphics.setFont(originalFont)
                    end
                end
            end
        end
    end
end

function settings.load()
    updateScreenScale()
    
    -- Load available skins
    local skinFiles = love.filesystem.getDirectoryItems("skins")
    for _, skin in ipairs(skinFiles) do
        if love.filesystem.getInfo("skins/" .. skin, "directory") then
            table.insert(skins, skin)
        end
    end
    loadTranslations()
    loadSettings()
end

function settings.update(dt)
    updateScreenScale()
    local mouseX, mouseY = love.mouse.getPosition()
    hoveredOption = nil

    -- Match draw() hitbox logic
    local panelW = currentWidth * 0.7
    local panelH = currentHeight * 0.7
    local panelX = (currentWidth - panelW) / 2
    local panelY = (currentHeight - panelH) / 2
    local optionX = panelX + panelW * 0.05
    local optionW = panelW * 0.9
    local yPosition = panelY + 80 * scaleY
    local optionHeight = 54 * scaleY
    local optionSpacing = 12 * scaleY

    for i, option in ipairs(options[selectedCategory]) do
        if mouseX >= optionX and mouseX <= optionX + optionW and
           mouseY >= yPosition and mouseY <= yPosition + optionHeight then
            hoveredOption = i
            break
        end
        yPosition = yPosition + optionHeight + optionSpacing
    end
end

-- Modern color palette (reuse from playmenu for consistency)
local colors = {
    background = {0.13, 0.15, 0.18},
    panel = {0.18, 0.20, 0.23, 0.95},
    accent = {0.22, 0.60, 0.86, 1},
    accentLight = {0.35, 0.75, 1.0, 1},
    text = {0.95, 0.97, 1.0, 1},
    shadow = {0, 0, 0, 0.25},
    selected = {0.22, 0.60, 0.86, 0.15},
    hover = {0.22, 0.60, 0.86, 0.10},
}

local function drawRoundedRectWithShadow(mode, x, y, w, h, rx, ry)
    love.graphics.setColor(colors.shadow)
    love.graphics.rectangle(mode, x+4, y+4, w, h, rx, ry)
    love.graphics.setColor(colors.panel)
    love.graphics.rectangle(mode, x, y, w, h, rx, ry)
end

function settings.draw()
    love.graphics.setBackgroundColor(colors.background)

    -- Draw main settings panel
    local panelW = currentWidth * 0.7
    local panelH = currentHeight * 0.7
    local panelX = (currentWidth - panelW) / 2
    local panelY = (currentHeight - panelH) / 2
    drawRoundedRectWithShadow("fill", panelX, panelY, panelW, panelH, 24 * scaleY, 24 * scaleY)

    -- Title
    love.graphics.setColor(colors.accent)
    local fontSize = 32 * math.min(scaleX, scaleY)
    local font = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", fontSize)
    love.graphics.setFont(font)
    love.graphics.printf(getTranslation("Settings"), panelX, panelY + 20 * scaleY, panelW, "center")

    -- Draw options
    local optionFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 22 * math.min(scaleX, scaleY))
    love.graphics.setFont(optionFont)
    local yPosition = panelY + 80 * scaleY
    local optionHeight = 54 * scaleY
    local optionSpacing = 12 * scaleY
    local optionW = panelW * 0.9
    local optionX = panelX + panelW * 0.05

    for i, option in ipairs(options[selectedCategory]) do
        local value = ""
        if option == "Volume" then
            value = tostring(math.floor(volume * 100)) .. "%"
        elseif option == "Note Speed" then
            value = tostring(noteSpeed)
        elseif option == "Note Size" then
            value = tostring(noteSize)
        elseif option == "Skins" then
            value = skins[selectedSkin] or getTranslation("No skins available")
        elseif option == "Background Dim" then
            value = tostring(math.floor(backgroundDim * 100)) .. "%"
        elseif option == "Rating Effect Size" then
            value = tostring(RatingEffectImageSize)
        elseif option == "Fullscreen" then
            value = isFullscreen and getTranslation("On") or getTranslation("Off")
        elseif option == "Enable FPS" then
            value = enableFPS and getTranslation("On") or getTranslation("Off")
        elseif option == "Language" then
            value = selectedLanguage
        elseif option == "Show Character" then
            value = character and getTranslation("On") or getTranslation("Off")
        elseif option == "Scroll Velocity" then
            value = string.format("%.1f", scrollVelocity)
        end

        local translatedOption = getTranslation(option)
        -- Option background
        if i == selectedOption then
            love.graphics.setColor(colors.selected)
        elseif i == hoveredOption then
            love.graphics.setColor(colors.hover)
        else
            love.graphics.setColor(0, 0, 0, 0)
        end
        love.graphics.rectangle("fill", optionX, yPosition, optionW, optionHeight, 14 * scaleY, 14 * scaleY)

        -- Option border
        if i == selectedOption then
            love.graphics.setColor(colors.accent)
            love.graphics.setLineWidth(3)
            love.graphics.rectangle("line", optionX, yPosition, optionW, optionHeight, 14 * scaleY, 14 * scaleY)
        end

        -- Option text
        love.graphics.setColor(colors.text)
        love.graphics.printf(translatedOption .. ": " .. value, optionX + 12 * scaleX, yPosition + 12 * scaleY, optionW - 24 * scaleX, "left")

        yPosition = yPosition + optionHeight + optionSpacing
    end

    -- Draw category buttons
    local buttonY = panelY + panelH - 70 * scaleY
    local buttonW = panelW / #categories
    local buttonH = 44 * scaleY
    for i, category in ipairs(categories) do
        local bx = panelX + (i-1)*buttonW
        -- Button background
        if category == selectedCategory then
            love.graphics.setColor(colors.accent)
        elseif love.mouse.getY() >= buttonY and love.mouse.getY() <= buttonY + buttonH and
               love.mouse.getX() >= bx and love.mouse.getX() <= bx + buttonW then
            love.graphics.setColor(colors.hover)
        else
            love.graphics.setColor(colors.panel)
        end
        love.graphics.rectangle("fill", bx, buttonY, buttonW, buttonH, 12 * scaleY, 12 * scaleY)
        -- Button text
        love.graphics.setColor(colors.text)
        love.graphics.printf(getTranslation(category), bx, buttonY + 10 * scaleY, buttonW, "center")
    end
end

function settings.mousepressed(x, y, button)
    -- Match panel dimensions from settings.draw()
    local panelW = currentWidth * 0.7
    local panelH = currentHeight * 0.7
    local panelX = (currentWidth - panelW) / 2
    local panelY = (currentHeight - panelH) / 2
    local buttonY = panelY + panelH - 70 * scaleY
    local buttonW = panelW / #categories
    local buttonH = 44 * scaleY

    -- Check if click is inside the button bar
    if y >= buttonY and y <= buttonY + buttonH and x >= panelX and x <= panelX + panelW then
        local index = math.floor((x - panelX) / buttonW) + 1
        if index >= 1 and index <= #categories then
            selectedCategory = categories[index]
            selectedOption = 1
            return
        end
    end

    -- Match draw() hitbox logic for options
    local optionX = panelX + panelW * 0.05
    local optionW = panelW * 0.9
    local yPosition = panelY + 80 * scaleY
    local optionHeight = 54 * scaleY
    local optionSpacing = 12 * scaleY

    for i, option in ipairs(options[selectedCategory]) do
        if x >= optionX and x <= optionX + optionW and
           y >= yPosition and y <= yPosition + optionHeight then
            selectedOption = i
            if button == 1 then
                adjustSettingValue("decrease")
            elseif button == 2 then
                adjustSettingValue("increase")
            end
            return
        end
        yPosition = yPosition + optionHeight + optionSpacing
    end
end

function adjustSettingValue(direction)
    local delta = (direction == "increase") and 1 or -1
    local option = options[selectedCategory][selectedOption]
    
    if option == "Volume" then
        volume = math.max(0, math.min(1, volume + delta * 0.1))
        love.audio.setVolume(volume)
    elseif option == "Note Speed" then
        noteSpeed = math.max(100, math.min(1000, noteSpeed + delta * 50))
    elseif option == "Note Size" then
        noteSize = math.max(10, math.min(100, noteSize + delta * 5))
    elseif option == "Skins" then
        selectedSkin = ((selectedSkin + delta - 1) % #skins) + 1
    elseif option == "Background Dim" then
        backgroundDim = math.max(0, math.min(1, backgroundDim + delta * 0.1))
    elseif option == "Rating Effect Size" then
        RatingEffectImageSize = math.max(20, RatingEffectImageSize + delta * 10)
    elseif option == "Fullscreen" then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
        updateScreenScale()
    elseif option == "Show Character" then
        character = not character
    elseif option == "Enable FPS" then
        enableFPS = not enableFPS
    elseif option == "Language" then
        local index = table.indexOf(languages, selectedLanguage)
        index = ((index + delta - 1) % #languages) + 1
        selectedLanguage = languages[index]
        if selectedLanguage == "jp" then
            local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24 * math.min(scaleX, scaleY))
            love.graphics.setFont(japaneseFont)
        else
            local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24 * math.min(scaleX, scaleY))
            love.graphics.setFont(originalFont)
        end
    elseif option == "Scroll Velocity" then
        scrollVelocity = math.max(0.1, math.min(5, scrollVelocity + delta * 0.1))
    end
    saveSettings()
end

function settings.keypressed(key)
    if key == "escape" then
        love.graphics.setBackgroundColor(0, 0, 0)
        backToMenu()
    end
end

-- Getter functions
function settings.getVolume() return volume end
function settings.getNoteSpeed() return noteSpeed end
function settings.getNoteSize() return noteSize end
function settings.getSelectedSkin() return skins[selectedSkin] end
function settings.getBackgroundDim() return backgroundDim end
function settings.getRatingSize() return RatingEffectImageSize end
function settings.getFullscreen() return isFullscreen end
function settings.getEnableFPS() return enableFPS end
function settings.getSelectedLanguage() return selectedLanguage end
function settings.getCharacterVis() return character end
function settings.getTranslation(key) return getTranslation(key) end
function settings.getScrollVelocity() return scrollVelocity end
function settings.setScrollVelocity(newVelocity)
    scrollVelocity = math.max(0.1, math.min(5, newVelocity))
    saveSettings()
end

-- Handle window resize
function love.resize(w, h)
    updateScreenScale()
end

return settings