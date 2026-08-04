local Library = {}
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local ScreenGui = nil
local NotifHolder = nil
local isConnected = false
local currentKeybind = Enum.KeyCode.RightShift
local isRebinding = false

local windowCount = 0
local WINDOW_WIDTH = 220
local WINDOW_PADDING = 12
local START_X = 20
local START_Y = 50

local Theme = {
    WindowBackground = Color3.fromRGB(16, 16, 18),
    HeaderBackground = Color3.fromRGB(16, 16, 18),
    ElementBackground = Color3.fromRGB(26, 26, 30),
    Accent = Color3.fromRGB(220, 35, 35),
    ToggleOff = Color3.fromRGB(40, 40, 45),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(35, 35, 40),
    FontBold = Enum.Font.SourceSansBold,
    FontRegular = Enum.Font.SourceSans
}

local togglesRegistry = {}
local activeTogglesList = {}
local rgbEnabled = false
local rgbConnection = nil
local settingsWindowInstance = nil

local CONFIG_FILE = "NexusUI_Config.json"

local function saveConfig()
    local saveData = {}
    for name, state in pairs(togglesRegistry) do
        saveData[name] = state
    end
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(saveData)
    end)
    if success and writefile then
        pcall(function()
            writefile(CONFIG_FILE, encoded)
        end)
    end
end

local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(decoded) == "table" then
            return decoded
        end
    end
    return {}
end

local savedConfigData = loadConfig()

local function cleanupOldInstances()
    local possibleNames = {"NexusUILibrary", "PepsiSwarm", "PepsiSwarmGUI"}
    for _, parent in ipairs({CoreGui, LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")}) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") then
                    for _, name in ipairs(possibleNames) do
                        if child.Name == name then
                            child:Destroy()
                        end
                    end
                end
            end
        end
    end
end

local function initGui(hubName, toggleKey)
    local guiName = hubName or "NexusUILibrary"
    currentKeybind = toggleKey or currentKeybind
    
    cleanupOldInstances()

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ResetOnSpawn = false

    local success = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
        end
        ScreenGui.Parent = CoreGui
    end)

    if not success or ScreenGui.Parent ~= CoreGui then
        pcall(function()
            ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end)
    end

    NotifHolder = Instance.new("Frame")
    NotifHolder.Name = "NotificationHolder"
    NotifHolder.Size = UDim2.new(0, 240, 1, -40)
    NotifHolder.Position = UDim2.new(1, -260, 0, 20)
    NotifHolder.BackgroundTransparency = 1
    NotifHolder.Parent = ScreenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 6)
    layout.Parent = NotifHolder

    if not isConnected then
        isConnected = true
        UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or isRebinding then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == currentKeybind then
                    if ScreenGui then
                        ScreenGui.Enabled = not ScreenGui.Enabled
                    end
                end
            end
        end)
    end
end

