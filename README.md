Nexus UI LibraryA modern, sleek dark-themed GUI library designed for Roblox script development. Built with a modular component architecture, automatic configuration saving, custom notifications, and multi-window dragging support.🌟 FeaturesModular Window Management: Draggable windows with collapse/expand toggles (- / +).Dark Crimson Aesthetic: Styled with dark grey panels and crimson red accent indicators.Built-in Components:Buttons: Auto-animated click feedback.Toggles: Auto-saved states with smooth color transitions.Sliders: Real-time value display with custom min/max bounds.Text Boxes: Integrated input fields.Labels: Text section headers and status displays.Notification System: Smooth slide-in toast notifications.Config Management: Automatic JSON config saving/loading (NexusUI_Config.json).Keybind Support: Customizable GUI toggle key.🚀 Quick StartAdd the following loader script to the top of your execution code:Lualocal Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/minecraftpe012/Nexus-UI-Libary/refs/heads/main/src.lua"))()
📖 API Documentation1. Library MethodsLibrary:AddWindow(titleText, defaultPosition)Creates a new main floating window.ParameterTypeDescriptiontitleTextstringHeader text displayed in the center.defaultPositionUDim2(Optional) Initial position on screen.Returns: WindowAPI object.Lualocal Window = Library:AddWindow("Main Hub", UDim2.new(0, 50, 0, 50))
Library:Notify(title, text, duration)Sends a toast notification to the bottom-right corner of the screen.ParameterTypeDescriptiontitlestringNotification title.textstringNotification message.durationnumberTime in seconds before fading out.LuaLibrary:Notify("Success", "Script loaded successfully!", 3)
Library:CreateSettingsWindow()Generates the default settings window on the right side of the screen with built-in Keybind Manager and Config Saver.LuaLibrary:CreateSettingsWindow()
2. Window Elements (WindowAPI)Window:AddButton(text, callback)Adds an interactive button.LuaWindow:AddButton("Click Me", function()
    print("Button clicked!")
end)
Window:AddToggle(text, default, callback)Adds a checkbox toggle control. States automatically save to the config file.LuaWindow:AddToggle("Auto Farm", false, function(state)
    print("Auto Farm is now:", state)
end)
Window:AddSlider(text, min, max, default, callback)Adds a progress-bar slider with real-time value updates.LuaWindow:AddSlider("WalkSpeed", 16, 100, 16, function(value)
    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
end)
Window:AddTextBox(text, defaultText, callback)Adds a text input box. The callback triggers when focus is lost or Enter is pressed.LuaWindow:AddTextBox("Target Player", "Username", function(input, enterPressed)
    print("Target set to:", input)
end)
Window:AddLabel(text)Adds a static text section label.LuaWindow:AddLabel("--- Settings Section ---")
💻 Full Example UsageLua-- Fetch Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/minecraftpe012/Nexus-UI-Libary/refs/heads/main/src.lua"))()

-- Create Window
local MainWin = Library:AddWindow("Combat Hub", UDim2.new(0, 50, 0, 50))

-- Add Elements
MainWin:AddLabel("Combat Controls")

MainWin:AddToggle("Kill Aura", false, function(state)
    print("Kill Aura:", state)
end)

MainWin:AddSlider("Aura Range", 5, 50, 15, function(val)
    print("Range:", val)
end)

MainWin:AddTextBox("Priority Target", "Player1", function(text)
    print("Targeting:", text)
end)

MainWin:AddButton("Reset Character", function()
    local char = game.Players.LocalPlayer.Character
    if char then char:BreakJoints() end
end)

-- Notify User
Library:Notify("Nexus UI", "GUI successfully initialised!", 3)
🛠️ Requirements & EnvironmentDesigned for executing platforms supporting standard Roblox Lua functions (game:HttpGet, writefile, readfile, isfile).Default UI Toggle Key: RightShift (Configurable via Settings Window).
