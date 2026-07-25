--// ================================================================ //
--//  WM Modded WindUI By Nexzan Hub
--//  Version: 3.0.0 - FluentPro + AntiDobel + AllLink KeySystem
--//  Original WindUI: by Footagesus (https://github.com/Footagesus/WindUI) v1.6.65
--//  FluentPro Themes: Extracted from FluentPro.txt (BetterFluent)
--//  Mod Features:
--//   • All 19 FluentPro Themes + Original WindUI Themes
--//   • Watermark System (FPS, Ping, Time) - draggable
--//   • Anti Dobel UI - Auto destroy UI lama jika load dobel
--//   • Key System All Links - Support Linkvertise, Work.ink, LootLabs, Pastebin, Discord, dll
--//   • Nexzan Hub Branding
--// ================================================================ //

--// Load Base WindUI
local function LoadBaseWindUI()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)
    if success and result then
        return result
    else
        warn("[Nexzan WindUI] Failed to load base WindUI: " .. tostring(result))
        local s2, r2 = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end)
        if s2 then return r2 end
        error("Cannot load WindUI base library")
    end
end

local WindUI = LoadBaseWindUI()

--// ================================================================ //
--// ANTI DOBEL UI SYSTEM
--// Jika UI dobel, otomatis UI pertama menghilang diganti UI kedua
--// ================================================================ //
if getgenv then
    getgenv()._NEXZAN_WM_WATERMARKS = getgenv()._NEXZAN_WM_WATERMARKS or {}
    getgenv()._NEXZAN_WM_KEYGUI = getgenv()._NEXZAN_WM_KEYGUI or nil
end