function Library:Notify(title, text, duration)
    if not ScreenGui or not ScreenGui.Parent or not NotifHolder or not NotifHolder.Parent then
        initGui("NexusUILibrary", currentKeybind)
    end

    title = title or "Notification"
    text = text or ""
    duration = duration or 3

    local notif = Instance.new("Frame")
    notif.Size = UDim2.new(1, 0, 0, 56)
    notif.BackgroundColor3 = Theme.WindowBackground
    notif.BorderColor3 = Theme.Border
    notif.BorderSizePixel = 1
    notif.BackgroundTransparency = 1
    notif.Parent = NotifHolder

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notif

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 20)
    titleLabel.Position = UDim2.new(0, 10, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Theme.FontBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Theme.Text
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0, 24)
    textLabel.Position = UDim2.new(0, 10, 0, 26)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Theme.FontRegular
    textLabel.Text = text
    textLabel.TextColor3 = Theme.TextDim
    textLabel.TextSize = 12
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextWrapped = true
    textLabel.Parent = notif

    TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()

    task.delay(duration, function()
        if notif and notif.Parent then
            local tween = TweenService:Create(notif, TweenInfo.new(0.2), {BackgroundTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function()
                notif:Destroy()
            end)
        end
    end)
end

function Library:AddWindow(titleText, defaultPosition, hubName, toggleKey)
    if not ScreenGui then
        initGui(hubName, toggleKey)
    end

    if not defaultPosition then
        local xOffset = START_X + (windowCount * (WINDOW_WIDTH + WINDOW_PADDING))
        defaultPosition = UDim2.new(0, xOffset, 0, START_Y)
    end
    windowCount = windowCount + 1

    local Window = Instance.new("Frame")
    Window.Name = titleText .. "Window"
    Window.Size = UDim2.new(0, WINDOW_WIDTH, 0, 46)
    Window.Position = defaultPosition
    Window.BackgroundColor3 = Theme.WindowBackground
    Window.BorderSizePixel = 0
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 8)
    WindowCorner.Parent = Window

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundColor3 = Theme.HeaderBackground
    Header.BorderSizePixel = 0
    Header.Parent = Window

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -40, 1, 0)
    TitleLabel.Position = UDim2.new(0, 20, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Theme.FontBold
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 16
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.Parent = Header

    local CollapseBtn = Instance.new("TextButton")
    CollapseBtn.Size = UDim2.new(0, 24, 0, 24)
    CollapseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CollapseBtn.Position = UDim2.new(1, -10, 0.5, 0)
    CollapseBtn.BackgroundTransparency = 1
    CollapseBtn.Font = Theme.FontBold
    CollapseBtn.Text = "-"
    CollapseBtn.TextColor3 = Theme.Text
    CollapseBtn.TextSize = 18
    CollapseBtn.Parent = Header

    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -12, 0, 0)
    Container.Position = UDim2.new(0, 6, 0, 38)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.Parent = Window

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 5)
    Layout.Parent = Container

    local collapsed = false

    local function updateWindowSize()
        if collapsed then
            Window.Size = UDim2.new(0, WINDOW_WIDTH, 0, 36)
        else
            local totalHeight = 0
            for _, child in ipairs(Container:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    totalHeight = totalHeight + child.Size.Y.Offset + Layout.Padding.Offset
                end
            end
            Window.Size = UDim2.new(0, WINDOW_WIDTH, 0, 36 + 10 + totalHeight)
        end
    end

    CollapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        Container.Visible = not collapsed
        CollapseBtn.Text = collapsed and "+" or "-"
        updateWindowSize()
    end)

    local dragging, dragInput, dragStart, startPos
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local windowAPI = {}

    function windowAPI:Notify(title, text, duration)
        Library:Notify(title, text, duration)
    end

    function windowAPI:AddButton(text, callback)
        callback = callback or function() end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.BackgroundColor3 = Theme.ElementBackground
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Theme.FontBold
        btn.Text = text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 13
        btn.Parent = Container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            task.spawn(callback)
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
            task.wait(0.12)
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.ElementBackground}):Play()
        end)

        updateWindowSize()
        return btn
    end

    function windowAPI:AddToggle(text, default, callback)
        callback = callback or function() end
        local savedVal = savedConfigData[text]
        local toggled = (savedVal ~= nil) and savedVal or (default or false)
        
        togglesRegistry[text] = toggled

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = Theme.ElementBackground
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = false
        btn.Font = Theme.FontBold
        btn.Text = "  " .. text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = Container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 5)
        btnCorner.Parent = btn

        local checkbox = Instance.new("Frame")
        checkbox.Size = UDim2.new(0, 16, 0, 16)
        checkbox.Position = UDim2.new(1, -22, 0.5, -8)
        checkbox.BorderSizePixel = 0
        checkbox.Parent = btn

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 3)
        boxCorner.Parent = checkbox

        local function updateVisuals(tweenTime)
            local targetColor = toggled and Theme.Accent or Theme.ToggleOff
            TweenService:Create(checkbox, TweenInfo.new(tweenTime or 0.15), {
                BackgroundColor3 = targetColor
            }):Play()
        end

        table.insert(activeTogglesList, {
            frame = checkbox,
            getToggled = function() return toggled end,
            update = updateVisuals
        })

        updateVisuals(0)
        if toggled then
            task.spawn(function()
                pcall(callback, toggled)
            end)
        end

        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            togglesRegistry[text] = toggled
            updateVisuals(0.15)
            pcall(callback, toggled)
            saveConfig()
        end)

        updateWindowSize()
        return btn
    end

    function windowAPI:AddSlider(text, min, max, default, callback)
        callback = callback or function() end
        min = min or 0
        max = max or 100
        default = math.clamp(default or min, min, max)

        local sliderFrame = Instance.new("Frame")
        sliderFrame.Size = UDim2.new(1, 0, 0, 42)
        sliderFrame.BackgroundColor3 = Theme.ElementBackground
        sliderFrame.BorderSizePixel = 0
        sliderFrame.Parent = Container

        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 5)
        sliderCorner.Parent = sliderFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.7, 0, 0, 20)
        label.Position = UDim2.new(0, 8, 0, 2)
        label.BackgroundTransparency = 1
        label.Font = Theme.FontBold
        label.Text = text
        label.TextColor3 = Theme.Text
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = sliderFrame

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Size = UDim2.new(0.3, -8, 0, 20)
        valueLabel.Position = UDim2.new(0.7, 0, 0, 2)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Font = Theme.FontBold
        valueLabel.Text = tostring(default)
        valueLabel.TextColor3 = Theme.Text
        valueLabel.TextSize = 13
        valueLabel.TextXAlignment = Enum.TextXAlignment.Right
        valueLabel.Parent = sliderFrame

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -16, 0, 10)
        barBg.Position = UDim2.new(0, 8, 0, 24)
        barBg.BackgroundColor3 = Theme.ToggleOff
        barBg.BorderSizePixel = 0
        barBg.Parent = sliderFrame

        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 3)
        barCorner.Parent = barBg

        local fillBar = Instance.new("Frame")
        fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fillBar.BackgroundColor3 = Theme.Accent
        fillBar.BorderSizePixel = 0
        fillBar.Parent = barBg

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = fillBar

        local sliderActive = false

        local function updateSlider(input)
            local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            local val = math.floor((min + (max - min) * pct) * 10) / 10
            fillBar.Size = UDim2.new(pct, 0, 1, 0)
            valueLabel.Text = tostring(val)
            pcall(callback, val)
        end

        barBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliderActive = true
                updateSlider(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliderActive = false
            end
        end)

        updateWindowSize()
        return sliderFrame
    end

    function windowAPI:AddTextBox(text, defaultText, callback)
        callback = callback or function() end

        local boxFrame = Instance.new("Frame")
        boxFrame.Size = UDim2.new(1, 0, 0, 32)
        boxFrame.BackgroundColor3 = Theme.ElementBackground
        boxFrame.BorderSizePixel = 0
        boxFrame.Parent = Container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = boxFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.55, 0, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Font = Theme.FontBold
        label.Text = text
        label.TextColor3 = Theme.Text
        label.TextSize = 13
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = boxFrame

        local textBox = Instance.new("TextBox")
        textBox.Size = UDim2.new(0.4, -6, 0, 22)
        textBox.Position = UDim2.new(0.6, 0, 0.5, -11)
        textBox.BackgroundColor3 = Theme.ToggleOff
        textBox.BorderSizePixel = 0
        textBox.Font = Theme.FontBold
        textBox.Text = defaultText or ""
        textBox.TextColor3 = Theme.Text
        textBox.TextSize = 12
        textBox.Parent = boxFrame

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = textBox

        textBox.FocusLost:Connect(function(enterPressed)
            pcall(callback, textBox.Text, enterPressed)
        end)

        updateWindowSize()
        return boxFrame
    end

    function windowAPI:AddLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 22)
        lbl.BackgroundTransparency = 1
        lbl.Font = Theme.FontBold
        lbl.Text = text
        lbl.TextColor3 = Theme.TextDim
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = Container

        updateWindowSize()
        return lbl
    end

    return windowAPI
