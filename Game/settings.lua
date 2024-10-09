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

-- Define categories
local categories = {"Audio", "Gameplay", "Display", "General"}

-- Update options to include category information
local options = {
    Audio = {"Volume"},
    Gameplay = {"Note Speed", "Note Size", "Skins"},
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
local backgroundDim = 0.5 -- Default dim value
local isFullscreen = false -- Default fullscreen value
local character = true
local enableFPS = false -- Default FPS display value
local selectedLanguage = "en" -- Default language

local translations = {}
local languages = {"en", "pl", "de", "es"} -- Available languages
local json = require("dkjson") -- Load the JSON library

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
        enableFPS = enableFPS, -- Save the FPS setting
        character = character,
        selectedLanguage = selectedLanguage -- Save the selected language
    }

    local encodedData = json.encode(data) -- Encode the data as JSON
    local byteData = love.data.encode("string", "base64", encodedData) -- Convert JSON string to base64 encoded byte data
    local compressedData = love.data.compress("string", "lz4", byteData) -- Compress the base64 encoded byte data using LZ4
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
                local jsonStr = love.data.decode("string", "base64", decompressedData) -- Decode LZ4 decompressed data from base64 to JSON string
                local data = json.decode(jsonStr) -- Decode the JSON data
                if data then
                    volume = data.volume or volume
                    noteSpeed = data.noteSpeed or noteSpeed
                    noteSize = data.noteSize or noteSize
                    selectedSkin = data.selectedSkin or selectedSkin
                    backgroundDim = data.backgroundDim or backgroundDim
                    RatingEffectImageSize = data.RatingEffectImageSize or RatingEffectImageSize
                    isFullscreen = data.isFullscreen or isFullscreen
                    enableFPS = data.enableFPS or enableFPS -- Load the FPS setting
                    character = data.character or character
                    selectedLanguage = data.selectedLanguage or selectedLanguage -- Load the selected language
                    if selectedLanguage == "jp" then
                        local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24)  -- Adjust size as needed
                        love.graphics.setFont(japaneseFont) -- Set the specific font
                    else
                        local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24)
                        love.graphics.setFont(originalFont)
                    end
                else
                    print("Failed to decode JSON data from decompressed LZ4 data.")
                end
            else
                print("Failed to decompress LZ4 data:", decompressedData)
            end
        else
            print("Failed to read compressed settings data from file.")
        end
    else
        print("Settings file 'settings.txt' not found.")
    end
end

function settings.load()
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
    local mouseX, mouseY = love.mouse.getPosition()
    hoveredOption = nil
    local yPosition = 100
    for i, option in ipairs(options[selectedCategory]) do
        if mouseY >= yPosition and mouseY <= yPosition + 50 then
            hoveredOption = i
            break
        end
        yPosition = yPosition + 50
    end
end

function settings.draw()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2) -- Dark background
    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 725, love.graphics.getWidth(), love.graphics.getHeight() - 600)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), love.graphics.getHeight() - 600)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(getTranslation("Settings") .. ":", 0, 25, love.graphics.getWidth(), "center")

    local yPosition = 100
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
        end

        local translatedOption = getTranslation(option)
        if i == selectedOption then
            love.graphics.setColor(1, 1, 0) -- Highlight selected option in yellow
            love.graphics.printf("-> " .. translatedOption .. ": " .. value, 0, yPosition, love.graphics.getWidth(), "center")
        elseif i == hoveredOption then
            love.graphics.setColor(0.8, 0.8, 0.8) -- Highlight hovered option in light gray
            love.graphics.printf(translatedOption .. ": " .. value, 0, yPosition, love.graphics.getWidth(), "center")
        else
            love.graphics.setColor(1, 1, 1) -- Default color
            love.graphics.printf(translatedOption .. ": " .. value, 0, yPosition, love.graphics.getWidth(), "center")
        end
        yPosition = yPosition + 50
    end

    -- Draw category buttons at the bottom
    local buttonY = love.graphics.getHeight() - 70
    local buttonWidth = love.graphics.getWidth() / #categories
    for i, category in ipairs(categories) do
        if category == selectedCategory then
            love.graphics.setColor(0.8, 0.8, 0.8)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(getTranslation(category), (i - 1) * buttonWidth, buttonY + 15, buttonWidth, "center")
    end
