--[[
================================================================================
                    NEXZAN PREMIUM UI LIBRARY (v2.3 - ULTIMATE FULL)
================================================================================
    * Glassmorphism Design Premium (White/Neutral Accent - NO BLUE)
    * Ukuran Jendela Utama: 550 x 330 (TETAP OPTIMAL)
    * Sistem Key System Terintegrasi & Aman
    * Fitur PALING LENGKAP & TERBAIK
    * Mobile Friendly dengan Draggable Sempurna
    * Rainbow Border Effect Premium
    * Notification System Advanced
    * 10+ UI Elements (Button, Toggle, Slider, Dropdown, Textbox, Keybind, ColorPicker, Label, dan lainnya)
================================================================================
]]

local Library = {}
Library.Unloaded = false
Library.KeyValidated = false
Library.Windows = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

-- ==================== CONFIGURATION ====================
local KEY_CONFIG = {
    Enabled = true,
    Keys = {
        "NEXZAN2024PREMIUM",
        "ADMIN123SECRET",
    },
    PastebinUrl = "https://pastebin.com/raw/YOUR_KEY_URL",
    MaxAttempts = 5,
    ShowKeyOnStartup = true,
}

-- ==================== UTILITY FUNCTIONS ====================

local function MakeDraggable(guiObject)
    local dragging
    local dragInput
    local dragStart
    local startPos

    local function update(input)
        local delta = input.Position - dragStart
        local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        TweenService:Create(guiObject, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end

    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

local function CreateRainbowBorder(frame, thickness)
    thickness = thickness or 2
    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not frame or not frame.Parent then
            connection:Disconnect()
            return
        end
        local hue = (tick() % 5) / 5
        stroke.Color = Color3.fromHSV(hue, 0.8, 1)
    end)
end

-- ==================== KEY SYSTEM ====================

function Library:InitKeySystem(callback)
    if not KEY_CONFIG.Enabled then
        Library.KeyValidated = true
        if callback then pcall(callback) end
        return
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexzanKeySystemGui"
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    -- Background Blur
    local Background = Instance.new("Frame", ScreenGui)
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Background.BackgroundTransparency = 0.65
    Background.BorderSizePixel = 0

    -- Main Panel
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 400, 0, 320)
    Frame.Position = UDim2.new(0.5, -200, 0.5, -160)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Frame.BackgroundTransparency = 0.08
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner", Frame)
    UICorner.CornerRadius = UDim.new(0, 15)

    CreateRainbowBorder(Frame, 2.5)

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Position = UDim2.new(0, 0, 0, 12)
    Title.BackgroundTransparency = 1
    Title.Text = "🔐 NEXZAN HUB - PREMIUM KEY"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = Frame

    -- Subtitle
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -30, 0, 30)
    Subtitle.Position = UDim2.new(0, 15, 0, 50)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "Verifikasi kunci premium Anda untuk mengakses hub"
    Subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 13
    Subtitle.TextWrapped = true
    Subtitle.Parent = Frame

    -- Attempts Counter
    local AttemptsLabel = Instance.new("TextLabel")
    AttemptsLabel.Size = UDim2.new(1, -30, 0, 18)
    AttemptsLabel.Position = UDim2.new(0, 15, 0, 85)
    AttemptsLabel.BackgroundTransparency = 1
    AttemptsLabel.Text = "Attempts: 5/5"
    AttemptsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    AttemptsLabel.Font = Enum.Font.Gotham
    AttemptsLabel.TextSize = 11
    AttemptsLabel.TextXAlignment = Enum.TextXAlignment.Left
    AttemptsLabel.Parent = Frame

    -- Input Box
    local TextBox = Instance.new("TextBox")
    TextBox.Size = UDim2.new(1, -30, 0, 44)
    TextBox.Position = UDim2.new(0, 15, 0, 105)
    TextBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    TextBox.PlaceholderText = "Paste your key here..."
    TextBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
    TextBox.Font = Enum.Font.Gotham
    TextBox.TextSize = 14
    TextBox.Text = ""
    TextBox.Parent = Frame
    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 8)
    
    local BoxStroke = Instance.new("UIStroke", TextBox)
    BoxStroke.Color = Color3.fromRGB(60, 60, 60)
    BoxStroke.Thickness = 1.5

    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -30, 0, 22)
    StatusLabel.Position = UDim2.new(0, 15, 0, 152)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = ""
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 12
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = Frame

    -- Button Container
    local ButtonContainer = Instance.new("Frame", Frame)
    ButtonContainer.Size = UDim2.new(1, -30, 0, 45)
    ButtonContainer.Position = UDim2.new(0, 15, 0, 182)
    ButtonContainer.BackgroundTransparency = 1

    local ButtonLayout = Instance.new("UIListLayout", ButtonContainer)
    ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
    ButtonLayout.Padding = UDim.new(0, 12)
    ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    -- Verify Button
    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Size = UDim2.new(0, 130, 0, 42)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
    SubmitBtn.Text = "✓ VERIFY"
    SubmitBtn.Font = Enum.Font.GothamBold
    SubmitBtn.TextSize = 13
    SubmitBtn.Parent = ButtonContainer
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 7)
    
    local SubmitStroke = Instance.new("UIStroke", SubmitBtn)
    SubmitStroke.Color = Color3.fromRGB(200, 200, 200)
    SubmitStroke.Thickness = 1.2

    -- Get Key Button
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(0, 130, 0, 42)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    GetKeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    GetKeyBtn.Text = "? GET KEY"
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 13
    GetKeyBtn.Parent = ButtonContainer
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 7)

    local GetKeyStroke = Instance.new("UIStroke", GetKeyBtn)
    GetKeyStroke.Color = Color3.fromRGB(80, 80, 80)
    GetKeyStroke.Thickness = 1.2

    MakeDraggable(Frame)

    local Attempts = KEY_CONFIG.MaxAttempts

    -- Verify Function
    local function VerifyKey()
        local enteredKey = TextBox.Text:upper()
        local isValid = false

        for _, key in ipairs(KEY_CONFIG.Keys) do
            if enteredKey == key:upper() then
                isValid = true
                break
            end
        end

        if isValid then
            Title.Text = "✅ ACCESS GRANTED!"
            Title.TextColor3 = Color3.fromRGB(0, 255, 120)
            StatusLabel.Text = ""
            Library.KeyValidated = true
            task.wait(1.5)
            ScreenGui:Destroy()
            if callback then pcall(callback) end
        else
            Attempts = Attempts - 1
            AttemptsLabel.Text = "Attempts: " .. Attempts .. "/" .. KEY_CONFIG.MaxAttempts
            StatusLabel.Text = "❌ Invalid key! " .. Attempts .. " attempts left."
            StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            TextBox.Text = ""
            
            if Attempts <= 0 then
                Title.Text = "⛔ ACCESS DENIED!"
                Title.TextColor3 = Color3.fromRGB(255, 50, 50)
                StatusLabel.Text = "Too many attempts. Please try again later."
                SubmitBtn.Visible = false
                GetKeyBtn.Visible = false
                TextBox.Visible = false
                task.wait(3)
                ScreenGui:Destroy()
            end
        end
    end

    SubmitBtn.MouseButton1Click:Connect(VerifyKey)
    
    TextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            VerifyKey()
        end
    end)

    GetKeyBtn.MouseButton1Click:Connect(function()
        setclipboard("discord.gg/nexzan") -- EDIT INI SESUAI DISCORD/LINK ANDA
        StatusLabel.Text = "✅ Discord link copied to clipboard!"
        StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        GetKeyBtn.Text = "✓ COPIED!"
        task.wait(2)
        StatusLabel.Text = ""
        GetKeyBtn.Text = "? GET KEY"
    end)

    TextBox:CaptureFocus()