end

function Library:CreateSettingsWindow()
    if settingsWindowInstance and settingsWindowInstance.Parent then return settingsWindowInstance end

    local SettingsWin = self:AddWindow("Settings", nil, "NexusUILibrary", currentKeybind)

    SettingsWin:AddLabel("UI Configuration")

    SettingsWin:AddToggle("RGB Theme", false, function(state)
        rgbEnabled = state
        if rgbEnabled then
            rgbConnection = RunService.RenderStepped:Connect(function()
                local hue = tick() % 5 / 5
                Theme.Accent = Color3.fromHSV(hue, 0.9, 1)
                for _, item in ipairs(activeTogglesList) do
                    if item.frame and item.frame.Parent and item.getToggled() then
                        item.frame.BackgroundColor3 = Theme.Accent
                    end
                end
            end)
        else
            if rgbConnection then
                rgbConnection:Disconnect()
                rgbConnection = nil
            end
            Theme.Accent = Color3.fromRGB(220, 35, 35)
            for _, item in ipairs(activeTogglesList) do
                if item.frame and item.frame.Parent then
                    item.update(0.15)
                end
            end
        end
    end)

    SettingsWin:AddButton("Save Config File", function()
        saveConfig()
        self:Notify("Settings", "Configuration saved to file!", 3)
    end)

    SettingsWin:AddLabel("Keybind Manager")

    local bindBtn = SettingsWin:AddButton("Toggle Key: " .. tostring(currentKeybind.Name), function()
        if isRebinding then return end
        isRebinding = true
        self:Notify("Keybind", "Press any key...", 2)

        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKeybind = input.KeyCode
                bindBtn.Text = "Toggle Key: " .. tostring(currentKeybind.Name)
                self:Notify("Keybind", "Key set to " .. tostring(currentKeybind.Name), 2)
                connection:Disconnect()
                task.delay(0.2, function()
                    isRebinding = false
                end)
            end
        end)
    end)

    settingsWindowInstance = SettingsWin
    return SettingsWin
end

return Library