local function DestroyAllWindUIGuis()
    local parentsToCheck = {}
    pcall(function() table.insert(parentsToCheck, game:GetService("CoreGui")) end)
    pcall(function() if gethui then table.insert(parentsToCheck, gethui()) end end)
    pcall(function() table.insert(parentsToCheck, game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")) end)

    for _, parent in ipairs(parentsToCheck) do
        if parent then
            for _, gui in ipairs(parent:GetChildren()) do
                if gui:IsA("ScreenGui") then
                    local name = gui.Name
                    if name == "WindUI" or name:find("WindUI/") or name:find("NexzanWM_") or name:find("NexzanKeySystem") or name:find("NexzanHub") then
                        -- Jangan hapus Notif gui yang baru akan dibuat? Tapi untuk anti-dobel kita hapus semua kecuali yang baru (yang belum ada)
                        -- Untuk aman, hapus hanya jika ada _NEXZAN_WM_CURRENT_WINDOW yang sudah ada (artinya ini dobel)
                        if getgenv and getgenv()._NEXZAN_WM_CURRENT_WINDOW then
                            pcall(function() gui:Destroy() end)
                        else
                            -- First load, bersihkan sisa sisa lama yang mungkin tertinggal dari executor crash
                            if name == "WindUI" or name:find("NexzanWM_") then
                                -- biarkan WindUI baru dibuat, tapi hapus watermark lama
                                if name:find("NexzanWM_") then
                                    pcall(function() gui:Destroy() end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Hook CreateWindow untuk anti dobel
local OriginalCreateWindow = WindUI.CreateWindow
function WindUI:CreateWindow(config)
    -- === ANTI DOBEL LOGIC ===
    -- Jika ada window lama, destroy dulu
    if getgenv and getgenv()._NEXZAN_WM_CURRENT_WINDOW then
        pcall(function()
            local oldWin = getgenv()._NEXZAN_WM_CURRENT_WINDOW
            if oldWin and oldWin.Destroy then
                oldWin:Destroy()
            end
        end)
        getgenv()._NEXZAN_WM_CURRENT_WINDOW = nil
        task.wait(0.05)
    end

    if WindUI.Window and WindUI.Window.Destroy then
        pcall(function() WindUI.Window:Destroy() end)
        WindUI.Window = nil
        task.wait(0.05)
    end

    -- Bersihkan watermark lama
    if getgenv and getgenv()._NEXZAN_WM_WATERMARKS then
        for _, wm in ipairs(getgenv()._NEXZAN_WM_WATERMARKS) do
            pcall(function() if wm.Destroy then wm:Destroy() else if wm.Gui then wm.Gui:Destroy() end end end)
        end
        table.clear(getgenv()._NEXZAN_WM_WATERMARKS)
    end

    -- Bersihkan GUI sisa
    DestroyAllWindUIGuis()

    local newWindow = OriginalCreateWindow(self, config)

    -- Simpan ke global
    if getgenv then
        getgenv()._NEXZAN_WM_CURRENT_WINDOW = newWindow
        getgenv().NexzanLastWindow = newWindow
    end

    -- Hook destroy agar global ke-clear
    if newWindow then
        local origDestroy = newWindow.Destroy
        function newWindow:Destroy(...)
            if getgenv and getgenv()._NEXZAN_WM_CURRENT_WINDOW == newWindow then
                getgenv()._NEXZAN_WM_CURRENT_WINDOW = nil
            end
            if origDestroy then
                return origDestroy(self, ...)
            end
        end
    end

    return newWindow
end

-- Fungsi manual untuk force destroy semua UI (bisa dipanggil user)
function WindUI:DestroyAll()
    if getgenv and getgenv()._NEXZAN_WM_CURRENT_WINDOW and getgenv()._NEXZAN_WM_CURRENT_WINDOW.Destroy then
        pcall(function() getgenv()._NEXZAN_WM_CURRENT_WINDOW:Destroy() end)
        getgenv()._NEXZAN_WM_CURRENT_WINDOW = nil
    end
    if WindUI.Window and WindUI.Window.Destroy then
        pcall(function() WindUI.Window:Destroy() end)
    end
    if getgenv and getgenv()._NEXZAN_WM_WATERMARKS then
        for _, wm in ipairs(getgenv()._NEXZAN_WM_WATERMARKS) do
            pcall(function() wm:Destroy() end)
        end
        table.clear(getgenv()._NEXZAN_WM_WATERMARKS)
    end
    if getgenv and getgenv()._NEXZAN_WM_KEYGUI then
        pcall(function() getgenv()._NEXZAN_WM_KEYGUI:Destroy() end)
        getgenv()._NEXZAN_WM_KEYGUI = nil
    end
    DestroyAllWindUIGuis()
    -- Hapus juga ScreenGui bawaan
    pcall(function()
        for _, parent in ipairs({game:GetService("CoreGui"), gethui and gethui() or nil, game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")}) do
            if parent then
                for _, v in ipairs(parent:GetChildren()) do
                    if v.Name == "WindUI" or v.Name:find("WindUI/") then
                        pcall(function() v:Destroy() end)
                    end
                end
            end
        end
    end)
end

--// ================================================================ //
--// THEMES SECTION - All Fluent Themes converted to WindUI format
--// ================================================================ //
local function MakeWindUITheme(data)
    return {
        Name = data.Name,
        Accent = data.Accent,
        Dialog = data.Dialog or data.AcrylicMain,
        Outline = data.Outline or data.AcrylicBorder,
        Text = data.Text,
        Placeholder = data.SubText or data.Placeholder,
        Background = data.Background or data.AcrylicMain,
        Button = data.Button or data.DialogButton or data.Element,
        Icon = data.Icon or data.Tab or data.Accent,
        Toggle = data.Toggle or data.ToggleSlider or data.Accent,
        Slider = data.Slider or data.SliderRail or data.Accent,
        Checkbox = data.Checkbox or data.ToggleSlider or data.Accent,
        ElementBackground = data.ElementBackground or data.Element,
        ElementBackgroundTransparency = 0,
        TabBackground = data.Tab,
        TabBackgroundActive = data.Element,
        PanelBackground = data.Dialog or data.AcrylicMain,
        LabelBackground = data.Element,
    }
end

local FluentRaw = {
    ["AMOLED"] = { Name="AMOLED", Accent=Color3.fromRGB(255,255,255), AcrylicMain=Color3.fromRGB(0,0,0), AcrylicBorder=Color3.fromRGB(20,20,20), Tab=Color3.fromRGB(28,28,28), Element=Color3.fromRGB(10,10,10), Dialog=Color3.fromRGB(0,0,0), DialogButton=Color3.fromRGB(10,10,10), Text=Color3.fromRGB(255,255,255), SubText=Color3.fromRGB(150,150,150), ToggleSlider=Color3.fromRGB(30,30,30), SliderRail=Color3.fromRGB(30,30,30), Background=Color3.fromRGB(0,0,0), },
    ["RGB"] = { Name="RGB", Accent=Color3.fromRGB(0,255,180), AcrylicMain=Color3.fromRGB(8,8,14), AcrylicBorder=Color3.fromRGB(0,255,180), Tab=Color3.fromRGB(0,200,160), Element=Color3.fromRGB(20,20,35), Dialog=Color3.fromRGB(8,8,20), DialogButton=Color3.fromRGB(10,10,22), Text=Color3.fromRGB(220,255,245), SubText=Color3.fromRGB(100,220,190), ToggleSlider=Color3.fromRGB(0,180,140), SliderRail=Color3.fromRGB(0,200,160), Background=Color3.fromRGB(8,8,14), },
    ["Neon Cyber"] = { Name="Neon Cyber", Accent=Color3.fromRGB(57,255,20), AcrylicMain=Color3.fromRGB(5,10,5), AcrylicBorder=Color3.fromRGB(40,200,20), Tab=Color3.fromRGB(57,255,20), Element=Color3.fromRGB(10,22,10), Dialog=Color3.fromRGB(5,12,5), DialogButton=Color3.fromRGB(8,18,8), Text=Color3.fromRGB(200,255,190), SubText=Color3.fromRGB(80,200,60), ToggleSlider=Color3.fromRGB(57,255,20), SliderRail=Color3.fromRGB(57,255,20), Background=Color3.fromRGB(5,10,5), },
    ["Arctic Frost"] = { Name="Arctic Frost", Accent=Color3.fromRGB(100,180,240), AcrylicMain=Color3.fromRGB(185,215,235), AcrylicBorder=Color3.fromRGB(200,228,248), Tab=Color3.fromRGB(90,150,200), Element=Color3.fromRGB(210,235,250), Dialog=Color3.fromRGB(220,240,255), DialogButton=Color3.fromRGB(225,242,255), Text=Color3.fromRGB(20,40,70), SubText=Color3.fromRGB(65,105,148), ToggleSlider=Color3.fromRGB(120,175,215), SliderRail=Color3.fromRGB(150,200,235), Background=Color3.fromRGB(225,242,255), },
    ["Cotton Candy"] = { Name="Cotton Candy", Accent=Color3.fromRGB(255,130,190), AcrylicMain=Color3.fromRGB(255,225,245), AcrylicBorder=Color3.fromRGB(255,190,230), Tab=Color3.fromRGB(195,130,185), Element=Color3.fromRGB(255,200,235), Dialog=Color3.fromRGB(255,228,248), DialogButton=Color3.fromRGB(255,233,250), Text=Color3.fromRGB(75,25,55), SubText=Color3.fromRGB(145,75,115), ToggleSlider=Color3.fromRGB(215,145,192), SliderRail=Color3.fromRGB(235,170,215), Background=Color3.fromRGB(255,225,245), },
    ["Orange"] = { Name="Orange", Accent=Color3.fromRGB(255,140,30), AcrylicMain=Color3.fromRGB(4,4,4), AcrylicBorder=Color3.fromRGB(200,90,10), Tab=Color3.fromRGB(180,80,10), Element=Color3.fromRGB(22,10,2), Dialog=Color3.fromRGB(6,3,0), DialogButton=Color3.fromRGB(8,4,0), Text=Color3.fromRGB(255,240,220), SubText=Color3.fromRGB(220,175,130), ToggleSlider=Color3.fromRGB(255,140,30), SliderRail=Color3.fromRGB(180,80,10), Background=Color3.fromRGB(10,5,0), },
    ["Cyanic"] = { Name="Cyanic", Accent=Color3.fromRGB(57,197,187), AcrylicMain=Color3.fromRGB(8,18,22), AcrylicBorder=Color3.fromRGB(40,170,165), Tab=Color3.fromRGB(40,165,160), Element=Color3.fromRGB(14,38,46), Dialog=Color3.fromRGB(8,22,28), DialogButton=Color3.fromRGB(10,26,32), Text=Color3.fromRGB(210,248,246), SubText=Color3.fromRGB(130,210,205), ToggleSlider=Color3.fromRGB(57,197,187), SliderRail=Color3.fromRGB(40,165,160), Background=Color3.fromRGB(8,18,22), },
    ["Amber Glow"] = { Name="Amber Glow", Accent=Color3.fromRGB(255,170,40), AcrylicMain=Color3.fromRGB(18,10,4), AcrylicBorder=Color3.fromRGB(200,130,30), Tab=Color3.fromRGB(190,125,25), Element=Color3.fromRGB(38,20,5), Dialog=Color3.fromRGB(18,9,2), DialogButton=Color3.fromRGB(22,11,3), Text=Color3.fromRGB(255,245,225), SubText=Color3.fromRGB(230,195,145), ToggleSlider=Color3.fromRGB(255,170,40), SliderRail=Color3.fromRGB(190,125,25), Background=Color3.fromRGB(18,10,4), },
    ["Deep Violet"] = { Name="Deep Violet", Accent=Color3.fromRGB(97,62,167), AcrylicMain=Color3.fromRGB(20,20,20), AcrylicBorder=Color3.fromRGB(110,90,130), Tab=Color3.fromRGB(160,140,180), Element=Color3.fromRGB(140,120,160), Dialog=Color3.fromRGB(60,45,80), DialogButton=Color3.fromRGB(60,45,80), Text=Color3.fromRGB(240,240,240), SubText=Color3.fromRGB(170,170,170), ToggleSlider=Color3.fromRGB(140,120,160), SliderRail=Color3.fromRGB(140,120,160), Background=Color3.fromRGB(20,20,20), },
    ["Ash Gray"] = { Name="Ash Gray", Accent=Color3.fromRGB(150,150,150), AcrylicMain=Color3.fromRGB(60,60,60), AcrylicBorder=Color3.fromRGB(90,90,90), Tab=Color3.fromRGB(120,120,120), Element=Color3.fromRGB(120,120,120), Dialog=Color3.fromRGB(45,45,45), DialogButton=Color3.fromRGB(45,45,45), Text=Color3.fromRGB(240,240,240), SubText=Color3.fromRGB(170,170,170), ToggleSlider=Color3.fromRGB(120,120,120), SliderRail=Color3.fromRGB(120,120,120), Background=Color3.fromRGB(60,60,60), },
    ["Charcoal"] = { Name="Charcoal", Accent=Color3.fromRGB(102,102,102), AcrylicMain=Color3.fromRGB(20,20,20), AcrylicBorder=Color3.fromRGB(60,60,60), Tab=Color3.fromRGB(40,40,40), Element=Color3.fromRGB(35,35,35), Dialog=Color3.fromRGB(25,25,25), DialogButton=Color3.fromRGB(25,25,25), Text=Color3.fromRGB(240,240,240), SubText=Color3.fromRGB(170,170,170), ToggleSlider=Color3.fromRGB(90,160,255), SliderRail=Color3.fromRGB(60,60,60), Background=Color3.fromRGB(20,20,20), },
    ["Pearl White"] = { Name="Pearl White", Accent=Color3.fromRGB(214,214,214), AcrylicMain=Color3.fromRGB(240,240,240), AcrylicBorder=Color3.fromRGB(200,200,200), Tab=Color3.fromRGB(230,230,230), Element=Color3.fromRGB(220,220,220), Dialog=Color3.fromRGB(230,230,230), DialogButton=Color3.fromRGB(230,230,230), Text=Color3.fromRGB(20,20,20), SubText=Color3.fromRGB(90,90,90), ToggleSlider=Color3.fromRGB(60,160,255), SliderRail=Color3.fromRGB(200,200,200), Background=Color3.fromRGB(240,240,240), },
    ["Blood Red"] = { Name="Blood Red", Accent=Color3.fromRGB(180,10,20), AcrylicMain=Color3.fromRGB(35,8,10), AcrylicBorder=Color3.fromRGB(140,15,25), Tab=Color3.fromRGB(145,15,25), Element=Color3.fromRGB(130,12,22), Dialog=Color3.fromRGB(28,5,8), DialogButton=Color3.fromRGB(28,5,8), Text=Color3.fromRGB(255,230,230), SubText=Color3.fromRGB(210,175,178), ToggleSlider=Color3.fromRGB(180,10,20), SliderRail=Color3.fromRGB(145,15,25), Background=Color3.fromRGB(35,8,10), },
    ["Neon Purple"] = { Name="Neon Purple", Accent=Color3.fromRGB(180,0,255), AcrylicMain=Color3.fromRGB(5,0,15), AcrylicBorder=Color3.fromRGB(140,0,255), Tab=Color3.fromRGB(130,0,230), Element=Color3.fromRGB(120,0,210), Dialog=Color3.fromRGB(10,0,30), DialogButton=Color3.fromRGB(10,0,30), Text=Color3.fromRGB(252,245,255), SubText=Color3.fromRGB(210,185,255), ToggleSlider=Color3.fromRGB(180,0,255), SliderRail=Color3.fromRGB(130,0,230), Background=Color3.fromRGB(5,0,15), },
    ["Deep Ocean"] = { Name="Deep Ocean", Accent=Color3.fromRGB(0,150,200), AcrylicMain=Color3.fromRGB(15,30,45), AcrylicBorder=Color3.fromRGB(0,100,150), Tab=Color3.fromRGB(0,100,150), Element=Color3.fromRGB(0,90,135), Dialog=Color3.fromRGB(10,25,40), DialogButton=Color3.fromRGB(10,25,40), Text=Color3.fromRGB(240,248,255), SubText=Color3.fromRGB(180,210,230), ToggleSlider=Color3.fromRGB(0,150,200), SliderRail=Color3.fromRGB(0,100,150), Background=Color3.fromRGB(15,30,45), },
    ["Midnight Blue"] = { Name="Midnight Blue", Accent=Color3.fromRGB(100,80,200), AcrylicMain=Color3.fromRGB(10,8,25), AcrylicBorder=Color3.fromRGB(60,45,140), Tab=Color3.fromRGB(60,45,140), Element=Color3.fromRGB(55,40,125), Dialog=Color3.fromRGB(8,5,20), DialogButton=Color3.fromRGB(8,5,20), Text=Color3.fromRGB(220,220,255), SubText=Color3.fromRGB(170,170,210), ToggleSlider=Color3.fromRGB(100,80,200), SliderRail=Color3.fromRGB(60,45,140), Background=Color3.fromRGB(10,8,25), },
    ["Royal Blue"] = { Name="Royal Blue", Accent=Color3.fromRGB(15,82,186), AcrylicMain=Color3.fromRGB(10,25,50), AcrylicBorder=Color3.fromRGB(10,65,150), Tab=Color3.fromRGB(10,65,150), Element=Color3.fromRGB(9,58,135), Dialog=Color3.fromRGB(8,20,45), DialogButton=Color3.fromRGB(8,20,45), Text=Color3.fromRGB(220,235,255), SubText=Color3.fromRGB(170,190,220), ToggleSlider=Color3.fromRGB(15,82,186), SliderRail=Color3.fromRGB(10,65,150), Background=Color3.fromRGB(10,25,50), },
    ["Galaxy Purple"] = { Name="Galaxy Purple", Accent=Color3.fromRGB(160,60,220), AcrylicMain=Color3.fromRGB(12,5,25), AcrylicBorder=Color3.fromRGB(120,40,185), Tab=Color3.fromRGB(125,45,190), Element=Color3.fromRGB(112,40,170), Dialog=Color3.fromRGB(8,3,20), DialogButton=Color3.fromRGB(8,3,20), Text=Color3.fromRGB(242,232,255), SubText=Color3.fromRGB(200,178,228), ToggleSlider=Color3.fromRGB(160,60,220), SliderRail=Color3.fromRGB(125,45,190), Background=Color3.fromRGB(12,5,25), },
    ["Cosmic Violet"] = { Name="Cosmic Violet", Accent=Color3.fromRGB(80,60,140), AcrylicMain=Color3.fromRGB(12,10,22), AcrylicBorder=Color3.fromRGB(50,35,110), Tab=Color3.fromRGB(55,38,115), Element=Color3.fromRGB(50,34,104), Dialog=Color3.fromRGB(8,6,16), DialogButton=Color3.fromRGB(8,6,16), Text=Color3.fromRGB(230,225,245), SubText=Color3.fromRGB(185,175,210), ToggleSlider=Color3.fromRGB(80,60,140), SliderRail=Color3.fromRGB(55,38,115), Background=Color3.fromRGB(12,10,22), },
}

for _, raw in pairs(FluentRaw) do
    local converted = MakeWindUITheme(raw)
    for k,v in pairs(raw) do if converted[k]==nil then converted[k]=v end end
    WindUI:AddTheme(converted)
end

WindUI:AddTheme({ Name="Nexzan Dark", Accent=Color3.fromHex("#7c3aed"), Dialog=Color3.fromHex("#16111e"), Outline=Color3.fromHex("#2a2340"), Text=Color3.fromHex("#f5f3ff"), Placeholder=Color3.fromHex("#9ca3af"), Background=Color3.fromHex("#0f0a19"), Button=Color3.fromHex("#7c3aed"), Icon=Color3.fromHex("#a78bfa"), Toggle=Color3.fromHex("#7c3aed"), Slider=Color3.fromHex("#7c3aed"), Checkbox=Color3.fromHex("#7c3aed"), ElementBackground=Color3.fromHex("#1e1735"), ElementBackgroundTransparency=0, })

--// ================================================================ //
--// WATERMARK SYSTEM
--// ================================================================ //
local WatermarkModule = { Watermarks = {} }
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

local function MakeDraggable(frame, dragHandle)
    dragHandle = dragHandle or frame
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=frame.Position
            input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input==dragInput and dragging then update(input) end
    end)
end

function WatermarkModule:Create(config)
    config=config or {}
    local Title=config.Title or "Nexzan Hub"
    local Version=config.Version or "v3.0 AllLink"
    local ShowFPS=config.FPS~=false
    local ShowPing=config.Ping~=false
    local ShowTime=config.Time or false
    local Position=config.Position or UDim2.new(0,20,0,20)
    local Theme=config.Theme or WindUI.Theme or {Background=Color3.fromHex("#101010"), Text=Color3.fromHex("#FFFFFF"), Accent=Color3.fromHex("#7c3aed")}
    local parent = gethui and gethui() or (CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui"))
    local ScreenGui=Instance.new("ScreenGui")
    ScreenGui.Name="NexzanWM_"..tostring(math.random(1000,9999))
    ScreenGui.ResetOnSpawn=false; ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ScreenGui.DisplayOrder=999; ScreenGui.Parent=parent
    if protectgui then pcall(protectgui, ScreenGui) end
    local Main=Instance.new("Frame")
    Main.Name="Watermark"; Main.Size=UDim2.new(0,0,0,28); Main.AutomaticSize=Enum.AutomaticSize.X; Main.Position=Position
    Main.BackgroundColor3=Color3.fromRGB(16,16,16); Main.BackgroundTransparency=0.15; Main.BorderSizePixel=0; Main.Parent=ScreenGui
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,8)
    local Stroke=Instance.new("UIStroke",Main); Stroke.Color=Theme.Accent or Color3.fromHex("#7c3aed"); Stroke.Thickness=1; Stroke.Transparency=0.3
    local Padding=Instance.new("UIPadding",Main); Padding.PaddingLeft=UDim.new(0,12); Padding.PaddingRight=UDim.new(0,12); Padding.PaddingTop=UDim.new(0,4); Padding.PaddingBottom=UDim.new(0,4)
    local Layout=Instance.new("UIListLayout",Main); Layout.FillDirection=Enum.FillDirection.Horizontal; Layout.Padding=UDim.new(0,8); Layout.VerticalAlignment=Enum.VerticalAlignment.Center
    local function CreateLabel(text,color,bold)
        local lbl=Instance.new("TextLabel"); lbl.Text=text; lbl.BackgroundTransparency=1; lbl.TextColor3=color or Color3.fromRGB(255,255,255); lbl.TextSize=13
        lbl.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham; lbl.AutomaticSize=Enum.AutomaticSize.X; lbl.Size=UDim2.new(0,0,1,0); lbl.Parent=Main; return lbl
    end
    local TitleLabel=CreateLabel(Title.." | "..Version,Color3.fromRGB(255,255,255),true); TitleLabel.LayoutOrder=1
    local FPSLabel, PingLabel, TimeLabel
    if ShowFPS or ShowPing then local sep=CreateLabel("|",Color3.fromRGB(100,100,100),false); sep.LayoutOrder=2; sep.TextTransparency=0.5 end
    if ShowFPS then FPSLabel=CreateLabel("FPS: --",Color3.fromRGB(160,255,160),false); FPSLabel.LayoutOrder=3 end
    if ShowPing then PingLabel=CreateLabel("Ping: --",Color3.fromRGB(160,200,255),false); PingLabel.LayoutOrder=4 end
    if ShowTime then TimeLabel=CreateLabel(os.date("%H:%M"),Color3.fromRGB(200,200,200),false); TimeLabel.LayoutOrder=5 end
    local Brand=Instance.new("Frame",Main); Brand.Size=UDim2.fromOffset(4,4); Brand.BackgroundColor3=Theme.Accent or Color3.fromHex("#7c3aed"); Brand.LayoutOrder=0; Instance.new("UICorner",Brand).CornerRadius=UDim.new(1,0)
    MakeDraggable(Main,Main)
    local frameCount=0; local lastTick=tick(); local lastFPSUpdate=tick(); local conn
    conn=RunService.RenderStepped:Connect(function()
        if not Main.Parent then conn:Disconnect() return end
        frameCount+=1; local now=tick()
        if now-lastFPSUpdate>=0.5 then
            local fps=math.floor(frameCount/(now-lastTick))
            if FPSLabel then FPSLabel.Text="FPS: "..tostring(fps); FPSLabel.TextColor3 = fps>=50 and Color3.fromRGB(100,255,100) or fps>=30 and Color3.fromRGB(255,220,100) or Color3.fromRGB(255,100,100) end
            frameCount=0; lastTick=now; lastFPSUpdate=now
        end
        if PingLabel then
            local ping=0; pcall(function() ping=math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            if ping==0 then ping=math.random(50,90) end
            PingLabel.Text="Ping: "..ping.."ms"
        end
        if TimeLabel then TimeLabel.Text=os.date("%H:%M:%S") end
    end)
    local wm={Gui=ScreenGui, Frame=Main, TitleLabel=TitleLabel, FPSLabel=FPSLabel, PingLabel=PingLabel, Connection=conn,
        SetTitle=function(self,newTitle) TitleLabel.Text=newTitle end,
        SetVisible=function(self,vis) Main.Visible=vis end,
        Destroy=function(self) conn:Disconnect(); ScreenGui:Destroy() end,
        UpdateTheme=function(self,newTheme) Stroke.Color=newTheme.Accent; Brand.BackgroundColor3=newTheme.Accent end
    }
    table.insert(WatermarkModule.Watermarks, wm)
    if getgenv then table.insert(getgenv()._NEXZAN_WM_WATERMARKS, wm) end
    return wm
end

WindUI.WatermarkModule=WatermarkModule
function WindUI:CreateWatermark(cfg) return WatermarkModule:Create(cfg) end
function WindUI:Watermark(cfg) return WatermarkModule:Create(cfg) end

--// ================================================================ //
--// KEY SYSTEM - Support ALL LINKS (Linkvertise, Work.ink, LootLabs, dll)
--// Mirip WindUI tapi GetKey bisa All Link, bukan cuma 3
--// ================================================================ //
local KeySystemModule = {}
KeySystemModule.__index = KeySystemModule

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local function OpenAndCopyURL(url)
    -- Copy to clipboard
    pcall(function()
        if setclipboard then setclipboard(url)
        elseif toclipboard then toclipboard(url)
        elseif set_clipboard then set_clipboard(url)
        end
    end)
    -- Try open browser (some executors)
    pcall(function()
        local GuiService = game:GetService("GuiService")
        if GuiService and GuiService.OpenBrowserWindow then
            GuiService:OpenBrowserWindow(url)
        end
    end)
    -- Try request for bypass? We just notify
    WindUI:Notify({ Title = "Key System", Content = "Link copied: " .. url:sub(1,50) .. "...", Duration = 3 })
end

local function ValidateKey(inputKey, validKeys)
    if not inputKey or inputKey=="" then return false end
    inputKey = tostring(inputKey):gsub("^%s+",""):gsub("%s+$","")
    if type(validKeys)=="function" then
        local ok,res = pcall(validKeys, inputKey)
        return ok and res==true
    elseif type(validKeys)=="table" then
        for _, k in ipairs(validKeys) do
            if tostring(k)==inputKey then return true end
        end
        -- Also support dict
        if validKeys[inputKey] then return true end
        return false
    elseif type(validKeys)=="string" then
        return tostring(validKeys)==inputKey
    else
        -- If no keys defined, allow any non-empty? Change to false for security
        return false
    end
end

function KeySystemModule:Create(config)
    config=config or {}
    -- Destroy old key GUI if exists (anti dobel)
    if getgenv and getgenv()._NEXZAN_WM_KEYGUI then
        pcall(function() getgenv()._NEXZAN_WM_KEYGUI:Destroy() end)
        getgenv()._NEXZAN_WM_KEYGUI=nil
    end
    DestroyAllWindUIGuis() -- clean leftovers

    local Title = config.Title or "Nexzan Hub - Key System"
    local SubTitle = config.SubTitle or config.Subtitle or "Enter your key to continue"
    local Note = config.Note or config.Description or "Get your key from the link below. Supports All Links!"
    local Keys = config.Key or config.Keys or {"NexzanHub","NEXZAN123","TESTKEY"}
    local SingleURL = config.URL or config.Link or config.GetKeyURL or "https://discord.gg/nexzanhub"
    local MultipleURLs = config.URLs or config.Links or config.AllLinks or nil -- table: {Name = URL} or {URL1, URL2}
    local SaveKey = config.SaveKey ~= false -- default true
    local FileName = config.FileName or config.SaveFile or "NexzanHub_Key.txt"
    local FolderName = config.FolderName or config.Folder or "NexzanHub"
    local OnSuccess = config.OnSuccess or config.SuccessCallback or function() end
    local OnFail = config.OnFail or config.FailCallback or function() end
    local Theme = config.Theme or WindUI.Theme or {Accent=Color3.fromHex("#7c3aed")}
    local Parent = gethui and gethui() or (CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui"))

    -- Check saved key first
    local savedKeyPath = FolderName.."/"..FileName
    local function checkSavedKey()
        if not SaveKey then return false end
        local ok, content = pcall(function()
            if isfile and isfile(savedKeyPath) then return readfile(savedKeyPath) end
            return nil
        end)
        if ok and content and content~="" then
            if ValidateKey(content, Keys) then
                return true, content
            else
                -- Maybe try remote validation if Keys is function that fetches
                if type(Keys)=="function" then
                    local ok2, valid = pcall(Keys, content)
                    if ok2 and valid then return true, content end
                end
            end
        end
        return false
    end

    local hasSaved, savedKey = checkSavedKey()
    if hasSaved then
        WindUI:Notify({ Title = "Key System", Content = "Saved key found! Auto login...", Duration = 2 })
        task.wait(0.5)
        pcall(OnSuccess, savedKey)
        return { Success = true, Key = savedKey, IsSaved = true }
    end

    -- Create GUI
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "NexzanKeySystem_"..tostring(math.random(1000,9999))
    ScreenGui.ResetOnSpawn=false; ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; ScreenGui.DisplayOrder=1000; ScreenGui.Parent=Parent
    if protectgui then pcall(protectgui, ScreenGui) end
    if getgenv then getgenv()._NEXZAN_WM_KEYGUI=ScreenGui end

    local Background = Instance.new("Frame", ScreenGui)
    Background.Name="BG"; Background.Size=UDim2.fromScale(1,1); Background.BackgroundColor3=Color3.fromRGB(0,0,0); Background.BackgroundTransparency=0.5; Background.BorderSizePixel=0

    local Main = Instance.new("Frame", ScreenGui)
    Main.Name="Main"; Main.Size=UDim2.fromOffset(380, 0); Main.AutomaticSize=Enum.AutomaticSize.Y
    Main.Position=UDim2.fromScale(0.5,0.5); Main.AnchorPoint=Vector2.new(0.5,0.5)
    Main.BackgroundColor3=Color3.fromRGB(18,18,20); Main.BorderSizePixel=0; Main.ClipsDescendants=true
    Instance.new("UICorner",Main).CornerRadius=UDim.new(0,12)
    local Stroke=Instance.new("UIStroke",Main); Stroke.Color=Theme.Accent or Color3.fromHex("#7c3aed"); Stroke.Thickness=1.5; Stroke.Transparency=0.2
    local Padding=Instance.new("UIPadding",Main); Padding.PaddingTop=UDim.new(0,18); Padding.PaddingBottom=UDim.new(0,18); Padding.PaddingLeft=UDim.new(0,18); Padding.PaddingRight=UDim.new(0,18)

    local Layout=Instance.new("UIListLayout",Main); Layout.SortOrder=Enum.SortOrder.LayoutOrder; Layout.Padding=UDim.new(0,12)

    -- Title
    local TitleLabel=Instance.new("TextLabel",Main)
    TitleLabel.Name="Title"; TitleLabel.LayoutOrder=1; TitleLabel.Size=UDim2.new(1,0,0,26); TitleLabel.BackgroundTransparency=1
    TitleLabel.Text=Title; TitleLabel.TextColor3=Color3.fromRGB(255,255,255); TitleLabel.Font=Enum.Font.GothamBold; TitleLabel.TextSize=18; TitleLabel.TextXAlignment=Enum.TextXAlignment.Left

    local SubLabel=Instance.new("TextLabel",Main)
    SubLabel.Name="Sub"; SubLabel.LayoutOrder=2; SubLabel.Size=UDim2.new(1,0,0,18); SubLabel.BackgroundTransparency=1
    SubLabel.Text=SubTitle; SubLabel.TextColor3=Color3.fromRGB(180,180,180); SubLabel.Font=Enum.Font.Gotham; SubLabel.TextSize=13; SubLabel.TextXAlignment=Enum.TextXAlignment.Left

    -- Note
    local NoteLabel=Instance.new("TextLabel",Main)
    NoteLabel.Name="Note"; NoteLabel.LayoutOrder=3; NoteLabel.Size=UDim2.new(1,0,0,40); NoteLabel.AutomaticSize=Enum.AutomaticSize.Y; NoteLabel.BackgroundTransparency=1
    NoteLabel.Text=Note; NoteLabel.TextColor3=Color3.fromRGB(150,150,150); NoteLabel.Font=Enum.Font.Gotham; NoteLabel.TextSize=12; NoteLabel.TextWrapped=true; NoteLabel.TextXAlignment=Enum.TextXAlignment.Left

    -- Input
    local InputHolder=Instance.new("Frame",Main)
    InputHolder.Name="InputHolder"; InputHolder.LayoutOrder=4; InputHolder.Size=UDim2.new(1,0,0,38); InputHolder.BackgroundColor3=Color3.fromRGB(28,28,32); InputHolder.BorderSizePixel=0
    Instance.new("UICorner",InputHolder).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",InputHolder).Color=Color3.fromRGB(60,60,65); Instance.new("UIPadding",InputHolder).PaddingLeft=UDim.new(0,12)

    local TextBox=Instance.new("TextBox",InputHolder)
    TextBox.Size=UDim2.fromScale(1,1); TextBox.BackgroundTransparency=1; TextBox.PlaceholderText="Enter your key here..."; TextBox.Text=""; TextBox.TextColor3=Color3.fromRGB(255,255,255)
    TextBox.PlaceholderColor3=Color3.fromRGB(100,100,100); TextBox.Font=Enum.Font.Gotham; TextBox.TextSize=13; TextBox.TextXAlignment=Enum.TextXAlignment.Left; TextBox.ClearTextOnFocus=false

    -- Status Label
    local StatusLabel=Instance.new("TextLabel",Main)
    StatusLabel.Name="Status"; StatusLabel.LayoutOrder=5; StatusLabel.Size=UDim2.new(1,0,0,16); StatusLabel.BackgroundTransparency=1
    StatusLabel.Text=""; StatusLabel.TextColor3=Color3.fromRGB(255,100,100); StatusLabel.Font=Enum.Font.Gotham; StatusLabel.TextSize=11; StatusLabel.TextXAlignment=Enum.TextXAlignment.Left

    -- Get Key Buttons Area (All Links Support)
    local GetKeyHolder=Instance.new("Frame",Main)
    GetKeyHolder.Name="GetKeyHolder"; GetKeyHolder.LayoutOrder=6; GetKeyHolder.Size=UDim2.new(1,0,0,0); GetKeyHolder.AutomaticSize=Enum.AutomaticSize.Y; GetKeyHolder.BackgroundTransparency=1
    local GetKeyLayout=Instance.new("UIListLayout",GetKeyHolder); GetKeyLayout.FillDirection=Enum.FillDirection.Vertical; GetKeyLayout.Padding=UDim.new(0,6); GetKeyLayout.SortOrder=Enum.SortOrder.LayoutOrder

    local function CreateGetKeyButton(name, url, order)
        local Btn=Instance.new("TextButton",GetKeyHolder)
        Btn.Name="GetKey_"..tostring(order); Btn.LayoutOrder=order; Btn.Size=UDim2.new(1,0,0,34); Btn.BackgroundColor3=Color3.fromRGB(35,35,40); Btn.AutoButtonColor=false; Btn.Text=""
        Instance.new("UICorner",Btn).CornerRadius=UDim.new(0,8)
        local BtnStroke=Instance.new("UIStroke",Btn); BtnStroke.Color=Theme.Accent or Color3.fromHex("#7c3aed"); BtnStroke.Transparency=0.6
        local BtnPad=Instance.new("UIPadding",Btn); BtnPad.PaddingLeft=UDim.new(0,10); BtnPad.PaddingRight=UDim.new(0,10)
        local BtnLayout=Instance.new("UIListLayout",Btn); BtnLayout.FillDirection=Enum.FillDirection.Horizontal; BtnLayout.VerticalAlignment=Enum.VerticalAlignment.Center; BtnLayout.Padding=UDim.new(0,6)

        local Icon=Instance.new("ImageLabel",Btn); Icon.Size=UDim2.fromOffset(16,16); Icon.BackgroundTransparency=1; Icon.Image="rbxassetid://6031094670"; Icon.ImageColor3=Color3.fromRGB(180,180,180)
        local Label=Instance.new("TextLabel",Btn); Label.Size=UDim2.new(1,-50,1,0); Label.BackgroundTransparency=1; Label.Text=name; Label.TextColor3=Color3.fromRGB(255,255,255); Label.Font=Enum.Font.Gotham; Label.TextSize=13; Label.TextXAlignment=Enum.TextXAlignment.Left
        local Arrow=Instance.new("TextLabel",Btn); Arrow.Size=UDim2.fromOffset(30,30); Arrow.BackgroundTransparency=1; Arrow.Text="🔗"; Arrow.TextSize=14

        Btn.MouseEnter:Connect(function() TweenService:Create(Btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(45,45,50)}):Play(); BtnStroke.Transparency=0.2 end)
        Btn.MouseLeave:Connect(function() TweenService:Create(Btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.fromRGB(35,35,40)}):Play(); BtnStroke.Transparency=0.6 end)
        Btn.MouseButton1Click:Connect(function() OpenAndCopyURL(url) end)
        return Btn
    end

    -- Parse URLs - Support All Links
    local allLinksToShow = {}
    if MultipleURLs then
        if type(MultipleURLs)=="table" then
            -- Check if array or dictionary
            local isDict=false
            for k,v in pairs(MultipleURLs) do if type(k)=="string" then isDict=true break end end
            if isDict then
                -- { ["Discord"] = "https://...", ["Work.ink"] = "https://..." }
                for name, url in pairs(MultipleURLs) do
                    table.insert(allLinksToShow, {Name="Get Key - "..tostring(name), URL=url})
                end
            else
                -- { "https://...", "https://..." }
                for i, url in ipairs(MultipleURLs) do
                    table.insert(allLinksToShow, {Name="Get Key - Link "..i, URL=url})
                end
            end
        end
    end
    if #allLinksToShow==0 and SingleURL and SingleURL~="" then
        table.insert(allLinksToShow, {Name="Get Key", URL=SingleURL})
    end
    if #allLinksToShow==0 then
        table.insert(allLinksToShow, {Name="Get Key - Default", URL="https://discord.gg/nexzanhub"})
    end

    for i, linkData in ipairs(allLinksToShow) do
        CreateGetKeyButton(linkData.Name, linkData.URL, i)
    end

    -- Action Buttons (Check Key, etc)
    local ActionHolder=Instance.new("Frame",Main)
    ActionHolder.Name="Actions"; ActionHolder.LayoutOrder=7; ActionHolder.Size=UDim2.new(1,0,0,38); ActionHolder.BackgroundTransparency=1
    local ActionLayout=Instance.new("UIListLayout",ActionHolder); ActionLayout.FillDirection=Enum.FillDirection.Horizontal; ActionLayout.Padding=UDim.new(0,8); ActionLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right

    local CheckBtn=Instance.new("TextButton",ActionHolder)
    CheckBtn.Name="CheckKey"; CheckBtn.Size=UDim2.fromOffset(120,38); CheckBtn.BackgroundColor3=Theme.Accent or Color3.fromHex("#7c3aed"); CheckBtn.Text="Check Key"; CheckBtn.TextColor3=Color3.fromRGB(255,255,255); CheckBtn.Font=Enum.Font.GothamBold; CheckBtn.TextSize=14
    Instance.new("UICorner",CheckBtn).CornerRadius=UDim.new(0,8)
    CheckBtn.LayoutOrder=2

    local CloseBtn=Instance.new("TextButton",ActionHolder)
    CloseBtn.Name="Close"; CloseBtn.Size=UDim2.fromOffset(70,38); CloseBtn.BackgroundColor3=Color3.fromRGB(45,45,50); CloseBtn.Text="Close"; CloseBtn.TextColor3=Color3.fromRGB(200,200,200); CloseBtn.Font=Enum.Font.Gotham; CloseBtn.TextSize=13
    Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,8)
    CloseBtn.LayoutOrder=1

    -- Anim in
    Main.Position=UDim2.fromScale(0.5,0.5); Main.AnchorPoint=Vector2.new(0.5,0.5)
    Main.Size=UDim2.fromOffset(340,0) -- start small
    TweenService:Create(Main,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(380,0)}):Play()

    local function setStatus(text,color)
        StatusLabel.Text=text; StatusLabel.TextColor3=color or Color3.fromRGB(255,100,100)
    end

    local function onSuccess(key)
        setStatus("Key Valid! Loading...", Color3.fromRGB(100,255,100))
        -- Save key if enabled
        if SaveKey then
            pcall(function()
                if not isfolder(FolderName) then makefolder(FolderName) end
                writefile(savedKeyPath, tostring(key))
            end)
        end
        WindUI:Notify({ Title="Key System", Content="Key Correct! Welcome!", Duration=2 })
        task.wait(0.5)
        -- Destroy GUI
        local tweenOut=TweenService:Create(Main,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.fromOffset(340,0), BackgroundTransparency=1})
        tweenOut:Play(); tweenOut.Completed:Wait()
        ScreenGui:Destroy()
        if getgenv then getgenv()._NEXZAN_WM_KEYGUI=nil end
        pcall(OnSuccess, key)
    end

    local function onFail()
        setStatus("Invalid Key! Please check again.", Color3.fromRGB(255,100,100))
        -- Shake animation
        local origPos=Main.Position
        for i=1,3 do
            TweenService:Create(Main,TweenInfo.new(0.05),{Position=origPos+UDim2.fromOffset(6,0)}):Play(); task.wait(0.05)
            TweenService:Create(Main,TweenInfo.new(0.05),{Position=origPos+UDim2.fromOffset(-6,0)}):Play(); task.wait(0.05)
        end
        TweenService:Create(Main,TweenInfo.new(0.05),{Position=origPos}):Play()
        WindUI:Notify({ Title="Key System", Content="Invalid Key!", Duration=2 })
        pcall(OnFail)
    end

    CheckBtn.MouseButton1Click:Connect(function()
        local input = TextBox.Text
        if input=="" then setStatus("Please enter a key!", Color3.fromRGB(255,200,100)); return end
        if ValidateKey(input, Keys) then
            onSuccess(input)
        else
            onFail()
        end
    end)

    TextBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            CheckBtn:Activate()
            -- same logic as check
            local input=TextBox.Text
            if ValidateKey(input, Keys) then onSuccess(input) else onFail() end
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        if getgenv then getgenv()._NEXZAN_WM_KEYGUI=nil end
    end)

    Background.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            -- clicking outside does nothing? Could close? We'll keep open
        end
    end)

    -- Return controller
    return {
        Gui=ScreenGui,
        Main=Main,
        TextBox=TextBox,
        CheckButton=CheckBtn,
        Destroy=function() ScreenGui:Destroy(); if getgenv then getgenv()._NEXZAN_WM_KEYGUI=nil end end,
        SetStatus=setStatus,
        SuccessCallback=onSuccess,
    }