end

-- ==================== MAIN UI CREATION ====================

function Library:CreateWindow(UiTitle)
    UiTitle = UiTitle or "Nexzan Premium"
    
    -- Initialize Key System
    if KEY_CONFIG.Enabled and KEY_CONFIG.ShowKeyOnStartup then
        self:InitKeySystem(function()
            print("✅ Key verified! Loading UI...")
        end)
        
        local maxWait = 60
        local waited = 0
        while not Library.KeyValidated and waited < maxWait do
            task.wait(0.1)
            waited = waited + 0.1
        end
        
        if not Library.KeyValidated then
            print("❌ Key validation failed")
            return
        end
    end
    
    -- Destroy old UI
    local OldGui = Player:WaitForChild("PlayerGui"):FindFirstChild("NexzanPremiumUiLib")
    if OldGui then OldGui:Destroy() end

    -- Main Container
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexzanPremiumUiLib"
    ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true

    -- ==================== NOTIFICATION SYSTEM ====================
    local NotificationArea = Instance.new("Frame")
    NotificationArea.Name = "NotificationArea"
    NotificationArea.Size = UDim2.new(0, 320, 1, -20)
    NotificationArea.Position = UDim2.new(1, -330, 0, 10)
    NotificationArea.BackgroundTransparency = 1
    NotificationArea.Parent = ScreenGui

    local NotifLayout = Instance.new("UIListLayout")
    NotifLayout.Parent = NotificationArea
    NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
    NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifLayout.Padding = UDim.new(0, 10)

    function Library:Notify(title, desc, duration, notifType)
        title = title or "Notification"
        desc = desc or "Something happened."
        duration = duration or 4
        notifType = notifType or "info"

        local NotifFrame = Instance.new("Frame")
        NotifFrame.Size = UDim2.new(1, 0, 0, 0)
        NotifFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        NotifFrame.BackgroundTransparency = 0.08
        NotifFrame.ClipsDescendants = true
        NotifFrame.Parent = NotificationArea

        local Corner = Instance.new("UICorner", NotifFrame)
        Corner.CornerRadius = UDim.new(0, 10)

        local BorderColor = Color3.fromRGB(255, 255, 255)
        if notifType == "success" then
            BorderColor = Color3.fromRGB(0, 255, 120)
        elseif notifType == "error" then
            BorderColor = Color3.fromRGB(255, 80, 80)
        elseif notifType == "warning" then
            BorderColor = Color3.fromRGB(255, 180, 0)
        end

        local Stroke = Instance.new("UIStroke", NotifFrame)
        Stroke.Color = BorderColor
        Stroke.Thickness = 1.5

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, -20, 0, 22)
        TitleLabel.Position = UDim2.new(0, 10, 0, 8)
        TitleLabel.Text = title
        TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TitleLabel.Font = Enum.Font.GothamBold
        TitleLabel.TextSize = 13
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Parent = NotifFrame

        local DescLabel = Instance.new("TextLabel")
        DescLabel.Size = UDim2.new(1, -20, 1, -36)
        DescLabel.Position = UDim2.new(0, 10, 0, 30)
        DescLabel.Text = desc
        DescLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        DescLabel.Font = Enum.Font.Gotham
        DescLabel.TextSize = 12
        DescLabel.TextXAlignment = Enum.TextXAlignment.Left
        DescLabel.TextYAlignment = Enum.TextYAlignment.Top
        DescLabel.TextWrapped = true
        DescLabel.BackgroundTransparency = 1
        DescLabel.Parent = NotifFrame

        local targetHeight = 85
        TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, targetHeight)}):Play()

        task.spawn(function()
            task.wait(duration)
            local shrink = TweenService:Create(NotifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1})
            shrink:Play()
            shrink.Completed:Connect(function()
                NotifFrame:Destroy()
            end)
        end)
    end

    -- ==================== MINIMIZE BUTTON ====================
    local MinimizedBtn = Instance.new("TextButton")
    MinimizedBtn.Size = UDim2.new(0, 160, 0, 40)
    MinimizedBtn.Position = UDim2.new(0.5, -80, 0, 20)
    MinimizedBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    MinimizedBtn.BackgroundTransparency = 0.08
    MinimizedBtn.Text = "🚀 Open Nexzan UI"
    MinimizedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizedBtn.Font = Enum.Font.GothamBold
    MinimizedBtn.TextSize = 13
    MinimizedBtn.Visible = false
    MinimizedBtn.Parent = ScreenGui

    Instance.new("UICorner", MinimizedBtn).CornerRadius = UDim.new(0, 10)
    local MinStroke = Instance.new("UIStroke", MinimizedBtn)
    MinStroke.Color = Color3.fromRGB(255, 255, 255)
    MinStroke.Thickness = 1.8
    MakeDraggable(MinimizedBtn)

    -- ==================== MAIN WINDOW (550x330) ====================
    local MainWindow = Instance.new("Frame")
    MainWindow.Size = UDim2.new(0, 550, 0, 330)
    MainWindow.Position = UDim2.new(0.5, -275, 0.5, -165)
    MainWindow.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainWindow.BackgroundTransparency = 0.08
    MainWindow.Active = true
    MainWindow.Parent = ScreenGui

    Instance.new("UICorner", MainWindow).CornerRadius = UDim.new(0, 15)
    MakeDraggable(MainWindow)
    CreateRainbowBorder(MainWindow, 2)

    -- ==================== WINDOW CONTROL BUTTONS ====================
    local ControlContainer = Instance.new("Frame")
    ControlContainer.Size = UDim2.new(0, 75, 0, 32)
    ControlContainer.Position = UDim2.new(1, -90, 0, 12)
    ControlContainer.BackgroundTransparency = 1
    ControlContainer.Parent = MainWindow

    local BtnMinimize = Instance.new("TextButton")
    local BtnClose = Instance.new("TextButton")

    BtnMinimize.Size = UDim2.new(0, 32, 0, 32)
    BtnMinimize.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BtnMinimize.Text = "━"
    BtnMinimize.TextColor3 = Color3.fromRGB(255, 255, 255)
    BtnMinimize.Font = Enum.Font.GothamBold
    BtnMinimize.TextSize = 18
    BtnMinimize.Parent = ControlContainer
    Instance.new("UICorner", BtnMinimize).CornerRadius = UDim.new(0, 7)

    BtnClose.Size = UDim2.new(0, 32, 0, 32)
    BtnClose.Position = UDim2.new(0, 40, 0, 0)
    BtnClose.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
    BtnClose.Text = "✕"
    BtnClose.TextColor3 = Color3.fromRGB(255, 255, 255)
    BtnClose.Font = Enum.Font.GothamBold
    BtnClose.TextSize = 16
    BtnClose.Parent = ControlContainer
    Instance.new("UICorner", BtnClose).CornerRadius = UDim.new(0, 7)

    BtnMinimize.MouseButton1Click:Connect(function()
        MainWindow.Visible = false
        MinimizedBtn.Visible = true
        Library:Notify("🔽 Minimized", "Click the button to reopen", 2, "info")
    end)

    MinimizedBtn.MouseButton1Click:Connect(function()
        MinimizedBtn.Visible = false
        MainWindow.Visible = true
    end)

    BtnClose.MouseButton1Click:Connect(function()
        Library.Unloaded = true
        ScreenGui:Destroy()
        Library:Notify("🔴 Closed", "Nexzan Hub has been closed", 2, "warning")
    end)

    -- ==================== SIDEBAR ====================
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 190, 1, -50)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    Sidebar.BackgroundTransparency = 0.25
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainWindow
    Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 15)

    -- Header
    local Header = Instance.new("Frame", Sidebar)
    Header.Size = UDim2.new(1, 0, 0, 70)
    Header.BackgroundTransparency = 1

    local GameTitle = Instance.new("TextLabel", Header)
    GameTitle.Size = UDim2.new(1, -20, 0, 25)
    GameTitle.Position = UDim2.new(0, 10, 0, 8)
    GameTitle.Text = UiTitle
    GameTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    GameTitle.TextSize = 14
    GameTitle.Font = Enum.Font.GothamBold
    GameTitle.TextXAlignment = Enum.TextXAlignment.Left
    GameTitle.TextTruncate = Enum.TextTruncate.AtEnd
    GameTitle.BackgroundTransparency = 1

    local AuthorLabel = Instance.new("TextLabel", Header)
    AuthorLabel.Size = UDim2.new(1, -20, 0, 18)
    AuthorLabel.Position = UDim2.new(0, 10, 0, 36)
    AuthorLabel.Text = "💎 Made by Nexzan"
    AuthorLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
    AuthorLabel.TextSize = 12
    AuthorLabel.Font = Enum.Font.Gotham
    AuthorLabel.TextXAlignment = Enum.TextXAlignment.Left
    AuthorLabel.BackgroundTransparency = 1

    local LineHeader = Instance.new("Frame", Sidebar)
    LineHeader.Size = UDim2.new(1, -20, 0, 1)
    LineHeader.Position = UDim2.new(0, 10, 0, 72)
    LineHeader.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    LineHeader.BorderSizePixel = 0

    -- Tab Container
    local TabContainer = Instance.new("ScrollingFrame", Sidebar)
    TabContainer.Size = UDim2.new(1, 0, 1, -155)
    TabContainer.Position = UDim2.new(0, 0, 0, 78)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)

    local TabListLayout = Instance.new("UIListLayout", TabContainer)
    TabListLayout.Padding = UDim.new(0, 6)
    TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
    end)

    -- Footer
    local Footer = Instance.new("Frame", Sidebar)
    Footer.Size = UDim2.new(1, -16, 0, 65)
    Footer.Position = UDim2.new(0, 8, 1, -73)
    Footer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    Footer.BackgroundTransparency = 0.4
    Instance.new("UICorner", Footer).CornerRadius = UDim.new(0, 10)
    
    local FooterStroke = Instance.new("UIStroke", Footer)
    FooterStroke.Color = Color3.fromRGB(60, 60, 60)
    FooterStroke.Thickness = 1

    local AvatarImg = Instance.new("ImageLabel", Footer)
    AvatarImg.Size = UDim2.new(0, 40, 0, 40)
    AvatarImg.Position = UDim2.new(0, 8, 0.5, -20)
    AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id="..Player.UserId.."&w=150&h=150"
    Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

    local DisplayNameLabel = Instance.new("TextLabel", Footer)
    DisplayNameLabel.Size = UDim2.new(1, -60, 0, 17)
    DisplayNameLabel.Position = UDim2.new(0, 52, 0, 4)
    DisplayNameLabel.Text = Player.DisplayName
    DisplayNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    DisplayNameLabel.Font = Enum.Font.GothamBold
    DisplayNameLabel.TextSize = 13
    DisplayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    DisplayNameLabel.BackgroundTransparency = 1

    local UsernameLabel = Instance.new("TextLabel", Footer)
    UsernameLabel.Size = UDim2.new(1, -60, 0, 15)
    UsernameLabel.Position = UDim2.new(0, 52, 0, 24)
    UsernameLabel.Text = "@" .. Player.Name
    UsernameLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    UsernameLabel.Font = Enum.Font.Gotham
    UsernameLabel.TextSize = 11
    UsernameLabel.TextXAlignment = Enum.TextXAlignment.Left
    UsernameLabel.BackgroundTransparency = 1

    -- ==================== PAGES HOLDER ====================
    local PagesHolder = Instance.new("Frame", MainWindow)
    PagesHolder.Size = UDim2.new(1, -210, 1, -50)
    PagesHolder.Position = UDim2.new(0, 200, 0, 40)
    PagesHolder.BackgroundTransparency = 1

    local Pages = {}
    local Tabs = {}
    local FirstTab = nil

    local function SwitchToTab(tabName)
        for name, page in pairs(Pages) do 
            page.Visible = (name == tabName) 
        end
        for name, btn in pairs(Tabs) do
            if name == tabName then
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.7, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                btn.TabLayout.Txt.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundTransparency = 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                btn.TabLayout.Txt.TextColor3 = Color3.fromRGB(170, 170, 170)
            end
        end
    end

    local WindowFunctions = {}

    -- ==================== CREATE TAB METHOD ====================
    function WindowFunctions:CreateTab(tabName, iconId)
        iconId = iconId or "rbxassetid://4483362458"
        
        local TabBtn = Instance.new("TextButton", TabContainer)
        TabBtn.Size = UDim2.new(1, -16, 0, 40)
        TabBtn.BackgroundTransparency = 1
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.Text = ""
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
        
        local TabLayout = Instance.new("Frame", TabBtn)
        TabLayout.Name = "TabLayout"
        TabLayout.Size = UDim2.new(1, 0, 1, 0)
        TabLayout.BackgroundTransparency = 1

        local Icon = Instance.new("ImageLabel", TabLayout)
        Icon.Size = UDim2.new(0, 18, 0, 18)
        Icon.Position = UDim2.new(0, 10, 0.5, -9)
        Icon.Image = iconId
        Icon.BackgroundTransparency = 1
        
        local Txt = Instance.new("TextLabel", TabLayout)
        Txt.Name = "Txt"
        Txt.Size = UDim2.new(1, -40, 1, 0)
        Txt.Position = UDim2.new(0, 35, 0, 0)
        Txt.Text = tabName
        Txt.TextColor3 = Color3.fromRGB(170, 170, 170)
        Txt.TextSize = 13
        Txt.Font = Enum.Font.GothamSemibold
        Txt.TextXAlignment = Enum.TextXAlignment.Left
        Txt.BackgroundTransparency = 1

        -- Page Content
        local ContentPage = Instance.new("ScrollingFrame", PagesHolder)
        ContentPage.Size = UDim2.new(1, 0, 1, 0)
        ContentPage.BackgroundTransparency = 1
        ContentPage.ScrollBarThickness = 4
        ContentPage.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
        ContentPage.Visible = false
        ContentPage.CanvasSize = UDim2.new(0, 0, 0, 0)

        local ContentLayout = Instance.new("UIListLayout", ContentPage)
        ContentLayout.Padding = UDim.new(0, 10)
        ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            ContentPage.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 15)
        end)

        local Padding = Instance.new("UIPadding", ContentPage)
        Padding.PaddingTop = UDim.new(0, 8)
        Padding.PaddingBottom = UDim.new(0, 15)
        Padding.PaddingLeft = UDim.new(0, 8)
        Padding.PaddingRight = UDim.new(0, 8)
        
        Pages[tabName] = ContentPage
        Tabs[tabName] = TabBtn

        if not FirstTab then
            FirstTab = tabName
            ContentPage.Visible = true
            TabBtn.BackgroundTransparency = 0.7
            TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        end

        TabBtn.MouseButton1Click:Connect(function() 
            SwitchToTab(tabName) 
        end)

        local TabFunctions = {}

        -- ==================== BUTTON ====================
        function TabFunctions:CreateButton(text, desc, callback)
            local FeatureFrame = Instance.new("Frame", ContentPage)
            FeatureFrame.Size = UDim2.new(1, -10, 0, 55)
            FeatureFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            FeatureFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", FeatureFrame).CornerRadius = UDim.new(0, 8)
            
            local BtnStroke = Instance.new("UIStroke", FeatureFrame)
            BtnStroke.Color = Color3.fromRGB(60, 60, 60)
            BtnStroke.Thickness = 1.2
            
            local Title = Instance.new("TextLabel", FeatureFrame)
            Title.Size = UDim2.new(0.65, 0, 0, 22)
            Title.Position = UDim2.new(0, 12, 0, 6)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local Description = Instance.new("TextLabel", FeatureFrame)
            Description.Size = UDim2.new(0.65, 0, 0, 18)
            Description.Position = UDim2.new(0, 12, 0, 30)
            Description.Text = desc or "No description"
            Description.TextColor3 = Color3.fromRGB(150, 150, 150)
            Description.Font = Enum.Font.Gotham
            Description.TextSize = 11
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BackgroundTransparency = 1
            
            local ActionBtn = Instance.new("TextButton", FeatureFrame)
            ActionBtn.Size = UDim2.new(0, 75, 0, 32)
            ActionBtn.Position = UDim2.new(1, -87, 0.5, -16)
            ActionBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ActionBtn.Text = "Execute"
            ActionBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
            ActionBtn.Font = Enum.Font.GothamBold
            ActionBtn.TextSize = 12
            Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 6)
            
            ActionBtn.MouseEnter:Connect(function()
                TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(230, 230, 230)}):Play()
            end)
            ActionBtn.MouseLeave:Connect(function()
                TweenService:Create(ActionBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            end)

            ActionBtn.MouseButton1Click:Connect(function()
                ActionBtn.Text = "⏳"
                pcall(callback)
                task.wait(0.5)
                ActionBtn.Text = "Execute"
            end)
        end

        -- ==================== TOGGLE ====================
        function TabFunctions:CreateToggle(text, desc, default, callback)
            local FeatureFrame = Instance.new("Frame", ContentPage)
            FeatureFrame.Size = UDim2.new(1, -10, 0, 55)
            FeatureFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            FeatureFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", FeatureFrame).CornerRadius = UDim.new(0, 8)
            
            local TglStroke = Instance.new("UIStroke", FeatureFrame)
            TglStroke.Color = Color3.fromRGB(60, 60, 60)
            TglStroke.Thickness = 1.2
            
            local Title = Instance.new("TextLabel", FeatureFrame)
            Title.Size = UDim2.new(0.6, 0, 0, 22)
            Title.Position = UDim2.new(0, 12, 0, 6)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local Description = Instance.new("TextLabel", FeatureFrame)
            Description.Size = UDim2.new(0.6, 0, 0, 18)
            Description.Position = UDim2.new(0, 12, 0, 30)
            Description.Text = desc or "Activate or deactivate"
            Description.TextColor3 = Color3.fromRGB(150, 150, 150)
            Description.Font = Enum.Font.Gotham
            Description.TextSize = 11
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BackgroundTransparency = 1

            local ToggleBg = Instance.new("TextButton", FeatureFrame)
            ToggleBg.Size = UDim2.new(0, 48, 0, 28)
            ToggleBg.Position = UDim2.new(1, -60, 0.5, -14)
            ToggleBg.BackgroundColor3 = default and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
            ToggleBg.Text = ""
            Instance.new("UICorner", ToggleBg).CornerRadius = UDim.new(1, 0)

            local ToggleBall = Instance.new("Frame", ToggleBg)
            ToggleBall.Size = UDim2.new(0, 22, 0, 22)
            ToggleBall.Position = default and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
            ToggleBall.BackgroundColor3 = default and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
            Instance.new("UICorner", ToggleBall).CornerRadius = UDim.new(1, 0)

            local IsOn = default
            ToggleBg.MouseButton1Click:Connect(function()
                IsOn = not IsOn
                local targetPos = IsOn and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)
                local targetColor = IsOn and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 60, 60)
                local ballColor = IsOn and Color3.fromRGB(20, 20, 20) or Color3.fromRGB(255, 255, 255)
                
                TweenService:Create(ToggleBall, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = targetPos, BackgroundColor3 = ballColor}):Play()
                TweenService:Create(ToggleBg, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
                
                pcall(callback, IsOn)
            end)
        end

        -- ==================== SLIDER ====================
        function TabFunctions:CreateSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame", ContentPage)
            SliderFrame.Size = UDim2.new(1, -10, 0, 62)
            SliderFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            SliderFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 8)
            
            local SldStroke = Instance.new("UIStroke", SliderFrame)
            SldStroke.Color = Color3.fromRGB(60, 60, 60)
            SldStroke.Thickness = 1.2

            local Title = Instance.new("TextLabel", SliderFrame)
            Title.Size = UDim2.new(0.6, 0, 0, 22)
            Title.Position = UDim2.new(0, 12, 0, 6)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local ValueLabel = Instance.new("TextLabel", SliderFrame)
            ValueLabel.Size = UDim2.new(0.3, 0, 0, 22)
            ValueLabel.Position = UDim2.new(0.65, 0, 0, 6)
            ValueLabel.Text = tostring(default)
            ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.BackgroundTransparency = 1

            local SliderBarBg = Instance.new("TextButton", SliderFrame)
            SliderBarBg.Size = UDim2.new(1, -24, 0, 9)
            SliderBarBg.Position = UDim2.new(0, 12, 0, 35)
            SliderBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            SliderBarBg.Text = ""
            Instance.new("UICorner", SliderBarBg).CornerRadius = UDim.new(1, 0)

            local SliderBarFill = Instance.new("Frame", SliderBarBg)
            SliderBarFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderBarFill.BorderSizePixel = 0
            Instance.new("UICorner", SliderBarFill).CornerRadius = UDim.new(1, 0)

            local Dragging = false
            local function UpdateSlider(input)
                local relativeX = input.Position.X - SliderBarBg.AbsolutePosition.X
                local pct = math.clamp(relativeX / SliderBarBg.AbsoluteSize.X, 0, 1)
                local rawVal = min + (pct * (max - min))
                local finalVal = math.round(rawVal)

                SliderBarFill.Size = UDim2.new(pct, 0, 1, 0)
                ValueLabel.Text = tostring(finalVal)
                pcall(callback, finalVal)
            end

            SliderBarBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    UpdateSlider(input)
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    UpdateSlider(input)
                end
            end)
        end

        -- ==================== DROPDOWN ====================
        function TabFunctions:CreateDropdown(text, options, callback)
            local DropdownFrame = Instance.new("Frame", ContentPage)
            DropdownFrame.Size = UDim2.new(1, -10, 0, 50)
            DropdownFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            DropdownFrame.BackgroundTransparency = 0.45
            DropdownFrame.ClipsDescendants = true
            Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 8)
            
            local DropStroke = Instance.new("UIStroke", DropdownFrame)
            DropStroke.Color = Color3.fromRGB(60, 60, 60)
            DropStroke.Thickness = 1.2

            local Title = Instance.new("TextLabel", DropdownFrame)
            Title.Size = UDim2.new(0.5, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local OpenBtn = Instance.new("TextButton", DropdownFrame)
            OpenBtn.Size = UDim2.new(0, 120, 0, 32)
            OpenBtn.Position = UDim2.new(1, -132, 0.5, -16)
            OpenBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            OpenBtn.Text = options[1] or "Select..."
            OpenBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            OpenBtn.Font = Enum.Font.GothamBold
            OpenBtn.TextSize = 12
            Instance.new("UICorner", OpenBtn).CornerRadius = UDim.new(0, 6)

            local ContainerOptions = Instance.new("Frame", DropdownFrame)
            ContainerOptions.Size = UDim2.new(1, -24, 0, #options * 32)
            ContainerOptions.Position = UDim2.new(0, 12, 0, 55)
            ContainerOptions.BackgroundTransparency = 1

            local DropLayout = Instance.new("UIListLayout", ContainerOptions)
            DropLayout.Padding = UDim.new(0, 4)

            local IsExpanded = false
            OpenBtn.MouseButton1Click:Connect(function()
                IsExpanded = not IsExpanded
                local targetHeight = IsExpanded and (50 + (#options * 32) + 15) or 50
                TweenService:Create(DropdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -10, 0, targetHeight)}):Play()
            end)

            for _, optName in ipairs(options) do
                local OptBtn = Instance.new("TextButton", ContainerOptions)
                OptBtn.Size = UDim2.new(1, 0, 0, 28)
                OptBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                OptBtn.Text = optName
                OptBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
                OptBtn.Font = Enum.Font.Gotham
                OptBtn.TextSize = 12
                Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 5)

                OptBtn.MouseEnter:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(50, 50, 50), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end)
                OptBtn.MouseLeave:Connect(function()
                    TweenService:Create(OptBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 35), TextColor3 = Color3.fromRGB(200, 200, 200)}):Play()
                end)

                OptBtn.MouseButton1Click:Connect(function()
                    OpenBtn.Text = optName
                    IsExpanded = false
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(1, -10, 0, 50)}):Play()
                    pcall(callback, optName)
                end)
            end
        end

        -- ==================== TEXTBOX ====================
        function TabFunctions:CreateTextbox(text, placeholder, callback)
            local InputFrame = Instance.new("Frame", ContentPage)
            InputFrame.Size = UDim2.new(1, -10, 0, 55)
            InputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            InputFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 8)
            
            local BoxFrameStroke = Instance.new("UIStroke", InputFrame)
            BoxFrameStroke.Color = Color3.fromRGB(60, 60, 60)
            BoxFrameStroke.Thickness = 1.2

            local Title = Instance.new("TextLabel", InputFrame)
            Title.Size = UDim2.new(0.5, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local InputBox = Instance.new("TextBox", InputFrame)
            InputBox.Size = UDim2.new(0, 145, 0, 32)
            InputBox.Position = UDim2.new(1, -157, 0.5, -16)
            InputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            InputBox.PlaceholderText = placeholder or "Type here..."
            InputBox.Text = ""
            InputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            InputBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
            InputBox.Font = Enum.Font.Gotham
            InputBox.TextSize = 12
            InputBox.ClipsDescendants = true
            Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 6)

            local BoxStroke = Instance.new("UIStroke", InputBox)
            BoxStroke.Color = Color3.fromRGB(70, 70, 70)
            BoxStroke.Thickness = 1.2

            InputBox.Focused:Connect(function()
                TweenService:Create(BoxStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(255, 255, 255)}):Play()
            end)
            InputBox.FocusLost:Connect(function(enterPressed)
                TweenService:Create(BoxStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(70, 70, 70)}):Play()
                pcall(callback, InputBox.Text, enterPressed)
            end)
        end

        -- ==================== KEYBIND ====================
        function TabFunctions:CreateKeybind(text, defaultKey, callback)
            local KeybindFrame = Instance.new("Frame", ContentPage)
            KeybindFrame.Size = UDim2.new(1, -10, 0, 55)
            KeybindFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            KeybindFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", KeybindFrame).CornerRadius = UDim.new(0, 8)
            
            local KeyStroke = Instance.new("UIStroke", KeybindFrame)
            KeyStroke.Color = Color3.fromRGB(60, 60, 60)
            KeyStroke.Thickness = 1.2

            local Title = Instance.new("TextLabel", KeybindFrame)
            Title.Size = UDim2.new(0.6, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local BindBtn = Instance.new("TextButton", KeybindFrame)
            BindBtn.Size = UDim2.new(0, 90, 0, 32)
            BindBtn.Position = UDim2.new(1, -102, 0.5, -16)
            BindBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            BindBtn.Text = defaultKey and defaultKey.Name or "NONE"
            BindBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 12
            Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 6)

            local CurrentKey = defaultKey
            local Listening = false

            BindBtn.MouseButton1Click:Connect(function()
                BindBtn.Text = "..."
                Listening = true
            end)

            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if Listening and not gameProcessed then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        Listening = false
                        CurrentKey = input.KeyCode
                        BindBtn.Text = CurrentKey.Name
                        pcall(callback, CurrentKey)
                    end
                elseif not Listening and CurrentKey and input.KeyCode == CurrentKey and not gameProcessed then
                    pcall(callback, CurrentKey)
                end
            end)
        end

        -- ==================== LABEL ====================
        function TabFunctions:CreateLabel(text, isParagraph)
            local LabelFrame = Instance.new("Frame", ContentPage)
            local FrameHeight = isParagraph and 70 or 40
            LabelFrame.Size = UDim2.new(1, -10, 0, FrameHeight)
            LabelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            LabelFrame.BackgroundTransparency = 0.55
            Instance.new("UICorner", LabelFrame).CornerRadius = UDim.new(0, 8)
            
            local LabelText = Instance.new("TextLabel", LabelFrame)
            LabelText.Size = UDim2.new(1, -20, 1, 0)
            LabelText.Position = UDim2.new(0, 10, 0, 0)
            LabelText.Text = text
            LabelText.TextColor3 = isParagraph and Color3.fromRGB(180, 180, 180) or Color3.fromRGB(255, 255, 255)
            LabelText.Font = isParagraph and Enum.Font.Gotham or Enum.Font.GothamBold
            LabelText.TextSize = isParagraph and 12 or 14
            LabelText.TextXAlignment = Enum.TextXAlignment.Left
            LabelText.TextYAlignment = Enum.TextYAlignment.Center
            LabelText.TextWrapped = isParagraph
            LabelText.BackgroundTransparency = 1

            return {SetText = function(newText) LabelText.Text = newText end}
        end

        -- ==================== COLORPICKER ====================
        function TabFunctions:CreateColorpicker(text, defaultColor, callback)
            local CpFrame = Instance.new("Frame", ContentPage)
            CpFrame.Size = UDim2.new(1, -10, 0, 55)
            CpFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            CpFrame.BackgroundTransparency = 0.45
            Instance.new("UICorner", CpFrame).CornerRadius = UDim.new(0, 8)
            
            local CpStroke = Instance.new("UIStroke", CpFrame)
            CpStroke.Color = Color3.fromRGB(60, 60, 60)
            CpStroke.Thickness = 1.2

            local Title = Instance.new("TextLabel", CpFrame)
            Title.Size = UDim2.new(0.6, 0, 1, 0)
            Title.Position = UDim2.new(0, 12, 0, 0)
            Title.Text = text
            Title.TextColor3 = Color3.fromRGB(255, 255, 255)
            Title.Font = Enum.Font.GothamBold
            Title.TextSize = 13
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.BackgroundTransparency = 1

            local ColorDisplay = Instance.new("TextButton", CpFrame)
            ColorDisplay.Size = UDim2.new(0, 48, 0, 28)
            ColorDisplay.Position = UDim2.new(1, -60, 0.5, -14)
            ColorDisplay.BackgroundColor3 = defaultColor or Color3.fromRGB(255, 0, 0)
            ColorDisplay.Text = ""
            Instance.new("UICorner", ColorDisplay).CornerRadius = UDim.new(0, 6)
            local DisplayStroke = Instance.new("UIStroke", ColorDisplay)
            DisplayStroke.Color = Color3.fromRGB(255, 255, 255)
            DisplayStroke.Thickness = 1.2

            local CurrentColor = defaultColor or Color3.fromRGB(255, 0, 0)
            local ColorPalette = nil

            local BasicColors = {
                Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0), Color3.fromRGB(200, 100, 0),
                Color3.fromRGB(100, 200, 0), Color3.fromRGB(0, 100, 200), Color3.fromRGB(200, 0, 100)
            }

            ColorDisplay.MouseButton1Click:Connect(function()
                if ColorPalette then
                    ColorPalette:Destroy()
                    ColorPalette = nil
                    TweenService:Create(CpFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 55)}):Play()
                else
                    TweenService:Create(CpFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 130)}):Play()
                    
                    ColorPalette = Instance.new("Frame", CpFrame)
                    ColorPalette.Size = UDim2.new(1, -24, 0, 65)
                    ColorPalette.Position = UDim2.new(0, 12, 0, 55)
                    ColorPalette.BackgroundTransparency = 1

                    local PalLayout = Instance.new("UIListLayout", ColorPalette)
                    PalLayout.FillDirection = Enum.FillDirection.Horizontal
                    PalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    PalLayout.Padding = UDim.new(0, 5)
                    PalLayout.VerticalAlignment = Enum.VerticalAlignment.Center

                    for _, col in ipairs(BasicColors) do
                        local ColBtn = Instance.new("TextButton", ColorPalette)
                        ColBtn.Size = UDim2.new(0, 26, 0, 26)
                        ColBtn.BackgroundColor3 = col
                        ColBtn.Text = ""
                        Instance.new("UICorner", ColBtn).CornerRadius = UDim.new(0.5, 0)
                        local InnerStroke = Instance.new("UIStroke", ColBtn)
                        InnerStroke.Color = Color3.fromRGB(80, 80, 80)
                        InnerStroke.Thickness = 1.2

                        ColBtn.MouseEnter:Connect(function()
                            InnerStroke.Color = Color3.fromRGB(255, 255, 255)
                            InnerStroke.Thickness = 1.8
                        end)
                        ColBtn.MouseLeave:Connect(function()
                            InnerStroke.Color = Color3.fromRGB(80, 80, 80)
                            InnerStroke.Thickness = 1.2
                        end)

                        ColBtn.MouseButton1Click:Connect(function()
                            CurrentColor = col
                            ColorDisplay.BackgroundColor3 = col
                            pcall(callback, col)
                            ColorPalette:Destroy()
                            ColorPalette = nil
                            TweenService:Create(CpFrame, TweenInfo.new(0.2), {Size = UDim2.new(1, -10, 0, 55)}):Play()
                        end)
                    end
                end
            end)
        end

        -- ==================== DIVIDER ====================
        function TabFunctions:CreateDivider()
            local DividerFrame = Instance.new("Frame", ContentPage)
            DividerFrame.Size = UDim2.new(1, -10, 0, 2)
            DividerFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            DividerFrame.BorderSizePixel = 0
        end

        return TabFunctions
    end

    return WindowFunctions
end

return Library
