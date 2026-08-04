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
    WindowBackground = Color3.fromRGB(16, 16, 18),
    HeaderBackground = Color3.fromRGB(22, 22, 26),
    TabBackground = Color3.fromRGB(24, 24, 28),
    TabSelected = Color3.fromRGB(35, 35, 42),
    ElementBackground = Color3.fromRGB(28, 28, 34),
    Accent = Color3.fromRGB(220, 35, 35),
    ToggleOff = Color3.fromRGB(45, 45, 52),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(170, 170, 170),
    Border = Color3.fromRGB(38, 38, 45),
    FontBold = Enum.Font.SourceSansBold,
    FontRegular = Enum.Font.SourceSans
}

local togglesRegistry = {}
local slidersRegistry = {}
local textboxesRegistry = {}
local windowPosition = nil

local activeTogglesList = {}
local activeConnections = {}
local rgbEnabled = false
local rgbConnection = nil
local CONFIG_FILE = "NexusUI_Config.json"

local function trackConnection(connection)
    table.insert(activeConnections, connection)
    return connection
end

--------------------------------------------------------------------------------
-- CONFIG MANAGEMENT & POSITION SANITIZER
--------------------------------------------------------------------------------

local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if success and type(decoded) == "table" then
            return {
                Toggles = type(decoded.Toggles) == "table" and decoded.Toggles or {},
                Sliders = type(decoded.Sliders) == "table" and decoded.Sliders or {},
                TextBoxes = type(decoded.TextBoxes) == "table" and decoded.TextBoxes or {},
                Keybind = decoded.Keybind,
                WindowPos = decoded.WindowPos
            }
        end
    end
    return { Toggles = {}, Sliders = {}, TextBoxes = {} }
end

local savedConfigData = loadConfig()

if savedConfigData.Keybind and Enum.KeyCode[savedConfigData.Keybind] then
    currentKeybind = Enum.KeyCode[savedConfigData.Keybind]
end

local function getValidWindowPos(posData)
    if type(posData) == "table" then
        local xs = tonumber(posData.XScale) or 0.5
        local xo = tonumber(posData.XOffset) or -240
        local ys = tonumber(posData.YScale) or 0.5
        local yo = tonumber(posData.YOffset) or -160
        if xs >= 0 and xs <= 1 and ys >= 0 and ys <= 1 then
            return UDim2.new(xs, xo, ys, yo)
        end
    end
    return UDim2.new(0.5, -240, 0.5, -160)
end

function Library:SaveConfig()
    local saveData = {
        Toggles = togglesRegistry,
        Sliders = slidersRegistry,
        TextBoxes = textboxesRegistry,
        Keybind = currentKeybind and currentKeybind.Name or "RightShift",
        WindowPos = windowPosition
    }
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(saveData)
    end)
    if success and writefile then
        pcall(function()
            writefile(CONFIG_FILE, encoded)
        end)
    end
end

--------------------------------------------------------------------------------
-- CLEANUP & DESTROY
--------------------------------------------------------------------------------

local function cleanupOldInstances()
    local possibleNames = {"NexusUILibrary", "PepsiSwarm", "PepsiSwarmGUI"}
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

    if rgbConnection then
        rgbConnection:Disconnect()
        rgbConnection = nil
    end

    if ScreenGui then
        ScreenGui:Destroy()
        ScreenGui = nil
    end

    togglesRegistry = {}
    slidersRegistry = {}
    textboxesRegistry = {}
    activeTogglesList = {}
    cleanupOldInstances()
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function initGui(hubName, toggleKey)
    local guiName = hubName or "NexusUILibrary"
    currentKeybind = toggleKey or currentKeybind
    
    Library:Destroy()

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = guiName
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
    NotifHolder.ZIndex = 100
    NotifHolder.Parent = ScreenGui

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 6)
    layout.Parent = NotifHolder

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
    notif.ZIndex = 101
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
    titleLabel.ZIndex = 102
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
    textLabel.ZIndex = 102
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
-- WINDOW & TAB CREATION
--------------------------------------------------------------------------------