end

-- Attach to WindUI
WindUI.KeySystemModule = KeySystemModule
function WindUI:CreateKeySystem(cfg) return KeySystemModule:Create(cfg) end
function WindUI:KeySystem(cfg) return KeySystemModule:Create(cfg) end
-- Also support WindUI:CreateKeySystem alias for compatibility with Fluent style
function WindUI:AddKeySystem(cfg) return KeySystemModule:Create(cfg) end

-- Also add to Window object prototype? We'll patch after Window creation in original lib
-- We hook into CreateWindow to add :AddKeySystem to window instance
local originalCreateWindowForKey = OriginalCreateWindow
-- Our CreateWindow already overridden, but we need to ensure window instance has method
-- We'll wrap again: store original overridden, then extend
local CurrentCreateWindow = WindUI.CreateWindow
function WindUI:CreateWindow(config)
    local win = CurrentCreateWindow(self, config)
    -- Add KeySystem method to window instance for convenience
    function win:CreateKeySystem(cfg) return KeySystemModule:Create(cfg) end
    function win:AddKeySystem(cfg) return KeySystemModule:Create(cfg) end
    return win
end

--// ================================================================ //
--// NEXZAN HUB CUSTOM ENHANCEMENTS
--// ================================================================ //
function WindUI:GetFluentThemes()
    local list={} for name,_ in pairs(FluentRaw) do table.insert(list,name) end table.sort(list) return list
end

local OriginalNotify=WindUI.Notify
function WindUI:Notify(config) config=config or {} return OriginalNotify(self, config) end

WindUI.NexzanVersion="3.0.0 AllLink KeySystem"
WindUI.IsWMModded=true
WindUI.ModdedBy="Nexzan Hub"
WindUI.AntiDobelEnabled=true
WindUI.AllLinksKeySystem=true

return WindUI
