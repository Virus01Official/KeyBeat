-- charteditor.lua
local settings = require("settings")
local noteSpeed = settings.getNoteSpeed()
local noteSize = settings.getNoteSize()
local charteditor = {}
local chart = {}
local isEditing = true
local selectedNoteIndex = nil
local musicStartTime = nil
local songTime = 0
local music
local notePlacementMode = "normal" -- Modes: "normal" for regular notes, "hold" for hold notes
local songsFolder = "songs"
local hitLineY = 500
local currentSongName = nil
local songNameInput = "" -- Text input for song name
local isEnteringSongName = true -- Controls if user is in text input mode

function charteditor.load()
    noteSpeed = settings.getNoteSpeed()
    noteSize = settings.getNoteSize()
end

function charteditor.loadChart(filename)
    chart = {}
    local file = love.filesystem.read(filename)
    if file then
        for line in file:gmatch("[^\r\n]+") do
            local time, x, holdTime = line:match("([%d%.]+) ([%d%.]+) ([%d%.]+)")
            if time and x and holdTime then
                table.insert(chart, {time = tonumber(time), x = tonumber(x), hold = holdTime > 0, holdTime = tonumber(holdTime)})
            end
        end
    end
end

function charteditor.saveChart()
    if not currentSongName then
        print("Error: No song selected for saving the chart.")
        return
    end

    local chartData = {}
    for _, note in ipairs(chart) do
        table.insert(chartData, string.format("%f %d %f", note.time, note.x, note.holdTime or 0))
    end

    local chartFilename = songsFolder .. "/" .. currentSongName .. "/chart.txt"
    love.filesystem.createDirectory(songsFolder .. "/" .. currentSongName)
    love.filesystem.write(chartFilename, table.concat(chartData, "\n"))
    print("Chart saved as: " .. chartFilename)
end

function charteditor.update(dt)
    if music and music:isPlaying() then
        songTime = love.timer.getTime() - musicStartTime
    end
end

function charteditor.draw()
    love.graphics.print("Chart Editor Mode", 10, 10)
    love.graphics.print("Press 'N' for normal note, 'H' for hold note, 'S' to save", 10, 30)
    love.graphics.print("Click on screen to place note; Right-click to delete", 10, 50)
    love.graphics.print("Press 'P' to play/pause preview", 10, 70)

    love.graphics.line(0, hitLineY, love.graphics.getWidth(), hitLineY)

    if isEnteringSongName then
        love.graphics.print("Enter Song Name: " .. songNameInput, 10, 90)
        love.graphics.print("Press Enter to confirm song name", 10, 110)
    else
        for i, note in ipairs(chart) do
            local y = hitLineY - (note.time - songTime) * noteSpeed
            if note.hold then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", note.x, y, noteSize, noteSize + note.holdTime * noteSpeed)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", note.x, y, noteSize, noteSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function charteditor.placeNote(x, y)
    local time = songTime + (hitLineY - y) / noteSpeed
    if notePlacementMode == "normal" then
        table.insert(chart, {time = time, x = x, hold = false, holdTime = 0})
    elseif notePlacementMode == "hold" then
        table.insert(chart, {time = time, x = x, hold = true, holdTime = 1.0})
    end
end

function charteditor.removeNoteAt(x, y)
    for i = #chart, 1, -1 do
        local note = chart[i]
        local noteY = hitLineY - (note.time - songTime) * noteSpeed
        if x >= note.x and x <= note.x + noteSize and y >= noteY and y <= noteY + noteSize then
            table.remove(chart, i)
            break
        end
    end
end

function charteditor.keypressed(key)
    if isEnteringSongName then
        if key == "return" then
            charteditor.startEditing(songNameInput)
            isEnteringSongName = false
            songNameInput = ""
        elseif key == "backspace" then
            songNameInput = songNameInput:sub(1, -2)
        elseif #key == 1 then
            songNameInput = songNameInput .. key
        end
    else
        if key == "p" then
            if music and music:isPlaying() then
                music:pause()
            else
                music:play()
                musicStartTime = love.timer.getTime() - songTime
            end
        elseif key == "n" then
            notePlacementMode = "normal"
        elseif key == "h" then
            notePlacementMode = "hold"
        elseif key == "s" then
            charteditor.saveChart()
        end
    end
end

function charteditor.mousepressed(x, y, button)
    if not isEnteringSongName then
        if button == 1 then
            charteditor.placeNote(x, y)
        elseif button == 2 then
            charteditor.removeNoteAt(x, y)
        end
    end
end

-- Function to start editing a song by name
function charteditor.startEditing(songName)
    local songPath = songsFolder .. "/" .. songName .. "/" .. "music.mp3"
    if love.filesystem.getInfo(songPath) then
        music = love.audio.newSource(songPath, "stream")
        currentSongName = songName
        music:setLooping(false)
        songTime = 0
        isEditing = true
        print("Editing mode started for song: " .. songName)
    else
        print("Song file not found: " .. songPath)
    end
end

return charteditor
