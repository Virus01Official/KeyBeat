-- credits.lua
local credits = {}
local settings = require("settings")

local function getTranslation(key)
    return settings.getTranslation(key)
end

local creditsText = {
    "Game Development Team:",
    "Virus - Lead Programmer, Polish Translator and artist",
    "Jake Whittaker - Programmer, German Translator and Charter",
    "",
    "Contributors:",
    "TeamF - Miss sound and hitsound",
    "Ax - Spanish Translator",
    "",
    "Special Thanks:",
    "Our Families and Friends",
    "The LOVE2D Community",
    "The KeyBeat Community",
    "And to YOU, thanks for playing this game ^-^",
    "",
    "DEEZ NUTS",
}

local scrollSpeed = 50
local yOffset = 600 -- Starting Y offset

function credits.load()
    love.graphics.setBackgroundColor(0.1, 0.1, 0.1) -- Dark background
end

function credits.update(dt)
    yOffset = yOffset - scrollSpeed * dt
    if yOffset < -(#creditsText * 30 + 100) then
        yOffset = 600
    end
end

function credits.draw()
    love.graphics.setColor(1, 1, 1)
    local translatedCredits = getTranslation("Credits")
    love.graphics.printf(translatedCredits, 0, 50, love.graphics.getWidth(), "center")

    local y = yOffset
    for i, line in ipairs(creditsText) do
        local translatedLine = getTranslation(line)
        love.graphics.printf(translatedLine, 0, y, love.graphics.getWidth(), "center")
        y = y + 30
    end
end

function credits.keypressed(key)
    if key == "escape" then
        backToMenu()
        love.graphics.setBackgroundColor(0, 0, 0) -- Dark background
    end
end

return credits
