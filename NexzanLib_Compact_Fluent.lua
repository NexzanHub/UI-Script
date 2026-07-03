--[=[
    ╔═══════════════════════════════════════════════════════════════╗
    ║         NEXZAN HUB - Compact Fluent Design (StyearX Style)    ║
    ║              Minimalist & Professional Themes                 ║
    ║                   Version: 2.0.0 (Compact)                    ║
    ╚═══════════════════════════════════════════════════════════════╝
]=]

local NexzanLib = {}
NexzanLib.Version = "2.0.0_Compact"

-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Success, CoreGui = pcall(function() return game:GetService("CoreGui") end)
if not Success then return nil end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Config
local ConfigFolder = "NexzanHub_Compact"
if not isfolder(ConfigFolder) then pcall(function() makefolder(ConfigFolder) end) end

-- ==================== FLUENT THEMES (StyearX Style) ====================

NexzanLib.Themes = {
    Fluent = {
        Primary = Color3.fromRGB(32, 32, 32),
        Secondary = Color3.fromRGB(45, 45, 45),
        Tertiary = Color3.fromRGB(55, 55, 55),
        Accent = Color3.fromRGB(0, 204, 255),
        Text = Color3.fromRGB(240, 240, 240),
        Danger = Color3.fromRGB(255, 84, 84),
        Success = Color3.fromRGB(52, 211, 153),
    },
    FluentDark = {
        Primary = Color3.fromRGB(25, 25, 25),
        Secondary = Color3.fromRGB(40, 40, 40),
        Tertiary = Color3.fromRGB(50, 50, 50),
        Accent = Color3.fromRGB(0, 180, 255),
        Text = Color3.fromRGB(230, 230, 230),
        Danger = Color3.fromRGB(255, 100, 100),
        Success = Color3.fromRGB(100, 255, 150),
    },
    FluentGray = {
        Primary = Color3.fromRGB(30, 30, 30),
        Secondary = Color3.fromRGB(42, 42, 42),
        Tertiary = Color3.fromRGB(52, 52, 52),
        Accent = Color3.fromRGB(100, 200, 255),
        Text = Color3.fromRGB(245, 245, 245),
        Danger = Color3.fromRGB(255, 80, 80),
        Success = Color3.fromRGB(80, 240, 160),
    },
}

NexzanLib.CurrentTheme = NexzanLib.Themes.Fluent

local Library = { Windows = {}, Notifications = {} }

-- ==================== UTILITY FUNCTIONS ====================

local function CreateInstance(ClassName, Parent, Properties)
    local Instance = Instance.new(ClassName)
    if Properties then
        for Property, Value in pairs(Properties) do
            pcall(function() Instance[Property] = Value end)
        end
    end
    if Parent then Instance.Parent = Parent end
    return Instance
end

