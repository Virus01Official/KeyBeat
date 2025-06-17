-- main.lua
local menu = require("menu")
local game = require("game")
local settings = require("settings")
local playmenu = require("playmenu")
local charteditor = require("charteditor")
local intro = require("intro")
local credits = require("credits")

currentVersion = "1.1"

gameState = "intro"  -- make gameState global for access in other modules

function love.load()
    love.graphics.setFont(love.graphics.newFont(20))
    hitsound = love.audio.newSource("assets/hitsound.ogg", "static")
    miss = love.audio.newSource("assets/miss.ogg", "static")
    logo = love.graphics.newImage("assets/logo.png")
    introSFX = love.audio.newSource("assets/Intro.mp3", "static")
    intro.load()
    settings.load() -- Load settings, including skins
    love.window.setFullscreen(settings.getFullscreen()) -- Set initial fullscreen state

    -- Register mouse events for playmenu
    love.mouse.setVisible(true)
    love.mouse.setGrabbed(false)
    love.mouse.setRelativeMode(false)
    love.mousemoved = playmenu.mousemoved  -- Register mousemoved function

    logoSizeX = 250
    logoSizeY = 250

    -- Original dimensions of the image
    originalWidth = logo:getWidth()
    originalHeight = logo:getHeight()

    -- Calculate the scaling factors
    LogoscaleX = logoSizeX / originalWidth
    LogoscaleY = logoSizeY / originalHeight
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
    elseif gameState == "game" then
        game.update(dt)
    elseif gameState == "settings" then
        settings.update(dt)
    elseif gameState == "playmenu" then
        playmenu.update(dt)
    elseif gameState == "intro" then
        intro.update(dt)
    elseif gameState == "credits" then
        credits.update(dt)
    elseif gameState == "joining" then
        joining.update(dt)
    elseif gameState == "charteditor" then
        charteditor.update(dt)
    end
end

function love.draw()
    if gameState == "menu" then
        menu.draw()
    elseif gameState == "game" then
        game.draw()
    elseif gameState == "settings" then
        settings.draw()
    elseif gameState == "playmenu" then
        playmenu.draw()
    elseif gameState == "intro" then
        intro.draw()
    elseif gameState == "credits" then
        credits.draw()
    elseif gameState == "joining" then
        joining.draw()
    elseif gameState == "charteditor" then
        charteditor.draw()
    end
end

function love.keypressed(key)
    if gameState == "menu" then
        menu.keypressed(key)
    elseif gameState == "game" then
        game.keypressed(key)
    elseif gameState == "settings" then
        settings.keypressed(key)
    elseif gameState == "playmenu" then
        playmenu.keypressed(key)
    elseif gameState == "intro" then
        intro.keypressed(key)
    elseif gameState == "credits" then
        credits.keypressed(key)
    elseif gameState == "charteditor" then
        charteditor.keypressed(key)
    end
end

function love.keyreleased(key)
    if gameState == "game" then
        game.keyreleased(key)
    end
end


function love.mousepressed(x, y, button, istouch, presses)
    if gameState == "playmenu" then
        playmenu.mousepressed(x, y, button)
    elseif gameState == "menu" then
        menu.mousepressed(x, y, button)
    elseif gameState == "game" then
        game.mousepressed(x, y, button)
    elseif gameState == "settings" then
        settings.mousepressed(x, y, button)
    elseif gameState == "joining" then
        joining.mousepressed(x, y, button)
    elseif gameState == "charteditor" then
        charteditor.mousepressed(x, y, button)
    end
end

function love.wheelmoved(x, y)
    if gameState == "playmenu" then
        playmenu.wheelmoved(x, y)
    end
end

function love.textinput(text) 
    if gameState == "playmenu" then
        playmenu.textinput(text)
    end
end

function love.resize(w, h)
    if game.calculateScale then
        game.calculateScale()
        -- Reload chart to update note positions
        if chartFile then
            loadChart(chartFile)
        end
    end
end

function startGame(chartFile, musicFile, backgroundFile)
    gameState = "game"
    game.start(chartFile, musicFile, function(breakdown)
        gameState = "playmenu"
        playmenu.load(breakdown)
    end, backgroundFile)
end

function goToPlayMenu()
    gameState = "playmenu"
    playmenu.load()
end

function goToSettings()
    gameState = "settings"
end

function backToMenu()
    gameState = "menu"
    menu.load()  -- Reload the menu options, but not the background
end

function goToCredits()
    gameState = "credits"
    credits.load()
end

function gotoJoining()
    gameState = "joining"
    joining.load()
end

function gotoChartEditor()
    gameState = "charteditor"
    charteditor.load()
end