end

function settings.mousepressed(x, y, button)
    local buttonY = love.graphics.getHeight() - 70
    if y >= buttonY then
        local buttonWidth = love.graphics.getWidth() / #categories
        local index = math.floor(x / buttonWidth) + 1
        if index >= 1 and index <= #categories then
            selectedCategory = categories[index]
            selectedOption = 1 -- Reset to the first option in the new category
        end
    elseif hoveredOption then
        selectedOption = hoveredOption
        if button == 1 then -- Left mouse button
            adjustSettingValue("decrease")
        elseif button == 2 then -- Right mouse button
            adjustSettingValue("increase")
        end
    end
end

function adjustSettingValue(direction)
    local delta = (direction == "increase") and 1 or -1
    if options[selectedCategory][selectedOption] == "Volume" then
        volume = math.max(0, math.min(1, volume + delta * 0.1))
        love.audio.setVolume(volume)
    elseif options[selectedCategory][selectedOption] == "Note Speed" then
        noteSpeed = math.max(100, math.min(1000, noteSpeed + delta * 50))
    elseif options[selectedCategory][selectedOption] == "Note Size" then
        noteSize = math.max(10, math.min(100, noteSize + delta * 5))
    elseif options[selectedCategory][selectedOption] == "Skins" then
        selectedSkin = selectedSkin + delta
        if selectedSkin < 1 then
            selectedSkin = #skins
        elseif selectedSkin > #skins then
            selectedSkin = 1
        end
    elseif options[selectedCategory][selectedOption] == "Background Dim" then
        backgroundDim = math.max(0, math.min(1, backgroundDim + delta * 0.1))
    elseif options[selectedCategory][selectedOption] == "Rating Effect Size" then
        RatingEffectImageSize = math.max(20, RatingEffectImageSize + delta * 10)
    elseif options[selectedCategory][selectedOption] == "Fullscreen" then
        isFullscreen = not isFullscreen
        love.window.setFullscreen(isFullscreen)
    elseif options[selectedCategory][selectedOption] == "Show Character" then
        character = not character
    elseif options[selectedCategory][selectedOption] == "Enable FPS" then
        enableFPS = not enableFPS
    elseif options[selectedCategory][selectedOption] == "Language" then
        local index = table.indexOf(languages, selectedLanguage)
        index = index + delta
        if index < 1 then
            index = #languages
        elseif index > #languages then
            index = 1
        end
        selectedLanguage = languages[index]
        if selectedLanguage == "jp" then
            local japaneseFont = love.graphics.newFont("Fonts/NotoSansCJKjp-Regular.otf", 24)  -- Adjust size as needed
            love.graphics.setFont(japaneseFont) -- Set the specific font
        else
            local originalFont = love.graphics.newFont("Fonts/NotoSans-Regular.ttf", 24)
            love.graphics.setFont(originalFont)
        end
    end
    saveSettings()
end

function settings.keypressed(key)
    if key == "escape" then
        love.graphics.setBackgroundColor(0, 0, 0) -- Dark background
        backToMenu()
    end
end

function settings.getVolume()
    return volume
end

function settings.getNoteSpeed()
    return noteSpeed
end

function settings.getNoteSize()
    return noteSize
end

function settings.getSelectedSkin()
    return skins[selectedSkin]
end

function settings.getBackgroundDim()
    return backgroundDim
end

function settings.getRatingSize()
    return RatingEffectImageSize
end

function settings.getFullscreen()
    return isFullscreen
end

function settings.getEnableFPS()
    return enableFPS
end

function settings.getSelectedLanguage()
    return selectedLanguage
end

function settings.getCharacterVis()
    return character
end

function settings.getTranslation(key)
    return getTranslation(key)
end

return settings