local function Tween(Object, Properties, Duration)
    if not Object or not Object.Parent then return end
    Duration = Duration or 0.25
    local TweenInfo = TweenInfo.new(Duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    local Tween = TweenService:Create(Object, TweenInfo, Properties)
    pcall(function() Tween:Play() end)
    return Tween
end

-- ==================== WINDOW CREATION ====================

function NexzanLib:CreateWindow(Options)
    Options = Options or {}
    
    -- Set theme
    if Options.Theme then
        NexzanLib.CurrentTheme = NexzanLib.Themes[Options.Theme] or NexzanLib.Themes.Fluent
    end
    
    local Window = {
        Name = Options.Name or "Nexzan",
        Tabs = {},
    }
    
    -- Create ScreenGui (COMPACT SIZE)
    local ScreenGui = CreateInstance("ScreenGui", CoreGui, {
        Name = "NexzanHub_" .. Options.Name,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    Window.ScreenGui = ScreenGui
    
    -- COMPACT FRAME (400x500 - Kecil & Rapi)
    local MainFrame = CreateInstance("Frame", ScreenGui, {
        Name = "MainFrame",
        Size = Options.Size or UDim2.new(0, 420, 0, 500),
        Position = Options.Position or UDim2.new(0.5, -210, 0.5, -250),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", MainFrame, { CornerRadius = UDim.new(0, 12) })
    
    -- Smooth Stroke
    CreateInstance("UIStroke", MainFrame, {
        Color = NexzanLib.CurrentTheme.Secondary,
        Thickness = 1,
        Transparency = 0,
    })
    
    Window.MainFrame = MainFrame
    
    -- Draggable
    local isDragging = false
    local dragStart = nil
    local startPos = nil
    
    MainFrame.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if input == dragStart and isDragging then
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
        if input == dragStart then isDragging = false end
    end)
    
    -- ==================== TOPBAR (MINIMALIS) ====================
    
    local Topbar = CreateInstance("Frame", MainFrame, {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", Topbar, { CornerRadius = UDim.new(0, 12) })
    
    -- Title (Minimal)
    CreateInstance("TextLabel", Topbar, {
        Name = "Title",
        Size = UDim2.new(1, -55, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        BackgroundTransparency = 1,
        Text = "✨ " .. Options.Name,
        TextColor3 = NexzanLib.CurrentTheme.Accent,
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    
    -- Close Button
    local CloseBtn = CreateInstance("TextButton", Topbar, {
        Name = "CloseBtn",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -38, 0.5, -15),
        BackgroundColor3 = NexzanLib.CurrentTheme.Danger,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Text = "✕",
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UICorner", CloseBtn, { CornerRadius = UDim.new(0, 6) })
    
    CloseBtn.MouseButton1Click:Connect(function()
        MainFrame.Parent = nil
    end)
    
    -- ==================== TAB CONTAINER ====================
    
    -- Tab Buttons (Horizontal Top)
    local TabButtonContainer = CreateInstance("Frame", MainFrame, {
        Name = "TabButtonContainer",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 45),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    CreateInstance("UIStroke", TabButtonContainer, {
        Color = NexzanLib.CurrentTheme.Secondary,
        Thickness = 1,
    })
    
    local TabScroll = CreateInstance("ScrollingFrame", TabButtonContainer, {
        Name = "TabScroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
    })
    
    CreateInstance("UIListLayout", TabScroll, {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    })
    
    Window.TabButtonContainer = TabButtonContainer
    Window.TabScroll = TabScroll
    
    -- Content Area
    local ContentArea = CreateInstance("Frame", MainFrame, {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -85),
        Position = UDim2.new(0, 0, 0, 85),
        BackgroundColor3 = NexzanLib.CurrentTheme.Primary,
        BorderSizePixel = 0,
    })
    
    Window.ContentArea = ContentArea
    
    table.insert(Library.Windows, Window)
    
    -- ==================== TAB CREATION ====================
    
    function Window:CreateTab(TabName, Icon)
        local Tab = {
            Name = TabName,
            Sections = {},
            Parent = self
        }
        
        -- Tab Button (Compact)
        local TabButton = CreateInstance("TextButton", self.TabScroll, {
            Name = TabName,
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
            TextColor3 = NexzanLib.CurrentTheme.Text,
            Text = (Icon or "•") .. " " .. TabName,
            TextSize = 11,
            Font = Enum.Font.GothamBold,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", TabButton, { CornerRadius = UDim.new(0, 0) })
        
        -- Tab Content
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
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = NexzanLib.CurrentTheme.Accent,
        })
        
        CreateInstance("UIListLayout", ScrollingFrame, {
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
        })
        
        CreateInstance("UIPadding", ScrollingFrame, {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        })
        
        Tab.Button = TabButton
        Tab.Content = TabContent
        Tab.ScrollingFrame = ScrollingFrame
        
        -- Tab Click Handler
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
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = NexzanLib.CurrentTheme.Tertiary,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UICorner", SectionFrame, { CornerRadius = UDim.new(0, 8) })
            
            CreateInstance("UIPadding", SectionFrame, {
                PaddingTop = UDim.new(0, 10),
                PaddingBottom = UDim.new(0, 10),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
            })
            
            -- Section Title
            CreateInstance("TextLabel", SectionFrame, {
                Name = "Title",
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text = "◆ " .. SectionName,
                TextColor3 = NexzanLib.CurrentTheme.Accent,
                TextSize = 12,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            
            local ElementList = CreateInstance("Frame", SectionFrame, {
                Name = "ElementList",
                Size = UDim2.new(1, 0, 1, -23),
                Position = UDim2.new(0, 0, 0, 23),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            CreateInstance("UIListLayout", ElementList, {
                Padding = UDim.new(0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            Section.Frame = SectionFrame
            Section.ElementList = ElementList
            
            -- ==================== ELEMENTS ====================
            
            function Section:AddButton(Options)
                Options = Options or {}
                
                local Button = CreateInstance("TextButton", self.ElementList, {
                    Name = Options.Name or "Button",
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
                    TextColor3 = Color3.fromRGB(0, 0, 0),
                    Text = Options.Name or "Button",
                    TextSize = 11,
                    Font = Enum.Font.GothamBold,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Button, { CornerRadius = UDim.new(0, 6) })
                
                Button.MouseButton1Click:Connect(function()
                    pcall(function()
                        if Options.Callback then Options.Callback() end
                    end)
                    
                    Tween(Button, { BackgroundColor3 = Color3.fromRGB(100, 230, 255) }, 0.1)
                    wait(0.1)
                    Tween(Button, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0.1)
                end)
                
                return Button
            end
            
            function Section:AddToggle(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Toggle",
                    Size = UDim2.new(1, 0, 0, 25),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, -35, 1, 0),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Toggle",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                local ToggleButton = CreateInstance("Frame", Container, {
                    Name = "ToggleButton",
                    Size = UDim2.new(0, 35, 0, 16),
                    Position = UDim2.new(1, -40, 0.5, -8),
                    BackgroundColor3 = Color3.fromRGB(55, 55, 55),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", ToggleButton, { CornerRadius = UDim.new(0, 8) })
                
                local Circle = CreateInstance("Frame", ToggleButton, {
                    Name = "Circle",
                    Size = UDim2.new(0, 14, 0, 14),
                    Position = UDim2.new(0, 1, 0.5, -7),
                    BackgroundColor3 = Color3.fromRGB(200, 200, 200),
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", Circle, { CornerRadius = UDim.new(1, 0) })
                
                local IsToggled = Options.CurrentValue or false
                
                if IsToggled then
                    Tween(ToggleButton, { BackgroundColor3 = NexzanLib.CurrentTheme.Accent }, 0)
                    Tween(Circle, { Position = UDim2.new(0, 20, 0.5, -7) }, 0)
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
                    
                    local NewColor = IsToggled and NexzanLib.CurrentTheme.Accent or Color3.fromRGB(55, 55, 55)
                    local NewPos = IsToggled and UDim2.new(0, 20, 0.5, -7) or UDim2.new(0, 1, 0.5, -7)
                    
                    Tween(ToggleButton, { BackgroundColor3 = NewColor }, 0.2)
                    Tween(Circle, { Position = NewPos }, 0.2)
                    
                    pcall(function()
                        if Options.Callback then Options.Callback(IsToggled) end
                    end)
                end)
                
                return Container
            end
            
            function Section:AddSlider(Options)
                Options = Options or {}
                
                local Container = CreateInstance("Frame", self.ElementList, {
                    Name = Options.Name or "Slider",
                    Size = UDim2.new(1, 0, 0, 35),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("TextLabel", Container, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 12),
                    BackgroundTransparency = 1,
                    Text = Options.Name or "Slider",
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    TextSize = 10,
                    Font = Enum.Font.Gotham,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                
                local SliderBg = CreateInstance("Frame", Container, {
                    Name = "SliderBg",
                    Size = UDim2.new(1, 0, 0, 4),
                    Position = UDim2.new(0, 0, 0, 15),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Tertiary,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", SliderBg, { CornerRadius = UDim.new(0, 2) })
                
                local SliderFill = CreateInstance("Frame", SliderBg, {
                    Name = "SliderFill",
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Accent,
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
                    
                    pcall(function()
                        if Options.Callback then Options.Callback(CurrentValue) end
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
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })
                
                local InputBox = CreateInstance("TextBox", Container, {
                    Name = "InputBox",
                    Size = UDim2.new(1, 0, 1, 0),
                    BackgroundColor3 = NexzanLib.CurrentTheme.Tertiary,
                    TextColor3 = NexzanLib.CurrentTheme.Text,
                    PlaceholderText = Options.Placeholder or "Enter...",
                    PlaceholderColor3 = Color3.fromRGB(150, 150, 150),
                    TextSize = 11,
                    Font = Enum.Font.Gotham,
                    BorderSizePixel = 0,
                })
                
                CreateInstance("UICorner", InputBox, { CornerRadius = UDim.new(0, 6) })
                CreateInstance("UIStroke", InputBox, {
                    Color = NexzanLib.CurrentTheme.Accent,
                    Thickness = 1,
                    Transparency = 0.7,
                })
                
                InputBox.FocusLost:Connect(function()
                    pcall(function()
                        if Options.Callback then Options.Callback(InputBox.Text) end
                    end)
                end)
                
                return Container
            end
            
            function Section:AddLabel(Text)
                local Label = CreateInstance("TextLabel", self.ElementList, {
                    Name = "Label",
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = Text or "Label",
                    TextColor3 = NexzanLib.CurrentTheme.Accent,
                    TextSize = 11,
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
        
        local NotificationFrame = CreateInstance("Frame", NotificationGui, {
            Name = "Notification",
            Size = UDim2.new(0, 300, 0, 80),
            Position = UDim2.new(1, -10, 1, -10),
            BackgroundColor3 = NexzanLib.CurrentTheme.Secondary,
            BorderSizePixel = 0,
        })
        
        CreateInstance("UICorner", NotificationFrame, { CornerRadius = UDim.new(0, 10) })
        CreateInstance("UIStroke", NotificationFrame, {
            Color = Options.Color or NexzanLib.CurrentTheme.Accent,
            Thickness = 1,
        })
        
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Title",
            Size = UDim2.new(1, -15, 0, 20),
            Position = UDim2.new(0, 8, 0, 5),
            BackgroundTransparency = 1,
            Text = Options.Title or "Notification",
            TextColor3 = NexzanLib.CurrentTheme.Accent,
            TextSize = 12,
            Font = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        })
        
        CreateInstance("TextLabel", NotificationFrame, {
            Name = "Content",
            Size = UDim2.new(1, -15, 1, -30),
            Position = UDim2.new(0, 8, 0, 30),
            BackgroundTransparency = 1,
            Text = Options.Content or "Message",
            TextColor3 = NexzanLib.CurrentTheme.Text,
            TextSize = 10,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true,
        })
        
        Tween(NotificationFrame, { Position = UDim2.new(1, -320, 1, -100) }, 0.3)
        
        wait(Options.Duration or 3)
        
        Tween(NotificationFrame, { Position = UDim2.new(1, -10, 1, -10) }, 0.3)
        
        wait(0.3)
        pcall(function() NotificationGui:Destroy() end)
    end
    
    return Window
end

print("✅ Nexzan Hub v2.0.0 Compact Fluent loaded!")
return NexzanLib
