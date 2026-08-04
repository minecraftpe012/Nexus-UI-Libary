local Library = {}
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local ScreenGui = nil
local NotifHolder = nil
local currentKeybind = Enum.KeyCode.RightShift
local isRebinding = false

local Theme = {
    WindowBackground = Color3.fromRGB(18, 18, 18),
    HeaderBackground = Color3.fromRGB(25, 25, 25),
    ElementBackground = Color3.fromRGB(28, 28, 32),
    Accent = Color3.fromRGB(220, 35, 35),
    ToggleOff = Color3.fromRGB(220, 35, 35),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(180, 180, 180),
    Border = Color3.fromRGB(40, 40, 40),
    FontBold = Enum.Font.SourceSansBold,
    FontRegular = Enum.Font.SourceSans
}

local activeConnections = {}
local windowOffsetCount = 0

local function trackConnection(connection)
    table.insert(activeConnections, connection)
    return connection
end

local function cleanupOldInstances()
    local possibleNames = {"NexusUILibrary", "PrismHub"}
    for _, parent in ipairs({CoreGui, LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")}) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("ScreenGui") and table.find(possibleNames, child.Name) then
                    child:Destroy()
                end
            end
        end
    end
end

function Library:Destroy()
    for _, conn in ipairs(activeConnections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(activeConnections)

    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end
    
    NotifHolder = nil
    windowOffsetCount = 0
    cleanupOldInstances()
end

local function initGui()
    if ScreenGui and ScreenGui.Parent then return end
    
    cleanupOldInstances()

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PrismHub"
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

    -- Toggle visibility hotkey
    trackConnection(UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or isRebinding then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode == currentKeybind then
                if ScreenGui then
                    ScreenGui.Enabled = not ScreenGui.Enabled
                end
            end
        end
    end))
end

--------------------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------------------

function Library:Notify(title, text, duration)
    if not ScreenGui or not ScreenGui.Parent then
        initGui()
    end

    title = title or "Notification"
    text = text or ""
    duration = duration or 3

    if not NotifHolder or not NotifHolder.Parent then
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
    end

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

--------------------------------------------------------------------------------
-- MULTI-WINDOW GENERATOR (`Library:AddWindow` or `Library:CreateWindow`)
--------------------------------------------------------------------------------

function Library:AddWindow(windowTitle)
    initGui()

    local spawnX = 20 + (windowOffsetCount * 175)
    windowOffsetCount = windowOffsetCount + 1

    local Window = Instance.new("Frame")
    Window.Name = windowTitle .. "Window"
    Window.Size = UDim2.new(0, 165, 0, 30)
    Window.Position = UDim2.new(0, spawnX, 0, 50)
    Window.BackgroundColor3 = Theme.WindowBackground
    Window.BorderSizePixel = 0
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 6)
    WindowCorner.Parent = Window

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 30)
    Header.BackgroundColor3 = Theme.HeaderBackground
    Header.BorderSizePixel = 0
    Header.Parent = Window

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 6)
    HeaderCorner.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -30, 1, 0)
    TitleLabel.Position = UDim2.new(0, 0, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Theme.FontBold
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Center
    TitleLabel.Parent = Header

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 20, 0, 20)
    MinimizeBtn.Position = UDim2.new(1, -22, 0.5, -10)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Font = Theme.FontBold
    MinimizeBtn.Text = "-"
    MinimizeBtn.TextColor3 = Theme.TextDim
    MinimizeBtn.TextSize = 14
    MinimizeBtn.Parent = Header

    -- Container for items
    local Container = Instance.new("Frame")
    Container.Name = "Container"
    Container.Size = UDim2.new(1, -8, 0, 0)
    Container.Position = UDim2.new(0, 4, 0, 34)
    Container.BackgroundTransparency = 1
    Container.Parent = Window

    local ContainerLayout = Instance.new("UIListLayout")
    ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ContainerLayout.Padding = UDim.new(0, 4)
    ContainerLayout.Parent = Container

    ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if Container.Visible then
            Container.Size = UDim2.new(1, -8, 0, ContainerLayout.AbsoluteContentSize.Y)
            Window.Size = UDim2.new(0, 165, 0, ContainerLayout.AbsoluteContentSize.Y + 40)
        end
    end)

    local isMinimized = false
    MinimizeBtn.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        Container.Visible = not isMinimized
        MinimizeBtn.Text = isMinimized and "+" or "-"
        Window.Size = isMinimized and UDim2.new(0, 165, 0, 30) or UDim2.new(0, 165, 0, ContainerLayout.AbsoluteContentSize.Y + 40)
    end)

    -- Dragging Logic
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

    trackConnection(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    ----------------------------------------------------------------------------
    -- WINDOW ELEMENTS
    ----------------------------------------------------------------------------

    local windowAPI = {}

    function windowAPI:AddButton(text, callback)
        callback = callback or function() end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 24)
        btn.BackgroundColor3 = Theme.ElementBackground
        btn.BorderSizePixel = 0
        btn.Font = Theme.FontRegular
        btn.Text = text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 12
        btn.Parent = Container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            task.spawn(callback)
        end)

        return btn
    end

    function windowAPI:AddToggle(text, default, callback)
        callback = callback or function() end
        local toggled = default or false

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundColor3 = Theme.ElementBackground
        btn.BorderSizePixel = 0
        btn.Font = Theme.FontRegular
        btn.Text = "  " .. text
        btn.TextColor3 = Theme.Text
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = Container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btn

        local box = Instance.new("Frame")
        box.Size = UDim2.new(0, 14, 0, 14)
        box.Position = UDim2.new(1, -18, 0.5, -7)
        box.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
        box.BorderSizePixel = 0
        box.Parent = btn

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 3)
        boxCorner.Parent = box

        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            box.BackgroundColor3 = toggled and Theme.Accent or Theme.ToggleOff
            pcall(callback, toggled)
        end)

        return btn
    end

    function windowAPI:AddSlider(text, min, max, default, callback)
        callback = callback or function() end
        min, max = min or 0, max or 100
        default = math.clamp(default or min, min, max)

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 36)
        frame.BackgroundColor3 = Theme.ElementBackground
        frame.BorderSizePixel = 0
        frame.Parent = Container

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -8, 0, 16)
        label.Position = UDim2.new(0, 4, 0, 2)
        label.BackgroundTransparency = 1
        label.Font = Theme.FontRegular
        label.Text = text .. " (" .. tostring(default) .. ")"
        label.TextColor3 = Theme.Text
        label.TextSize = 11
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -8, 0, 8)
        barBg.Position = UDim2.new(0, 4, 0, 22)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        barBg.BorderSizePixel = 0
        barBg.Parent = frame

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = barBg

        local active = false
        local function update(input)
            local pct = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            local val = math.floor((min + (max - min) * pct) * 10) / 10
            fill.Size = UDim2.new(pct, 0, 1, 0)
            label.Text = text .. " (" .. tostring(val) .. ")"
            pcall(callback, val)
        end

        barBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = true
                update(input)
            end
        end)

        trackConnection(UserInputService.InputChanged:Connect(function(input)
            if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end))

        trackConnection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                active = false
            end
        end))

        return frame
    end

    function windowAPI:AddLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Font = Theme.FontBold
        lbl.Text = text
        lbl.TextColor3 = Theme.TextDim
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Center
        lbl.Parent = Container

        return lbl
    end

    return windowAPI
end

Library.CreateWindow = Library.AddWindow

return Library