function Library:CreateWindow(titleText, hubName, toggleKey)
    if not ScreenGui then
        initGui(hubName, toggleKey)
    end

    local Window = Instance.new("Frame")
    Window.Name = titleText .. "Window"
    Window.Size = UDim2.new(0, 480, 0, 320)
    Window.Position = getValidWindowPos(savedConfigData.WindowPos)
    Window.BackgroundColor3 = Theme.WindowBackground
    Window.BorderSizePixel = 0
    Window.ZIndex = 1
    Window.Parent = ScreenGui

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 8)
    WindowCorner.Parent = Window

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 36)
    Header.BackgroundColor3 = Theme.HeaderBackground
    Header.BorderSizePixel = 0
    Header.ZIndex = 2
    Header.Parent = Window

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -70, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Theme.FontBold
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextSize = 15
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 3
    TitleLabel.Parent = Header

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 24, 0, 24)
    CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Font = Theme.FontBold
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Theme.Accent
    CloseBtn.TextSize = 14
    CloseBtn.ZIndex = 3
    CloseBtn.Parent = Header

    CloseBtn.MouseButton1Click:Connect(function()
        Library:Destroy()
    end)

    -- Tab Bar (Scrollable Horizontal Container)
    local TabBar = Instance.new("ScrollingFrame")
    TabBar.Name = "TabBar"
    TabBar.Size = UDim2.new(1, -16, 0, 28)
    TabBar.Position = UDim2.new(0, 8, 0, 42)
    TabBar.BackgroundTransparency = 1
    TabBar.BorderSizePixel = 0
    TabBar.ScrollBarThickness = 0
    TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabBar.ZIndex = 2
    TabBar.Parent = Window

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.Parent = TabBar

    -- Content Container
    local ContentHolder = Instance.new("Frame")
    ContentHolder.Name = "ContentHolder"
    ContentHolder.Size = UDim2.new(1, -16, 1, -80)
    ContentHolder.Position = UDim2.new(0, 8, 0, 74)
    ContentHolder.BackgroundTransparency = 1
    ContentHolder.ClipsDescendants = true
    ContentHolder.ZIndex = 2
    ContentHolder.Parent = Window

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
                    windowPosition = {
                        XScale = Window.Position.X.Scale,
                        XOffset = Window.Position.X.Offset,
                        YScale = Window.Position.Y.Scale,
                        YOffset = Window.Position.Y.Offset
                    }
                    Library:SaveConfig()
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
    -- TAB MANAGEMENT API
    ----------------------------------------------------------------------------

    local windowAPI = {
        Tabs = {},
        ActiveTab = nil
    }

    function windowAPI:CreateTab(tabName)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0, 95, 1, 0)
        tabBtn.BackgroundColor3 = Theme.TabBackground
        tabBtn.BorderSizePixel = 0
        tabBtn.Font = Theme.FontBold
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.TextDim
        tabBtn.TextSize = 13
        tabBtn.ZIndex = 3
        tabBtn.Parent = TabBar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 5)
        tabCorner.Parent = tabBtn

        local tabPage = Instance.new("ScrollingFrame")
        tabPage.Name = tabName .. "Page"
        tabPage.Size = UDim2.new(1, 0, 1, 0)
        tabPage.BackgroundTransparency = 1
        tabPage.BorderSizePixel = 0
        tabPage.ScrollBarThickness = 3
        tabPage.ScrollBarImageColor3 = Theme.Border
        tabPage.Visible = false
        tabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y
        tabPage.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabPage.ZIndex = 3
        tabPage.Parent = ContentHolder

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 6)
        pageLayout.Parent = tabPage

        local tabAPI = {}

        local function refreshCanvas()
            task.defer(function()
                if pageLayout and tabPage then
                    tabPage.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 10)
                end
            end)
        end

        local function activateTab()
            for _, t in pairs(windowAPI.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = Theme.TabBackground
                t.Button.TextColor3 = Theme.TextDim
            end
            tabPage.Visible = true
            tabBtn.BackgroundColor3 = Theme.TabSelected
            tabBtn.TextColor3 = Theme.Text
            windowAPI.ActiveTab = tabAPI
            refreshCanvas()
        end

        tabBtn.MouseButton1Click:Connect(activateTab)

        table.insert(windowAPI.Tabs, {Button = tabBtn, Page = tabPage})

        if #windowAPI.Tabs == 1 then
            activateTab()
        end

        ------------------------------------------------------------------------
        -- TAB ELEMENT BUILDERS
        ------------------------------------------------------------------------

        function tabAPI:AddButton(text, callback)
            callback = callback or function() end
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 30)
            btn.BackgroundColor3 = Theme.ElementBackground
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Theme.FontBold
            btn.Text = text
            btn.TextColor3 = Theme.Text
            btn.TextSize = 13
            btn.ZIndex = 4
            btn.Parent = tabPage

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = btn

            btn.MouseButton1Click:Connect(function()
                task.spawn(callback)
                TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                task.wait(0.12)
                TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Theme.ElementBackground}):Play()
            end)

            refreshCanvas()
            return btn
        end

        function tabAPI:AddToggle(text, default, callback)
            callback = callback or function() end
            local savedToggles = savedConfigData.Toggles or {}
            local savedVal = savedToggles[text]
            local toggled = (savedVal ~= nil) and savedVal or (default or false)
            
            togglesRegistry[text] = toggled

            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 32)
            btn.BackgroundColor3 = Theme.ElementBackground
            btn.BorderSizePixel = 0
            btn.AutoButtonColor = false
            btn.Font = Theme.FontBold
            btn.Text = "  " .. text
            btn.TextColor3 = Theme.Text
            btn.TextSize = 13
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.ZIndex = 4
            btn.Parent = tabPage

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 5)
            btnCorner.Parent = btn

            local checkbox = Instance.new("Frame")
            checkbox.Size = UDim2.new(0, 16, 0, 16)
            checkbox.Position = UDim2.new(1, -22, 0.5, -8)
            checkbox.BorderSizePixel = 0
            checkbox.ZIndex = 5
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
                Library:SaveConfig()
            end)

            refreshCanvas()
            return btn
        end

        function tabAPI:AddSlider(text, min, max, default, callback)
            callback = callback or function() end
            min = min or 0
            max = max or 100
            
            local savedSliders = savedConfigData.Sliders or {}
            local savedVal = savedSliders[text]
            default = math.clamp((savedVal ~= nil) and savedVal or (default or min), min, max)
            slidersRegistry[text] = default

            local sliderFrame = Instance.new("Frame")
            sliderFrame.Size = UDim2.new(1, -6, 0, 42)
            sliderFrame.BackgroundColor3 = Theme.ElementBackground
            sliderFrame.BorderSizePixel = 0
            sliderFrame.ZIndex = 4
            sliderFrame.Parent = tabPage

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
            label.ZIndex = 5
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
            valueLabel.ZIndex = 5
            valueLabel.Parent = sliderFrame

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(1, -16, 0, 10)
            barBg.Position = UDim2.new(0, 8, 0, 24)
            barBg.BackgroundColor3 = Theme.ToggleOff
            barBg.BorderSizePixel = 0
            barBg.ZIndex = 5
            barBg.Parent = sliderFrame

            local barCorner = Instance.new("UICorner")
            barCorner.CornerRadius = UDim.new(0, 3)
            barCorner.Parent = barBg

            local fillBar = Instance.new("Frame")
            fillBar.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            fillBar.BackgroundColor3 = Theme.Accent
            fillBar.BorderSizePixel = 0
            fillBar.ZIndex = 6
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
                slidersRegistry[text] = val
                pcall(callback, val)
            end

            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    sliderActive = true
                    updateSlider(input)
                end
            end)

            trackConnection(UserInputService.InputChanged:Connect(function(input)
                if sliderActive and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end))

            trackConnection(UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if sliderActive then
                        sliderActive = false
                        Library:SaveConfig()
                    end
                end
            end))

            refreshCanvas()
            return sliderFrame
        end

        function tabAPI:AddTextBox(text, defaultText, callback)
            callback = callback or function() end

            local savedBoxes = savedConfigData.TextBoxes or {}
            local savedVal = savedBoxes[text]
            local initialText = (savedVal ~= nil) and savedVal or (defaultText or "")
            textboxesRegistry[text] = initialText

            local boxFrame = Instance.new("Frame")
            boxFrame.Size = UDim2.new(1, -6, 0, 32)
            boxFrame.BackgroundColor3 = Theme.ElementBackground
            boxFrame.BorderSizePixel = 0
            boxFrame.ZIndex = 4
            boxFrame.Parent = tabPage

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
            label.ZIndex = 5
            label.Parent = boxFrame

            local textBox = Instance.new("TextBox")
            textBox.Size = UDim2.new(0.4, -6, 0, 22)
            textBox.Position = UDim2.new(0.6, 0, 0.5, -11)
            textBox.BackgroundColor3 = Theme.ToggleOff
            textBox.BorderSizePixel = 0
            textBox.Font = Theme.FontBold
            textBox.Text = initialText
            textBox.TextColor3 = Theme.Text
            textBox.TextSize = 12
            textBox.ZIndex = 5
            textBox.Parent = boxFrame

            local boxCorner = Instance.new("UICorner")
            boxCorner.CornerRadius = UDim.new(0, 4)
            boxCorner.Parent = textBox

            textBox.FocusLost:Connect(function(enterPressed)
                textboxesRegistry[text] = textBox.Text
                pcall(callback, textBox.Text, enterPressed)
                Library:SaveConfig()
            end)

            refreshCanvas()
            return boxFrame
        end

        function tabAPI:AddLabel(text)
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -6, 0, 22)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.FontBold
            lbl.Text = text
            lbl.TextColor3 = Theme.TextDim
            lbl.TextSize = 13
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.ZIndex = 4
            lbl.Parent = tabPage

            refreshCanvas()
            return lbl
        end

        return tabAPI
    end

    ----------------------------------------------------------------------------
    -- SETTINGS TAB GENERATOR
    ----------------------------------------------------------------------------

    function windowAPI:CreateSettingsTab()
        local SettingsTab = self:CreateTab("Settings")

        SettingsTab:AddLabel("UI Configuration")

        SettingsTab:AddToggle("RGB Theme", false, function(state)
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

        SettingsTab:AddLabel("Layout & Window Management")

        SettingsTab:AddButton("Save Layout", function()
            windowPosition = {
                XScale = Window.Position.X.Scale,
                XOffset = Window.Position.X.Offset,
                YScale = Window.Position.Y.Scale,
                YOffset = Window.Position.Y.Offset
            }
            Library:SaveConfig()
            Library:Notify("Layout", "Window position saved!", 2)
        end)

        SettingsTab:AddButton("Reset Layout", function()
            local defaultPos = UDim2.new(0.5, -240, 0.5, -160)
            TweenService:Create(Window, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = defaultPos}):Play()
            
            windowPosition = {
                XScale = 0.5,
                XOffset = -240,
                YScale = 0.5,
                YOffset = -160
            }
            Library:SaveConfig()
            Library:Notify("Layout", "Window position reset to center!", 2)
        end)

        SettingsTab:AddLabel("Keybind & Config Manager")

        local bindBtn
        bindBtn = SettingsTab:AddButton("Toggle Key: " .. tostring(currentKeybind.Name), function()
            if isRebinding then return end
            isRebinding = true
            Library:Notify("Keybind", "Press any key...", 2)

            local connection
            connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                    currentKeybind = input.KeyCode
                    bindBtn.Text = "Toggle Key: " .. tostring(currentKeybind.Name)
                    Library:Notify("Keybind", "Key set to " .. tostring(currentKeybind.Name), 2)
                    connection:Disconnect()
                    Library:SaveConfig()
                    task.delay(0.2, function()
                        isRebinding = false
                    end)
                end
            end)
        end)

        SettingsTab:AddButton("Save Config File", function()
            Library:SaveConfig()
            Library:Notify("Settings", "Configuration saved!", 2)
        end)

        SettingsTab:AddLabel("Script Controls")

        SettingsTab:AddButton("Destroy UI", function()
            Library:Destroy()
        end)

        return SettingsTab
    end

    return windowAPI
end

return Library
