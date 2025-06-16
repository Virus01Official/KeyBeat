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
    local yPosition = 100 * scaleY
    
    for i, option in ipairs(options[selectedCategory]) do
        if mouseY >= yPosition and mouseY <= yPosition + 50 * scaleY then
            hoveredOption = i
            break
        end
        yPosition = yPosition + 50 * scaleY
    end
end

function settings.draw()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    
    -- Draw background panels with scaling
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, currentHeight - 725 * scaleY, currentWidth, 125 * scaleY)
    love.graphics.rectangle("fill", 0, currentHeight - 100 * scaleY, currentWidth, 100 * scaleY)
    
    -- Set scaled font
    local fontSize = 24 * math.min(scaleX, scaleY)
    local font = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", fontSize)
    love.graphics.setFont(font)
    
    -- Draw title
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(getTranslation("Settings") .. ":", 0, 25 * scaleY, currentWidth, "center")
    
    -- Draw options
    local yPosition = 100 * scaleY
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
        if i == selectedOption then
            love.graphics.setColor(1, 1, 0)
            love.graphics.printf("-> " .. translatedOption .. ": " .. value, 0, yPosition, currentWidth, "center")
        elseif i == hoveredOption then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.printf(translatedOption .. ": " .. value, 0, yPosition, currentWidth, "center")
        else
            love.graphics.setColor(1, 1, 1)
            love.graphics.printf(translatedOption .. ": " .. value, 0, yPosition, currentWidth, "center")
        end
        yPosition = yPosition + 50 * scaleY
    end

    -- Draw category buttons
    local buttonY = currentHeight - 70 * scaleY
    local buttonWidth = currentWidth / #categories
    for i, category in ipairs(categories) do
        if category == selectedCategory then
            love.graphics.setColor(0.8, 0.8, 0.8)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        love.graphics.rectangle("fill", (i-1)*buttonWidth, buttonY, buttonWidth, 50 * scaleY)
        love.graphics.setColor(0, 0, 0)
        love.graphics.printf(getTranslation(category), (i-1)*buttonWidth, buttonY + 15 * scaleY, buttonWidth, "center")
    end
end

function settings.mousepressed(x, y, button)
    local buttonY = currentHeight - 70 * scaleY
    if y >= buttonY then
        local buttonWidth = currentWidth / #categories
        local index = math.floor(x / buttonWidth) + 1
        if index >= 1 and index <= #categories then
            selectedCategory = categories[index]
            selectedOption = 1
        end
    elseif hoveredOption then
        selectedOption = hoveredOption
        if button == 1 then
            adjustSettingValue("decrease")
        elseif button == 2 then
            adjustSettingValue("increase")
        end
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