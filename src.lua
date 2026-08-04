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

-- Configuration and Theme State
local togglesRegistry = {}
local activeTogglesList = {}
local currentAccent = Color3.fromRGB(0, 200, 80)
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

-- Forward declaration
local createSettingsWindow

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
            if input.KeyCode == currentKeybind and not gameProcessed then
                if ScreenGui then
                    ScreenGui.Enabled = not ScreenGui.Enabled
                end
            end
        end)
    end

    -- Automatically spawn settings window on the right side if not already created
    task.spawn(function()
        task.wait(0.05)
        if not settingsWindowInstance then
            Library:CreateSettingsWindow()
        end
    end)
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
    notif.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    notif.BorderColor3 = Color3.fromRGB(50, 50, 50)
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
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = notif

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 0, 24)
    textLabel.Position = UDim2.new(0, 10, 0, 26)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.SourceSans
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
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

    local Window = Instance.new("Frame")
    Window.Name = titleText .. "Window"
    Window.Size = UDim2.new(0, 220, 0, 380)
    Window.Position = defaultPosition or UDim2.new(0, 50, 0, 50)
    Window.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Window.BorderSizePixel = 1
    Window.BorderColor3 = Color3.fromRGB(45, 45, 45)
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 6)
    WindowCorner.Parent = Window

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Header.BorderSizePixel = 0
    Header.Parent = Window

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 6)
    HeaderCorner.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -36, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.SourceSansBold
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local CollapseBtn = Instance.new("TextButton")
    CollapseBtn.Size = UDim2.new(0, 22, 0, 22)
    CollapseBtn.AnchorPoint = Vector2.new(1, 0.5)
    CollapseBtn.Position = UDim2.new(1, -6, 0.5, 0)
    CollapseBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    CollapseBtn.BorderSizePixel = 1
    CollapseBtn.BorderColor3 = Color3.fromRGB(55, 55, 55)
    CollapseBtn.Font = Enum.Font.SourceSansBold
    CollapseBtn.Text = "-"
    CollapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CollapseBtn.TextSize = 14
    CollapseBtn.Parent = Header

    local CollapseCorner = Instance.new("UICorner")
    CollapseCorner.CornerRadius = UDim.new(0, 4)
    CollapseCorner.Parent = CollapseBtn

    local Container = Instance.new("ScrollingFrame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -10, 1, -36)
    Container.Position = UDim2.new(0, 5, 0, 32)
    Container.BackgroundTransparency = 1
    Container.BorderSizePixel = 0
    Container.CanvasSize = UDim2.new(0, 0, 0, 0)
    Container.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Container.ScrollBarThickness = 3
    Container.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)
    Container.Parent = Window

    local Layout = Instance.new("UIListLayout")
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 4)
    Layout.Parent = Container

    local collapsed = false
    local fullHeight = UDim2.new(0, 220, 0, 380)
    local collapsedHeight = UDim2.new(0, 220, 0, 30)

    CollapseBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        Container.Visible = not collapsed
        CollapseBtn.Text = collapsed and "+" or "-"
        if collapsed then
            Window.Size = collapsedHeight
        else
            Window.Size = fullHeight
        end
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
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(45, 45, 45)
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.SourceSans
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.TextSize = 13
        btn.Parent = Container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            task.spawn(callback)
            TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(45, 45, 45)}):Play()
            task.wait(0.12)
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
        end)
        return btn
    end

    function windowAPI:AddToggle(text, default, callback)
        callback = callback or function() end
        local savedVal = savedConfigData[text]
        local toggled = (savedVal ~= nil) and savedVal or (default or false)
        
        togglesRegistry[text] = toggled

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(45, 45, 45)
        btn.AutoButtonColor = false
        btn.Font = Enum.Font.SourceSans
        btn.Text = "  " .. text
        btn.TextColor3 = Color3.fromRGB(220, 220, 220)
        btn.TextSize = 13
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = Container

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        local checkbox = Instance.new("Frame")
        checkbox.Size = UDim2.new(0, 16, 0, 16)
        checkbox.Position = UDim2.new(1, -22, 0.5, -8)
        checkbox.BorderSizePixel = 1
        checkbox.Parent = btn

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 3)
        boxCorner.Parent = checkbox

        local function updateVisuals(tweenTime)
            local targetColor = toggled and currentAccent or Color3.fromRGB(35, 35, 35)
            local targetBorder = toggled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
            TweenService:Create(checkbox, TweenInfo.new(tweenTime or 0.15), {
                BackgroundColor3 = targetColor,
                BorderColor3 = targetBorder
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

        return btn
    end

    function windowAPI:AddLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 24)
        lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.SourceSansBold
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(160, 160, 160)
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = Container
        return lbl
    end

    return windowAPI
end

function Library:CreateSettingsWindow()
    if settingsWindowInstance and settingsWindowInstance.Parent then return settingsWindowInstance end

    -- Position automatically on the right side of the screen
    local SettingsWin = self:AddWindow("Settings", UDim2.new(1, -230, 0, 50), "NexusUILibrary", currentKeybind)

    SettingsWin:AddLabel("UI Configuration")

    SettingsWin:AddToggle("RGB Theme", false, function(state)
        rgbEnabled = state
        if rgbEnabled then
            rgbConnection = RunService.RenderStepped:Connect(function()
                local hue = tick() % 5 / 5
                currentAccent = Color3.fromHSV(hue, 1, 1)
                for _, item in ipairs(activeTogglesList) do
                    if item.frame and item.frame.Parent and item.getToggled() then
                        item.frame.BackgroundColor3 = currentAccent
                    end
                end
            end)
        else
            if rgbConnection then
                rgbConnection:Disconnect()
                rgbConnection = nil
            end
            currentAccent = Color3.fromRGB(0, 200, 80)
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
        self:Notify("Keybind", "Press any keyboard key...", 3)
        local connection
        connection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKeybind = input.KeyCode
                bindBtn.Text = "Toggle Key: " .. tostring(currentKeybind.Name)
                self:Notify("Keybind", "Toggle key updated to " .. tostring(currentKeybind.Name), 3)
                connection:Disconnect()
            end
        end)
    end)

    settingsWindowInstance = SettingsWin
    return SettingsWin
end

return Library
