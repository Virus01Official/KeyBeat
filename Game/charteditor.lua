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
local svValue = 1.0 -- Default scroll velocity for notes
local lastSVValue = 1.0 -- Track the last SV to optimize saving
local songsFolder = "songs"
local hitLineY = 500
local currentSongName = nil
local songNameInput = "" -- Text input for song name
local isEnteringSongName = true -- Controls if user is in text input mode
local capsLockEnabled = false

function charteditor.load()
    noteSpeed = settings.getNoteSpeed()
    noteSize = settings.getNoteSize()
end

function charteditor.loadChart(filename)
    chart = {}
    local file = love.filesystem.read(filename)
    if file then
        svValue = 1.0 -- Reset to default SV at the start of each load
        for line in file:gmatch("[^\r\n]+") do
            if line:match("^SV") then
                -- Handle SV line
                svValue = tonumber(line:match("SV ([%d%.]+)")) or 1.0
            else
                -- Handle regular note line
                local time, x, holdTime = line:match("([%d%.]+) ([%d%.]+) ([%d%.]+)")
                if time and x and holdTime then
                    holdTime = tonumber(holdTime) -- Convert holdTime to a number
                    table.insert(chart, {time = tonumber(time), x = tonumber(x), hold = holdTime > 0, holdTime = holdTime, sv = svValue})
                end
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
    lastSVValue = 1.0 -- Reset to default SV for comparison
    for _, note in ipairs(chart) do
        if note.sv ~= lastSVValue then
            -- Add an SV line whenever the SV changes
            table.insert(chartData, string.format("SV %f", note.sv))
            lastSVValue = note.sv
        end
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
    love.graphics.print("Scroll Velocity (SV): " .. svValue, 10, 50)
    love.graphics.print("Press '[' or ']' to adjust SV", 10, 70)
    love.graphics.print("Press 'P' to play/pause preview", 10, 90)
    love.graphics.print("Press Left/Right Arrow to scroll the chart", 10, 110)  -- Added scroll instructions
    love.graphics.line(0, hitLineY, love.graphics.getWidth(), hitLineY)

    if isEnteringSongName then
        love.graphics.print("Enter Song Name: " .. songNameInput, 10, 130)
        love.graphics.print("Press Enter to confirm song name", 10, 150)
    else
        for i, note in ipairs(chart) do
            local y = hitLineY - (note.time - songTime) * noteSpeed * note.sv
            if note.hold then
                love.graphics.setColor(0, 1, 0)
                love.graphics.rectangle("fill", note.x, y, noteSize, noteSize + note.holdTime * noteSpeed * note.sv)
            else
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", note.x, y, noteSize, noteSize)
            end
        end
    end
    love.graphics.setColor(1, 1, 1)
end

function charteditor.placeNote(x, y)
    local time = songTime + (hitLineY - y) / (noteSpeed * svValue)
    if notePlacementMode == "normal" then
        table.insert(chart, {time = time, x = x, hold = false, holdTime = 0, sv = svValue})
    elseif notePlacementMode == "hold" then
        table.insert(chart, {time = time, x = x, hold = true, holdTime = 1.0, sv = svValue})
    end
end

function charteditor.removeNoteAt(x, y)
    for i = #chart, 1, -1 do
        local note = chart[i]
        local noteY = hitLineY - (note.time - songTime) * noteSpeed * note.sv
        if x >= note.x and x <= note.x + noteSize and y >= noteY and y <= noteY + noteSize then
            table.remove(chart, i)
            break
        end
    end
end

function charteditor.keypressed(key)
    if key == "escape" then
        -- Stop editing and return to menu
        isEditing = false
        isEnteringSongName = true
        if music then
            music:stop() -- Stop any music that might be playing
        end
        backToMenu()
    end

    if isEnteringSongName then
        if key == "return" then
            charteditor.startEditing(songNameInput)
            isEnteringSongName = false
            songNameInput = ""
        elseif key == "backspace" then
            songNameInput = songNameInput:sub(1, -2)
        elseif key == "capslock" then
            -- Toggle Caps Lock state
            capsLockEnabled = not capsLockEnabled
        elseif key == "space" then
            songNameInput = songNameInput .. " " 
        elseif #key == 1 then
            -- Add character, adjusting case based on Caps Lock
            if capsLockEnabled then
                songNameInput = songNameInput .. key:upper()
            else
                songNameInput = songNameInput .. key
            end
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
        elseif key == "[" then
            svValue = math.max(0, svValue - 0.1) -- Decrease SV
        elseif key == "]" then
            svValue = math.min(1.0, svValue + 0.1) -- Increase SV
        elseif key == "left" then
            songTime = math.max(0, songTime - 1)  -- Decrease song time to scroll left
            charteditor.updateMusicPosition()
        elseif key == "right" then
            songTime = songTime + 1  -- Increase song time to scroll right
            charteditor.updateMusicPosition()
        end
    end
end

function charteditor.updateMusicPosition()
    if music then
        local wasPlaying = music:isPlaying()
        music:pause()  -- Pause music to safely adjust position
        music:seek(songTime)  -- Set music playback to match songTime
        if wasPlaying then
            music:play()  -- Resume playback if it was already playing
        end
        musicStartTime = love.timer.getTime() - songTime  -- Adjust start time reference
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
    local songPath = songsFolder .. "/" .. songName .. "/music.mp3"
    local songPathOgg = songsFolder .. "/" .. songName .. "/music.ogg"
    local chartPath = songsFolder .. "/" .. songName .. "/chart.txt"
    if love.filesystem.getInfo(songPath) then
        music = love.audio.newSource(songPath, "stream")
        currentSongName = songName
        music:setLooping(false)
        songTime = 0
        isEditing = true
        print("Editing mode started for song: " .. songName)
    elseif love.filesystem.getInfo(songPathOgg) then
        music = love.audio.newSource(songPath, "stream")
        currentSongName = songName
        music:setLooping(false)
        songTime = 0
        isEditing = true
        print("Editing mode started for song: " .. songName)
    else
        print("Song file not found: " .. songPath)
    end

    if love.filesystem.getInfo(chartPath) then
        -- Load Chart UwU
        charteditor.loadChart(chartPath)
    else
        print("Chart not found")
    end
end

return charteditor
