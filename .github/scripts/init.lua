-- Hammerspoon Menu Selection Script
-- Creates a menu for selecting analysis types
local menuChoices = {
    {
        text = "Technical Analysis",
        subText = "Formatting, structure, grammar",
        value = "technical"
    }, {
        text = "Philosophical Analysis",
        subText = "Themes, paradox, meaning",
        value = "philosophical"
    }, {
        text = "Comprehensive Analysis",
        subText = "All categories combined",
        value = "comprehensive"
    }
}

-- Function to show the selection menu
function showAnalysisMenu()
    local chooser = hs.chooser.new(function(choice)
        if choice then
            -- Generate the selected prompt
            local script = string.format(
                               'cd "%s/.github/scripts" && ./generate-prompt.sh %s show-examples',
                               hs.fs.currentDir(), choice.value)

            -- Execute the script
            hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
                if exitCode == 0 then
                    hs.notify.new({
                        title = "Prompt Generated",
                        informativeText = string.format("%s prompt is ready",
                                                        choice.text),
                        autoWithdraw = true,
                        withdrawAfter = 3
                    }):send()
                else
                    hs.notify.new({
                        title = "Error",
                        informativeText = "Failed to generate prompt",
                        autoWithdraw = true,
                        withdrawAfter = 5
                    }):send()
                end
            end, {"-c", script}):start()
        end
    end)

    chooser:choices(menuChoices)
    chooser:placeholderText("Select analysis type...")
    chooser:searchSubText(true)
    chooser:show()
end

-- Bind to a hotkey (Cmd+Shift+A for Analysis)
hs.hotkey.bind({"cmd", "shift"}, "a", showAnalysisMenu)

-- Alternative: Create a menu bar item
local menubar = hs.menubar.new()
if menubar then
    menubar:setTitle("📝")
    menubar:setTooltip("Analysis Menu")
    menubar:setMenu({
        {
            title = "Technical Analysis",
            fn = function()
                local script = string.format(
                                   'cd "%s/.github/scripts" && ./generate-prompt.sh technical show-examples',
                                   hs.fs.currentDir())
                hs.task.new("/bin/bash", nil, {"-c", script}):start()
                hs.notify.new({
                    title = "Technical Analysis",
                    informativeText = "Prompt generated"
                }):send()
            end
        }, {
            title = "Philosophical Analysis",
            fn = function()
                local script = string.format(
                                   'cd "%s/.github/scripts" && ./generate-prompt.sh philosophical show-examples',
                                   hs.fs.currentDir())
                hs.task.new("/bin/bash", nil, {"-c", script}):start()
                hs.notify.new({
                    title = "Philosophical Analysis",
                    informativeText = "Prompt generated"
                }):send()
            end
        }, {
            title = "Comprehensive Analysis",
            fn = function()
                local script = string.format(
                                   'cd "%s/.github/scripts" && ./generate-prompt.sh comprehensive show-examples',
                                   hs.fs.currentDir())
                hs.task.new("/bin/bash", nil, {"-c", script}):start()
                hs.notify.new({
                    title = "Comprehensive Analysis",
                    informativeText = "Prompt generated"
                }):send()
            end
        }, {
            title = "-" -- Separator
        }, {title = "Show Chooser Menu", fn = showAnalysisMenu}
    })
end

-- Function to get the current working directory (you may need to adjust this)
function getCurrentWorkspaceDir()
    -- Try to get VS Code workspace directory
    -- This is a simplified approach - you might need to customize based on your setup
    return
        "/Users/donaldmoore/reading/Illusion, Insight, and the Vanishing Garden"
end

print("Analysis menu loaded! Use Cmd+Shift+A or click the 📝 menu bar item.")
