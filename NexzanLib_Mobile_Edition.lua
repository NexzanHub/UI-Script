--[=[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         NEXZAN HUB - Mobile Edition (Minimalized)             ║
    ║         Optimized for Mobile Exploit Clients                  ║
    ║              Version: 1.0.0 (Mobile Optimized)                ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    Mobile Features:
    ✅ Compact UI (Mobile Friendly Size)
    ✅ Touch-Optimized Buttons
    ✅ Minimized by Default
    ✅ Quick Access Navbar
    ✅ All Components (Optimized)
    ✅ Advanced Key System
    ✅ Smooth Mobile Animations
    ✅ Responsive Design
]=]

local NexzanLibMobile = {}
NexzanLibMobile.Version = "1.0.0_Mobile"

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- Constants
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration Storage
local ConfigFolder = "NexzanHub_Mobile"
local ConfigExtension = ".json"

-- Create Config Folder
if not isfolder(ConfigFolder) then
    makefolder(ConfigFolder)
end

-- Themes
NexzanLibMobile.Themes = {
    Dark = {
        Primary = Color3.fromRGB(30, 30, 35),
        Secondary = Color3.fromRGB(40, 40, 45),
        Accent = Color3.fromRGB(100, 200, 255),
        Text = Color3.fromRGB(230, 230, 230),
        Danger = Color3.fromRGB(255, 100, 100),
        Success = Color3.fromRGB(100, 255, 150),
        Warning = Color3.fromRGB(255, 200, 100),
    },
    Neon = {
        Primary = Color3.fromRGB(15, 15, 25),
        Secondary = Color3.fromRGB(30, 30, 50),
        Accent = Color3.fromRGB(0, 255, 200),
        Text = Color3.fromRGB(240, 240, 255),
        Danger = Color3.fromRGB(255, 50, 100),
        Success = Color3.fromRGB(100, 255, 200),
        Warning = Color3.fromRGB(255, 180, 50),
    },
    Royal = {
        Primary = Color3.fromRGB(20, 25, 50),
        Secondary = Color3.fromRGB(35, 45, 80),
        Accent = Color3.fromRGB(150, 100, 255),
        Text = Color3.fromRGB(235, 235, 250),
        Danger = Color3.fromRGB(255, 80, 120),
        Success = Color3.fromRGB(120, 255, 180),
        Warning = Color3.fromRGB(255, 200, 80),
    },
}

-- Default Theme
NexzanLibMobile.CurrentTheme = NexzanLibMobile.Themes.Dark

-- Main Library Table
local Library = {}
Library.Windows = {}
Library.Notifications = {}

-- ==================== UTILITY FUNCTIONS ====================

local function CreateInstance(ClassName, Parent, Properties)
    local Instance = Instance.new(ClassName)
    Instance.Parent = Parent
    
    if Properties then
        for Property, Value in pairs(Properties) do
            if pcall(function() Instance[Property] = Value end) then end
        end
    end
    
    return Instance
end

