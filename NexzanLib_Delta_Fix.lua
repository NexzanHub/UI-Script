--[=[
    ╔═══════════════════════════════════════════════════════════════╗
    ║            NEXZAN HUB - Fixed for Delta Executor              ║
    ║              Futuristic Design for Roblox Exploits            ║
    ║                   Version: 1.0.1 (Delta Compatible)           ║
    ╚═══════════════════════════════════════════════════════════════╝
]=]

local NexzanLib = {}
NexzanLib.Version = "1.0.1_Delta"

-- ==================== COMPATIBILITY CHECK ====================

local Success, CoreGui = pcall(function()
    return game:GetService("CoreGui")
end)

if not Success then
    warn("⚠️ CoreGui not available")
    return nil
end

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local ConfigFolder = "NexzanHub_Config"
local ConfigExtension = ".json"

-- Create Config Folder (safe check)
if not isfolder(ConfigFolder) then
    pcall(function()
        makefolder(ConfigFolder)
    end)
end

-- ==================== THEMES ====================

NexzanLib.Themes = {
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

NexzanLib.CurrentTheme = NexzanLib.Themes.Dark

-- Main Library
local Library = {}
Library.Windows = {}
Library.Notifications = {}

-- ==================== UTILITY FUNCTIONS ====================

local function CreateInstance(ClassName, Parent, Properties)
    local Instance = Instance.new(ClassName)
    
    if Properties then
        for Property, Value in pairs(Properties) do
            pcall(function()
                Instance[Property] = Value
            end)
        end
    end
    
    if Parent then
        Instance.Parent = Parent
    end
    
    return Instance
end

local function Tween(Object, Properties, Duration)
    if not Object or not Object.Parent then return end
    
    Duration = Duration or 0.3
    local TweenInfo = TweenInfo.new(
        Duration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    pcall(function()
        Tween:Play()
    end)
    
    return Tween
end

-- ==================== KEY SYSTEM ====================

local KeySystemEnabled = false
local ValidKeys = {}
local KeyFilePath = ConfigFolder .. "/KeySystem"

local function InitKeySystem(Keys, Options)
    Options = Options or {}
    KeySystemEnabled = true
    
    pcall(function()
        if not isfolder(KeyFilePath) then
            makefolder(KeyFilePath)
        end
    end)
    
    if Options.GrabKeyFromSite then
        for i, KeyURL in ipairs(Keys) do
            local Success, Response = pcall(function()
                return game:HttpGet(KeyURL)
            end)
            if Success then
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
    
    local FileExists = pcall(function()
        return isfile(FilePath)
    end)
    
    if FileExists then
        local Success, SavedKey = pcall(function()
            return readfile(FilePath)
        end)
        
        if Success then
            for _, ValidKey in ipairs(ValidKeys) do
                if SavedKey == ValidKey then
                    return true
                end
            end
        end
    end
    
    return false
end

local function SaveKey(FileName, Key)
    pcall(function()
        local FilePath = KeyFilePath .. "/" .. FileName .. ConfigExtension
        writefile(FilePath, Key)
    end)
end

local function ShowKeyUI(Options)
    Options = Options or {}
    
    local KeyScreen = CreateInstance("ScreenGui", CoreGui, {
        Name = "NexzanKeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    -- Background
    CreateInstance("Frame", KeyScreen, {
        Name = "Background",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    })
    
    -- Main Panel
    local Panel = CreateInstance("Frame", KeyScreen, {
        Name = "Panel",
        Size = UDim2.new(0, 400, 0, 300),
        Position = UDim2.new(0.5, -200, 0.5, -150),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", Panel, { CornerRadius = UDim.new(0, 12) })
    CreateInstance("UIStroke", Panel, {
        Color = NexzanLib.CurrentTheme.Accent,
        Thickness = 2,
    })
    
    -- Title
    CreateInstance("TextLabel", Panel, {
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = Options.Title or "🔐 KEY SYSTEM",
        TextColor3 = NexzanLib.CurrentTheme.Text,
        TextSize = 24,
        Font = Enum.Font.GothamBold,
    })
    
    -- Subtitle
    CreateInstance("TextLabel", Panel, {
        Name = "Subtitle",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 50),
        BackgroundTransparency = 1,
        Text = Options.Subtitle or "ENTER YOUR KEY",
        TextColor3 = NexzanLib.CurrentTheme.Accent,
        TextSize = 14,
        Font = Enum.Font.Gotham,
    })
    
    -- Input Box
    local InputBox = CreateInstance("TextBox", Panel, {
        Name = "InputBox",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 110),
        BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
        TextColor3 = NexzanLib.CurrentTheme.Text,
        PlaceholderText = "Paste your key here...",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
        TextSize = 14,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", InputBox, { CornerRadius = UDim.new(0, 8) })
    CreateInstance("UIStroke", InputBox, {
        Color = NexzanLib.CurrentTheme.Accent,
        Thickness = 1,
    })
    
    -- Submit Button
    local SubmitButton = CreateInstance("TextButton", Panel, {
        Name = "SubmitButton",
        Size = UDim2.new(1, -20, 0, 35),
        Position = UDim2.new(0, 10, 0, 165),
        BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        Text = "VERIFY KEY",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", SubmitButton, { CornerRadius = UDim.new(0, 8) })
    
    -- Status Label
    local StatusLabel = CreateInstance("TextLabel", Panel, {
        Name = "Status",
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 10, 0, 210),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = NexzanLib.CurrentTheme.Danger,
        TextSize = 11,
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
            StatusLabel.Text = "✅ Key Valid!"
            StatusLabel.TextColor3 = NexzanLib.CurrentTheme.Success
            
            if Options.SaveKey then
                SaveKey(Options.FileName or "Key", Key)
            end
            
            wait(1)
            KeyScreen:Destroy()
        else
            Attempts = Attempts - 1
            StatusLabel.Text = "❌ Invalid Key! (" .. Attempts .. " attempts left)"
            
            if Attempts <= 0 then
                KeyScreen:Destroy()
                pcall(function()
                    game:Shutdown()
                end)
            end
            
            InputBox.Text = ""
        end
    end)
    
    InputBox:CaptureFocus()
end

-- ==================== WINDOW CREATION ====================

function NexzanLib:CreateWindow(Options)
    Options = Options or {}
    
    -- Initialize Key System
    if Options.KeySystem then
        local KeyOpts = Options.KeySettings or {}
        
        if KeyOpts.FileName and KeyOpts.SaveKey then
            if CheckSavedKey(KeyOpts.FileName) then
                -- Key válido
            else
                InitKeySystem(KeyOpts.Key or {}, {
                    GrabKeyFromSite = KeyOpts.GrabKeyFromSite or false
                })
                ShowKeyUI({
                    Title = KeyOpts.Title or "🔐 KEY SYSTEM",
                    Subtitle = KeyOpts.Subtitle or "ENTER YOUR KEY",
                    FileName = KeyOpts.FileName,
                    SaveKey = KeyOpts.SaveKey or true,
                })
            end
        else
            InitKeySystem(KeyOpts.Key or {}, {
                GrabKeyFromSite = KeyOpts.GrabKeyFromSite or false
            })
            ShowKeyUI({
                Title = KeyOpts.Title or "🔐 KEY SYSTEM",
                Subtitle = KeyOpts.Subtitle or "ENTER YOUR KEY",
                FileName = KeyOpts.FileName,
                SaveKey = KeyOpts.SaveKey or true,
            })
        end
    end
    
    -- Set Theme
    if Options.Theme then
        NexzanLib.CurrentTheme = NexzanLib.Themes[Options.Theme] or NexzanLib.Themes.Dark
    end
    
    local Window = {
        Name = Options.Name or "Nexzan Hub",
        Tabs = {},
        Elements = {},
        Config = Options.ConfigurationSaving or {}
    }
    
    -- Create ScreenGui
    local ScreenGui = CreateInstance("ScreenGui", CoreGui, {
        Name = "NexzanHub_" .. Options.Name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    Window.ScreenGui = ScreenGui
    
    -- Main Frame
    local MainFrame = CreateInstance("Frame", ScreenGui, {
        Name = "MainFrame",
        Size = Options.Size or UDim2.new(0, 800, 0, 600),
        Position = Options.Position or UDim2.new(0.5, -400, 0.5, -300),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", MainFrame, { CornerRadius = UDim.new(0, 16) })
    CreateInstance("UIStroke", MainFrame, {
        Color = NexzanLib.CurrentTheme.Accent,
        Thickness = 2,
    })
    
    Window.MainFrame = MainFrame
    
    -- Make Draggable (safe way)
    local isDragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    MainFrame.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input == dragInput and isDragging then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input == dragInput then
            isDragging = false
        end
    end)
    
    -- Topbar
    local Topbar = CreateInstance("Frame", MainFrame, {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", Topbar, { CornerRadius = UDim.new(0, 16) })
    
    -- Title
    CreateInstance("TextLabel", Topbar, {
        Name = "Title",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "✨ " .. Options.Name .. " ✨",
        TextColor3 = NexzanLib.CurrentTheme.Accent,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Minimize Button
    local MinimizeBtn = CreateInstance("TextButton", Topbar, {
        Name = "MinimizeBtn",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -80, 0, 12),
        BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
        TextColor3 = Color3.fromRGB(0, 0, 0),
        Text = "━",
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", MinimizeBtn, { CornerRadius = UDim.new(0, 8) })
    
    -- Close Button
    local CloseBtn = CreateInstance("TextButton", Topbar, {
        Name = "CloseBtn",
        Size = UDim2.new(0, 35, 0, 35),
        Position = UDim2.new(1, -40, 0, 12),
        BackgroundColor3 = NexzanLib.CurrentTheme.Danger,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "✕",
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", CloseBtn, { CornerRadius = UDim.new(0, 8) })
    
    local IsMinimized = false
    
    MinimizeBtn.MouseButton1Click:Connect(function()
        IsMinimized = not IsMinimized
        Tween(MainFrame, {
            Size = IsMinimized and UDim2.new(0, 800, 0, 60) or UDim2.new(0, 800, 0, 600)
        }, 0.3)
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Parent = nil
    end)
    
    -- Tab Bar
    local TabBar = CreateInstance("Frame", MainFrame, {
        Name = "TabBar",
        Size = UDim2.new(0, 200, 1, -60),
        Position = UDim2.new(0, 0, 0, 60),
        BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", TabBar, { CornerRadius = UDim.new(0, 16) })
    
    local TabList = CreateInstance("Frame", TabBar, {
        Name = "TabList",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UIListLayout", TabList, {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })
    
    Window.TabBar = TabBar
    Window.TabList = TabList
    
    -- Content Area
    local ContentArea = CreateInstance("Frame", MainFrame, {
        Name = "ContentArea",
        Size = UDim2.new(1, -200, 1, -60),
        Position = UDim2.new(0, 200, 0, 60),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", ContentArea, { CornerRadius = UDim.new(0, 16) })
    
    Window.ContentArea = ContentArea
    
    table.insert(Library.Windows, Window)
    
    -- ==================== TAB CREATION ====================
    
    function Window:CreateTab(TabName, Icon)
        local Tab = {
            Name = TabName,
            Sections = {},
            Parent = self
        }
        
        local TabButton = CreateInstance("TextButton", self.TabList, {
            Name = TabName,
            Size = UDim2.new(1, -10, 0, 40),
            BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
            TextColor3 = NexzanLib.CurrentTheme.Text,
            Text = (Icon or "•") .. " " .. TabName,
            TextSize = 13,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", TabButton, { CornerRadius = UDim.new(0, 8) })
        
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
            ScrollBarThickness = 8,
            ScrollBarImageColor3 = NexzanLib.CurrentTheme.Accent,
        })
        
        CreateInstance("UIListLayout", ScrollingFrame, {
            Padding = UDim.new(0, 10),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.ScrollingFrame = ScrollingFrame
        
        TabButton.MouseButton1Click:Connect(function()
            for _, OtherTab in pairs(self.Tabs) do
                OtherTab.Content.Visible = false
                Tween(OtherTab.Button, { BackgroundColor3 = NexzanLib.CurrentTheme.Secondary }, 0.2)
            end
            
            TabContent.Visible = true
            Tween(TabButton, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0.2)
        end)
        
        if #self.Tabs == 0 then
            TabContent.Visible = true
            Tween(TabButton, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0.2)
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
                Size = UDim2.new(1, -10, 0, 0),
                BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UICorner", SectionFrame, { CornerRadius = UDim.new(0, 12) })
            CreateInstance("UIStroke", SectionFrame, {
                Color = NexzanLib.CurrentTheme.Accent,
                Thickness = 1,
            })
            
            CreateInstance("UIPadding", SectionFrame, {
                PaddingTop = UDim.new(0, 15),
                PaddingBottom = UDim.new(0, 15),
                PaddingLeft = UDim.new(0, 15),
                PaddingRight = UDim.new(0, 15),
            })
            
            CreateInstance("TextLabel", SectionFrame, {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 25),
                BackgroundTransparency = 1,
                Text = "■ " .. SectionName,
                TextColor3 = NexzanLib.CurrentTheme.Accent,
                TextSize = 14,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ElementList = CreateInstance("Frame", SectionFrame, {
                Name = "ElementList",
                Size = UDim2.new(1, 0, 1, -30),
                Position = UDim2.new(0, 0, 0, 30),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UIListLayout", ElementList, {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            Section.Frame = SectionFrame
            Section.ElementList = ElementList
            
            -- ==================== ELEMENTS ====================
            
            function Section:AddButton(Options)
                Options = Options or {}
                
                local Button = CreateInstance("TextButton", self.ElementList, {
                    Name = Options.Name or "Button",
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    Text = Options.Name or "Button",
                    TextSize = 13,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Button, { CornerRadius = UDim.new(0, 8) })
                
                Button.MouseButton1Click:Connect(function()
                    pcall(function()
                        if Options.Callback then
                            Options.Callback()
                        end
                    end)
                    
                    Tween(Button, { BackgroundColor3 = Color3.fromRGB(150, 220, 255) }, 0.1)
                    wait(0.1)
                    Tween(Button, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0.1)
                end)
                
                return Button
            end
            
            function Section:AddToggle(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Toggle",
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, -40, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Toggle",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                local ToggleButton = CreateInstance("Frame", Container, {
                    Name = "ToggleButton",
                    Size = UDim2.new(0, 40, 0, 20),
                    Position = UDim2.new(1, -45, 0.5, -10),
                    BackgroundColor3 = Color3.fromRGB(60, 60, 65),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", ToggleButton, { CornerRadius = UDim.new(0, 10) })
                
                local Circle = CreateInstance("Frame", ToggleButton, {
                    Name = "Circle",
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(0, 2, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Circle, { CornerRadius = UDim.new(1, 0) })
                
                local IsToggled = Options.CurrentValue or false
                
                if IsToggled then
                    Tween(ToggleButton, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0)
                    Tween(Circle, { Position = UDim2.new(0, 22, 0.5, -8) }, 0)
                end
                
                local ClickRegion = CreateInstance("TextButton", Container, {
                    Name = "ClickRegion",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = "",
                })
                
                ClickRegion.MouseButton1Click:Connect(function()
                    IsToggled = not IsToggled
                    
                    local NewColor = IsToggled and NexzanLib.CurrentTheme.Accent or Color3.fromRGB(60, 60, 65)
                    local NewPos = IsToggled and UDim2.new(0, 22, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                    
                    Tween(ToggleButton, { BackgroundColor3 = NewColor }, 0.2)
                    Tween(Circle, { Position = NewPos }, 0.2)
                    
                    pcall(function()
                        if Options.Callback then
                            Options.Callback(IsToggled)
                        end
                    end)
                end)
                
                return Container
            end
            
            function Section:AddSlider(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Slider",
                    Size = UDim2.new(1, 0, 0, 40),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Slider",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                local SliderBg = CreateInstance("Frame", Container, {
                    Name = "SliderBg",
                    Size = UDim2.new(1, 0, 0, 6),
                    Position = UDim2.new(0, 0, 0, 20),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", SliderBg, { CornerRadius = UDim.new(0, 3) })
                
                local SliderFill = CreateInstance("Frame", SliderBg, {
                    Name = "SliderFill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", SliderFill, { CornerRadius = UDim.new(0, 3) })
                
                local Min = Options.Min or 0
                local Max = Options.Max or 100
                local Default = Options.Default or Min
                
                local CurrentValue = Default
                
                local function UpdateSlider(InputX)
                    local RelativeX = InputX - SliderBg.AbsolutePosition.X
                    local Percentage = math.clamp(RelativeX / SliderBg.AbsoluteSize.X, 0, 1)
                    CurrentValue = math.round(Min + (Max - Min) * Percentage)
                    
                    SliderFill.Size = UDim2.new(Percentage, 0, 1, 0)
                    
                    pcall(function()
                        if Options.Callback then
                            Options.Callback(CurrentValue)
                        end
                    end)
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
                
                local InitPercentage = (Default - Min) / (Max - Min)
                SliderFill.Size = UDim2.new(InitPercentage, 0, 1, 0)
                
                return Container
            end
            
            function Section:AddInput(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Input",
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(0, 100, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Input",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                local InputBox = CreateInstance("TextBox", Container, {
                    Name = "InputBox",
                    Size = UDim2.new(1, -110, 1, 0),
                    Position = UDim2.new(0, 105, 0, 0),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    PlaceholderText = Options.Placeholder or "Enter text...",
                    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = 12,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", InputBox, { CornerRadius = UDim.new(0, 6) })
                CreateInstance("UIStroke", InputBox, {
                    Color = NexzanLib.CurrentTheme.Accent,
                    Thickness = 1,
                })
                
                InputBox.FocusLost:Connect(function()
                    pcall(function()
                        if Options.Callback then
                            Options.Callback(InputBox.Text)
                        end
                    end)
                end)
                
                return Container
            end
            
            function Section:AddLabel(Text)
                local Label = CreateInstance("TextLabel", self.ElementList, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                    Text = Text or "Label",
                    TextColor3 = NexzanLib.CurrentTheme.Accent,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                return Label
            end
            
            function Section:AddParagraph(Title, Text)
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = "Paragraph",
                    Size = UDim2.new(1, 0, 0, 60),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Title",
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Title or "Title",
                    TextColor3 = NexzanLib.CurrentTheme.Accent,
                    TextSize = 12,
                    Font = Enum.Font.GothamBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Text",
                    Size = UDim2.new(1, 0, 1, -25),
                    Position = UDim2.new(0, 0, 0, 22),
                    BackgroundTransparency = 1,
                    Text = Text or "Content",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                })
                
                return Container
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
        
        local NotificationFrame = CreateInstance("Frame", NotificationGui, {
            Name = "Notification",
            Size = UDim2.new(0, 350, 0, 100),
            Position = UDim2.new(1, -10, 1, -10),
            BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", NotificationFrame, { CornerRadius = UDim.new(0, 12) })
        CreateInstance("UIStroke", NotificationFrame, {
            Color = Options.Color or NexzanLib.CurrentTheme.Accent,
            Thickness = 2,
        })
        
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 25),
            Position = UDim2.new(0, 10, 0, 5),
            BackgroundTransparency = 1,
            Text = Options.Title or "Notification",
            TextColor3 = NexzanLib.CurrentTheme.Accent,
            TextSize = 14,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Content",
            Size = UDim2.new(1, -20, 1, -35),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundTransparency = 1,
            Text = Options.Content or "Message",
            TextColor3 = NexzanLib.CurrentTheme.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        
        Tween(NotificationFrame, {
            Position = UDim2.new(1, -370, 1, -120)
        }, 0.3)
        
        wait(Options.Duration or 3)
        
        Tween(NotificationFrame, {
            Position = UDim2.new(1, -10, 1, -10)
        }, 0.3)
        
        wait(0.3)
        pcall(function()
            NotificationGui:Destroy()
        end)
    end
    
    return Window
end

print("✅ Nexzan Hub v1.0.1 loaded successfully!")
return NexzanLib
