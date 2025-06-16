local joining = {}
local settings = require("settings")
local PPandToS = "https://moonwave-website.vercel.app/terms.html"

local function getTranslation(key)
    return settings.getTranslation(key)
end

local linkX, linkY = love.graphics.getWidth() - 550, 150
local linkText = "Our Terms of Service and Privacy Policy"
local linkWidth, linkHeight = 0, 0

-- Persistent flag to check if the user has accepted the terms
local hasAcceptedTerms = false

function joining.load()
    -- Load the acceptance flag from persistent storage
    hasAcceptedTerms = love.filesystem.getInfo("terms_accepted") ~= nil

    -- Measure the text width and height for the link
    linkWidth = love.graphics.getFont():getWidth(linkText)
    linkHeight = love.graphics.getFont():getHeight()
end

function joining.update(dt)

end

function joining.draw()
    if not hasAcceptedTerms then
        love.graphics.print(getTranslation("Agree before playing!"), love.graphics.getWidth() - 800, 0)
        love.graphics.print(getTranslation("Do you agree to our Terms of Service and Privacy Policy?"), love.graphics.getWidth() - 1000, 100)
        love.graphics.setColor(0,0,1)
        love.graphics.print(linkText, linkX, linkY)
        love.graphics.setColor(1,1,1)
        -- Buttons
        love.graphics.print(getTranslation("Yes"), love.graphics.getWidth() - 800, 200)
        love.graphics.print(getTranslation("No"), love.graphics.getWidth() - 600, 200)
    else
        -- Draw the main menu or other content here
    end
end

function joining.mousepressed(x, y, button)
    if button == 1 then
        -- Check if the click was within the link's bounding box
        if x >= linkX and x <= linkX + linkWidth and y >= linkY and y <= linkY + linkHeight then
            love.system.openURL(PPandToS)
        else
            -- Check for Yes button click
            if x >= love.graphics.getWidth() - 800 and x <= love.graphics.getWidth() - 800 + love.graphics.getFont():getWidth(getTranslation("Yes")) and y >= 200 and y <= 200 + love.graphics.getFont():getHeight() then
                hasAcceptedTerms = true
                -- Save the acceptance flag to persistent storage
                love.filesystem.write("terms_accepted", "true")
                backToMenu()
            -- Check for No button click
            elseif x >= love.graphics.getWidth() - 600 and x <= love.graphics.getWidth() - 600 + love.graphics.getFont():getWidth(getTranslation("No")) and y >= 200 and y <= 200 + love.graphics.getFont():getHeight() then
                love.event.quit()
            end
        end
    end
end

return joining