local function Tween(Object, Properties, Duration)
    Duration = Duration or 0.3
    local TweenService = game:GetService("TweenService")
    local TweenInfo = TweenInfo.new(
        Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    Tween:Play()
    return Tween
end

-- ==================== KEY SYSTEM ====================

local KeySystemEnabled = false
local ValidKeys = {}
local KeyFilePath = ConfigFolder .. "/KeySystem"

local function InitKeySystem(Keys, Options)
    Options = Options or {}
    
    if not isfolder(KeyFilePath) then
        makefolder(KeyFilePath)
    end
    
    KeySystemEnabled = true
    
    -- Fetch keys from URL if enabled
    if Options.GrabKeyFromSite then
        for i, KeyURL in ipairs(Keys) do
            local Success, Response = pcall(function()
                return game:HttpGet(KeyURL)
            end)
            if Success then
                -- Remove whitespace
                local CleanedKey = Response:gsub("[\n\r\t ]", "")
                table.insert(ValidKeys, CleanedKey)
            end
        end
    else
        ValidKeys = Keys
    end
    
    return true
end

local function CheckSavedKey(FileName)
    local FilePath = KeyFilePath .. "/" .. FileName .. ConfigExtension
    
    if isfile(FilePath) then
        local SavedKey = readfile(FilePath)
        for _, ValidKey in ipairs(ValidKeys) do
            if SavedKey == ValidKey then
                return true
            end
        end
    end
    
    return false
end

local function SaveKey(FileName, Key)
    local FilePath = KeyFilePath .. "/" .. FileName .. ConfigExtension
    writefile(FilePath, Key)
end

local function ShowKeyUI(Options)
    Options = Options or {}
    
    -- Mobile optimized size
    local ScreenSize = CoreGui.Parent.AbsoluteSize
    local IsMobile = UserInputService.TouchEnabled
    local KeyScreenSize = IsMobile and UDim2.new(0, 320, 0, 280) or UDim2.new(0, 400, 0, 300)
    
    local KeyScreen = CreateInstance("ScreenGui", CoreGui, {
        Name = "NexzanKeySystem_Mobile",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    -- Background
    local Background = CreateInstance("Frame", KeyScreen, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    })
    
    -- Main Panel
    local Panel = CreateInstance("Frame", Background, {
        Name = "Panel",
        Size = KeyScreenSize,
        Position = UDim2.new(0.5, -KeyScreenSize.X.Offset/2, 0.5, -KeyScreenSize.Y.Offset/2),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    -- Corner
    CreateInstance("UICorner", Panel, { CornerRadius = UDim.new(0, 12) })
    
    -- Stroke
    CreateInstance("UIStroke", Panel, {
        Color = NexzanLibMobile.CurrentTheme.Accent,
        Thickness = 2,
    })
    
    -- Title
    CreateInstance("TextLabel", Panel, {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = Options.Title or "🔐 KEY",
        TextColor3 = NexzanLibMobile.CurrentTheme.Text,
        TextSize = IsMobile and 18 or 24,
        Font = Enum.Font.GothamBold,
    })
    
    -- Subtitle
    CreateInstance("TextLabel", Panel, {
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 25),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = Options.Subtitle or "ENTER KEY",
        TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
        TextSize = IsMobile and 11 or 14,
        Font = Enum.Font.Gotham,
    })
    
    -- Note
    CreateInstance("TextLabel", Panel, {
        Name = "Note",
        Size = UDim2.new(1, -15, 0, 30),
        Position = UDim2.new(0, 7, 0, 75),
        BackgroundTransparency = 1,
        Text = Options.Note or "Get key from Discord",
        TextColor3 = NexzanLibMobile.CurrentTheme.Text,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
    })
    
    -- Input Box
    local InputBox = CreateInstance("TextBox", Panel, {
        Name = "InputBox",
        Size = UDim2.new(1, -15, 0, 35),
        Position = UDim2.new(0, 7, 0, 110),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
        TextColor3 = NexzanLibMobile.CurrentTheme.Text,
        PlaceholderText = "Paste key...",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
    })
    
    CreateInstance("UICorner", InputBox, { CornerRadius = UDim.new(0, 8) })
    CreateInstance("UIStroke", InputBox, {
        Color = NexzanLibMobile.CurrentTheme.Accent,
        Thickness = 1,
    })
    
    -- Submit Button
    local SubmitButton = CreateInstance("TextButton", Panel, {
        Name = "SubmitButton",
        Size = UDim2.new(1, -15, 0, 32),
        Position = UDim2.new(0, 7, 0, 155),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        Text = "VERIFY",
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", SubmitButton, { CornerRadius = UDim.new(0, 8) })
    
    -- Status Label
    local StatusLabel = CreateInstance("TextLabel", Panel, {
        Name = "Status",
        Size = UDim2.new(1, -15, 0, 18),
        Position = UDim2.new(0, 7, 0, 200),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = NexzanLibMobile.CurrentTheme.Danger,
        TextSize = 10,
        Font = Enum.Font.Gotham,
    })
    
    local Attempts = 3
    
    SubmitButton.MouseButton1Click:Connect(function()
        local Key = InputBox.Text
        
        local KeyValid = false
        for _, ValidKey in ipairs(ValidKeys) do
            if Key == ValidKey then
                KeyValid = true
                break
            end
        end
        
        if KeyValid then
            StatusLabel.Text = "✅ Valid!"
            StatusLabel.TextColor3 = NexzanLibMobile.CurrentTheme.Success
            
            if Options.SaveKey then
                SaveKey(Options.FileName or "Key", Key)
            end
            
            wait(1)
            KeyScreen:Destroy()
        else
            Attempts = Attempts - 1
            StatusLabel.Text = "❌ Invalid! (" .. Attempts .. ")"
            
            if Attempts <= 0 then
                KeyScreen:Destroy()
                game:Shutdown()
            end
            
            InputBox.Text = ""
        end
    end)
    
    -- Enter key binding
    InputBox.FocusLost:Connect(function(EnterPressed)
        if EnterPressed then
            SubmitButton:Fire()
        end
    end)
    
    InputBox:CaptureFocus()
end

-- ==================== MOBILE WINDOW CREATION ====================

function NexzanLibMobile:CreateWindow(Options)
    Options = Options or {}
    
    -- Detect mobile
    local IsMobile = UserInputService.TouchEnabled
    local WindowWidth = IsMobile and 300 or 400
    local WindowHeight = IsMobile and 400 or 500
    
    -- Initialize Key System if enabled
    if Options.KeySystem then
        local KeyOpts = Options.KeySettings or {}
        
        -- Check for saved key first
        if KeyOpts.FileName and KeyOpts.SaveKey then
            if CheckSavedKey(KeyOpts.FileName) then
                -- Key already saved and valid
            else
                InitKeySystem(KeyOpts.Key or {}, {
                    GrabKeyFromSite = KeyOpts.GrabKeyFromSite or false
                })
                ShowKeyUI({
                    Title = KeyOpts.Title or "🔐 KEY",
                    Subtitle = KeyOpts.Subtitle or "ENTER KEY",
                    Note = KeyOpts.Note or "Get key from Discord",
                    FileName = KeyOpts.FileName,
                    SaveKey = KeyOpts.SaveKey or true,
                })
            end
        else
            InitKeySystem(KeyOpts.Key or {}, {
                GrabKeyFromSite = KeyOpts.GrabKeyFromSite or false
            })
            ShowKeyUI({
                Title = KeyOpts.Title or "🔐 KEY",
                Subtitle = KeyOpts.Subtitle or "ENTER KEY",
                Note = KeyOpts.Note or "Get key from Discord",
                FileName = KeyOpts.FileName,
                SaveKey = KeyOpts.SaveKey or true,
            })
        end
    end
    
    -- Set theme if specified
    if Options.Theme then
        NexzanLibMobile.CurrentTheme = NexzanLibMobile.Themes[Options.Theme] or NexzanLibMobile.Themes.Dark
    end
    
    local Window = {
        Name = Options.Name or "Nexzan",
        Tabs = {},
        Elements = {},
        Config = Options.ConfigurationSaving or {},
        IsMobile = IsMobile
    }
    
    -- Create main ScreenGui
    local ScreenGui = CreateInstance("ScreenGui", CoreGui, {
        Name = "NexzanHub_Mobile_" .. Options.Name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    Window.ScreenGui = ScreenGui
    
    -- Create main frame (MINIMIZED BY DEFAULT ON MOBILE)
    local MainFrame = CreateInstance("Frame", ScreenGui, {
        Name = "MainFrame",
        Size = IsMobile and UDim2.new(0, 50, 0, 50) or UDim2.new(0, WindowWidth, 0, WindowHeight),
        Position = UDim2.new(1, -65, 0, 20),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", MainFrame, { CornerRadius = UDim.new(0, 12) })
    
    -- Stroke
    CreateInstance("UIStroke", MainFrame, {
        Color = NexzanLibMobile.CurrentTheme.Accent,
        Thickness = 2,
    })
    
    Window.MainFrame = MainFrame
    
    -- ==================== MOBILE MINIMIZE BUTTON ====================
    
    local MinimizeBtn = CreateInstance("TextButton", MainFrame, {
        Name = "MinimizeBtn",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
        Text = "✨",
        TextSize = 24,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", MinimizeBtn, { CornerRadius = UDim.new(0, 12) })
    
    local IsMinimized = IsMobile and true or false
    
    -- Create topbar (HIDDEN WHEN MINIMIZED)
    local Topbar = CreateInstance("Frame", MainFrame, {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Visible = not IsMinimized,
    })
    
    CreateInstance("UICorner", Topbar, { CornerRadius = UDim.new(0, 12) })
    
    -- Title
    CreateInstance("TextLabel", Topbar, {
        Name = "Title",
        Size = UDim2.new(1, -90, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "✨ " .. Options.Name,
        TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
        TextSize = IsMobile and 12 or 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Minimize btn in topbar
    local TopMinBtn = CreateInstance("TextButton", Topbar, {
        Name = "MinBtn",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -80, 0, 7),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        Text = "━",
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", TopMinBtn, { CornerRadius = UDim.new(0, 6) })
    
    -- Close button
    local CloseBtn = CreateInstance("TextButton", Topbar, {
        Name = "CloseBtn",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -40, 0, 7),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Danger,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "✕",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", CloseBtn, { CornerRadius = UDim.new(0, 6) })
    
    local function ToggleMinimize()
        IsMinimized = not IsMinimized
        
        if IsMinimized then
            Tween(MainFrame, {
                Size = UDim2.new(0, 50, 0, 50)
            }, 0.3)
            Topbar.Visible = false
            MinimizeBtn.Visible = true
        else
            Tween(MainFrame, {
                Size = UDim2.new(0, IsMobile and 320 or WindowWidth, 0, IsMobile and 450 or WindowHeight)
            }, 0.3)
            wait(0.3)
            Topbar.Visible = true
            MinimizeBtn.Visible = false
        end
    end
    
    MinimizeBtn.MouseButton1Click:Connect(ToggleMinimize)
    TopMinBtn.MouseButton1Click:Connect(ToggleMinimize)
    
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Parent = nil
    end)
    
    -- Create tab bar
    local TabBar = CreateInstance("Frame", MainFrame, {
        Name = "TabBar",
        Size = UDim2.new(0, IsMobile and 100 or 150, 1, -50),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
        BorderSizePixel = 0,
        Visible = not IsMinimized,
    })
    
    CreateInstance("UICorner", TabBar, { CornerRadius = UDim.new(0, 12) })
    
    local TabList = CreateInstance("Frame", TabBar, {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UIListLayout", TabList, {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    Window.TabBar = TabBar
    Window.TabList = TabList
    
    -- Create content area
    local ContentArea = CreateInstance("Frame", MainFrame, {
        Name = "ContentArea",
        Size = UDim2.new(1, -(IsMobile and 100 or 150), 1, -50),
        Position = UDim2.new(0, IsMobile and 100 or 150, 0, 50),
        BackgroundColor3 = NexzanLibMobile.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Visible = not IsMinimized,
    })
    
    CreateInstance("UICorner", ContentArea, { CornerRadius = UDim.new(0, 12) })
    
    Window.ContentArea = ContentArea
    
    -- Store window reference
    table.insert(Library.Windows, Window)
    
    -- ==================== TAB CREATION ====================
    
    function Window:CreateTab(TabName, Icon)
        local Tab = {
            Name = TabName,
            Sections = {},
            Parent = self
        }
        
        -- Create tab button
        local TabButton = CreateInstance("TextButton", self.TabList, {
            Name = TabName,
            Size = UDim2.new(1, -6, 0, IsMobile and 35 or 40),
            BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
            TextColor3 = NexzanLibMobile.CurrentTheme.Text,
            Text = (Icon or "•"),
            TextSize = IsMobile and 11 or 12,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", TabButton, { CornerRadius = UDim.new(0, 6) })
        
        -- Create tab content frame
        local TabContent = CreateInstance("Frame", self.ContentArea, {
            Name = TabName .. "_Content",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        })
        
        local ScrollingFrame = CreateInstance("ScrollingFrame", TabContent, {
            Name = "ScrollingFrame",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 6,
            ScrollBarImageColor3 = NexzanLibMobile.CurrentTheme.Accent,
        })
        
        CreateInstance("UIListLayout", ScrollingFrame, {
            Padding = UDim.new(0, 8),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.ScrollingFrame = ScrollingFrame
        
        -- Tab button click handler
        TabButton.MouseButton1Click:Connect(function()
            -- Hide all tabs
            for _, OtherTab in pairs(self.Tabs) do
                OtherTab.Content.Visible = false
                Tween(OtherTab.Button, { BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary }, 0.2)
            end
            
            -- Show current tab
            TabContent.Visible = true
            Tween(TabButton, { BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent }, 0.2)
        end)
        
        if #self.Tabs == 0 then
            TabContent.Visible = true
            Tween(TabButton, { BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent }, 0.2)
        end
        
        table.insert(self.Tabs, Tab)
        
        -- ==================== SECTION CREATION ====================
        
        function Tab:CreateSection(SectionName)
            local Section = {
                Name = SectionName,
                Elements = {}
            }
            
            local SectionFrame = CreateInstance("Frame", self.ScrollingFrame, {
                Name = SectionName .. "_Section",
                Size = UDim2.new(1, -8, 0, 0),
                BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UICorner", SectionFrame, { CornerRadius = UDim.new(0, 10) })
            CreateInstance("UIStroke", SectionFrame, {
                Color = NexzanLibMobile.CurrentTheme.Accent,
                Thickness = 1,
            })
            
            local SectionPadding = CreateInstance("UIPadding", SectionFrame, {
                PaddingTop = UDim.new(0, 12),
                PaddingBottom = UDim.new(0, 12),
                PaddingLeft = UDim.new(0, 12),
                PaddingRight = UDim.new(0, 12),
            })
            
            -- Section title
            local SectionTitle = CreateInstance("TextLabel", SectionFrame, {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = "■ " .. SectionName,
                TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
                TextSize = IsMobile and 11 or 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ElementList = CreateInstance("Frame", SectionFrame, {
                Name = "ElementList",
                Size = UDim2.new(1, 0, 1, -25),
                Position = UDim2.new(0, 0, 0, 25),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UIListLayout", ElementList, {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            Section.Frame = SectionFrame
            Section.ElementList = ElementList
            
            -- ==================== ELEMENTS (MOBILE OPTIMIZED) ====================
            
            function Section:AddButton(Options)
                Options = Options or {}
                
                local Button = CreateInstance("TextButton", self.ElementList, {
                    Name = Options.Name or "Button",
                    Size = UDim2.new(1, 0, 0, IsMobile and 32 or 35),
                    BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    Text = Options.Name or "Button",
                    TextSize = IsMobile and 11 or 12,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Button, { CornerRadius = UDim.new(0, 6) })
                
                Button.MouseButton1Click:Connect(function()
                    if Options.Callback then
                        Options.Callback()
                    end
                    
                    -- Click effect
                    Tween(Button, { BackgroundColor3 = Color3.fromRGB(150, 220, 255) }, 0.1)
                    wait(0.1)
                    Tween(Button, { BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent }, 0.1)
                end)
                
                return Button
            end
            
            function Section:AddToggle(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Toggle",
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                -- Label
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, -40, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Toggle",
                    TextColor3 = NexzanLibMobile.CurrentTheme.Text,
                    TextSize = IsMobile and 10 or 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                -- Toggle button
                local ToggleButton = CreateInstance("Frame", Container, {
                    Name = "ToggleButton",
                    Size = UDim2.new(0, 38, 0, 18),
                    Position = UDim2.new(1, -43, 0.5, -9),
                    BackgroundColor3 = Color3.fromRGB(60, 60, 65),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", ToggleButton, { CornerRadius = UDim.new(0, 9) })
                
                -- Toggle circle
                local Circle = CreateInstance("Frame", ToggleButton, {
                    Name = "Circle",
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 2, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Circle, { CornerRadius = UDim.new(1, 0) })
                
                local IsToggled = Options.CurrentValue or false
                
                if IsToggled then
                    Tween(ToggleButton, { BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent }, 0)
                    Tween(Circle, { Position = UDim2.new(0, 22, 0.5, -7) }, 0)
                end
                
                -- Click handler
                local ClickRegion = CreateInstance("TextButton", Container, {
                    Name = "ClickRegion",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                })
                
                ClickRegion.MouseButton1Click:Connect(function()
                    IsToggled = not IsToggled
                    
                    local NewColor = IsToggled and NexzanLibMobile.CurrentTheme.Accent or Color3.fromRGB(60, 60, 65)
                    local NewPos = IsToggled and UDim2.new(0, 22, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    
                    Tween(ToggleButton, { BackgroundColor3 = NewColor }, 0.2)
                    Tween(Circle, { Position = NewPos }, 0.2)
                    
                    if Options.Callback then
                        Options.Callback(IsToggled)
                    end
                end)
                
                return Container
            end
            
            function Section:AddSlider(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Slider",
                    Size = UDim2.new(1, 0, 0, 36),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                -- Label
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 14),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Slider",
                    TextColor3 = NexzanLibMobile.CurrentTheme.Text,
                    TextSize = IsMobile and 10 or 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                -- Slider background
                local SliderBg = CreateInstance("Frame", Container, {
                    Name = "SliderBg",
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", SliderBg, { CornerRadius = UDim.new(0, 2) })
                
                -- Slider fill
                local SliderFill = CreateInstance("Frame", SliderBg, {
                    Name = "SliderFill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = NexzanLibMobile.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", SliderFill, { CornerRadius = UDim.new(0, 2) })
                
                local Min = Options.Min or 0
                local Max = Options.Max or 100
                local Default = Options.Default or Min
                
                local CurrentValue = Default
                
                local function UpdateSlider(InputX)
                    local RelativeX = InputX - SliderBg.AbsolutePosition.X
                    local Percentage = math.clamp(RelativeX / SliderBg.AbsoluteSize.X, 0, 1)
                    CurrentValue = math.round(Min + (Max - Min) * Percentage)
                    
                    SliderFill.Size = UDim2.new(Percentage, 0, 1, 0)
                    
                    if Options.Callback then
                        Options.Callback(CurrentValue)
                    end
                end
                
                SliderBg.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        UpdateSlider(input.Position.X)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input, gameProcessed)
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        if UserInputService:IsMouseButtonPressed(Enum.UserInputButton.Left) then
                            UpdateSlider(input.Position.X)
                        end
                    end
                end)
                
                -- Initialize
                local InitPercentage = (Default - Min) / (Max - Min)
                SliderFill.Size = UDim2.new(InitPercentage, 0, 1, 0)
                
                return Container
            end
            
            function Section:AddInput(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Input",
                    Size = UDim2.new(1, 0, 0, 32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                -- Input box (Full width on mobile)
                local InputBox = CreateInstance("TextBox", Container, {
                    Name = "InputBox",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
                    TextColor3 = NexzanLibMobile.CurrentTheme.Text,
                    PlaceholderText = Options.Placeholder or "Enter text...",
                    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = IsMobile and 11 or 12,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", InputBox, { CornerRadius = UDim.new(0, 6) })
                CreateInstance("UIStroke", InputBox, {
                    Color = NexzanLibMobile.CurrentTheme.Accent,
                    Thickness = 1,
                })
                
                InputBox.FocusLost:Connect(function()
                    if Options.Callback then
                        Options.Callback(InputBox.Text)
                    end
                end)
                
                return Container
            end
            
            function Section:AddLabel(Text)
                local Label = CreateInstance("TextLabel", self.ElementList, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = Text or "Label",
                    TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
                    TextSize = IsMobile and 10 or 11,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                return Label
            end
            
            table.insert(self.Sections, Section)
            return Section
        end
        
        return Tab
    end
    
    -- ==================== NOTIFICATIONS ====================
    
    function Window:Notify(Options)
        Options = Options or {}
        
        local NotificationGui = CreateInstance("ScreenGui", CoreGui, {
            Name = "Notification_" .. math.random(1, 999),
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        
        local NotifSize = IsMobile and UDim2.new(0, 280, 0, 90) or UDim2.new(0, 350, 0, 100)
        
        local NotificationFrame = CreateInstance("Frame", NotificationGui, {
            Name = "Notification",
            Size = NotifSize,
            Position = UDim2.new(1, -10, 1, -10),
            BackgroundColor3 = NexzanLibMobile.CurrentTheme.Secondary,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", NotificationFrame, { CornerRadius = UDim.new(0, 10) })
        CreateInstance("UIStroke", NotificationFrame, {
            Color = Options.Color or NexzanLibMobile.CurrentTheme.Accent,
            Thickness = 2,
        })
        
        -- Title
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Title",
            Size = UDim2.new(1, -15, 0, 22),
            Position = UDim2.new(0, 8, 0, 4),
            BackgroundTransparency = 1,
            Text = Options.Title or "Notification",
            TextColor3 = NexzanLibMobile.CurrentTheme.Accent,
            TextSize = IsMobile and 12 or 13,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        -- Content
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Content",
            Size = UDim2.new(1, -15, 1, -32),
            Position = UDim2.new(0, 8, 0, 30),
            BackgroundTransparency = 1,
            Text = Options.Content or "Message",
            TextColor3 = NexzanLibMobile.CurrentTheme.Text,
            TextSize = IsMobile and 10 or 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        
        -- Animation
        Tween(NotificationFrame, {
            Position = IsMobile and UDim2.new(1, -300, 1, -110) or UDim2.new(1, -370, 1, -120)
        }, 0.3)
        
        wait(Options.Duration or 3)
        
        Tween(NotificationFrame, {
            Position = UDim2.new(1, -10, 1, -10)
        }, 0.3)
        
        wait(0.3)
        NotificationGui:Destroy()
    end
    
    return Window
end

-- ==================== EXPORT ====================

return NexzanLibMobile
