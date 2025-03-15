--[[
  NovaUI Library v1.0 (Single-file example)
  ----------------------------------------
  Key Features:
    • Window creation (draggable, centered, mobile-friendly)
    • Tab system
    • Elements: Toggles, Sliders, Colorpickers, Buttons, Labels
    • Basic theme system
    • Optional intro splash
    • Orion-like API calls (MakeWindow, MakeTab, AddToggle, etc.)

  Usage:
    local NovaUI = loadstring(...)()  -- or require(...)
    local Window = NovaUI:MakeWindow({Name = "My Menu"})
    local Tab = Window:MakeTab({Name = "Main"})
    Tab:AddToggle({Name = "Auto Farm", Default = false, Callback = function(val) ... end})
    ... etc ...
--]]

--------------------------
-- Module Setup
--------------------------
local NovaUI = {
    Connections = {},
    Flags = {},
    Themes = {
        Default = {
            Main     = Color3.fromRGB(35, 35, 45),
            Secondary= Color3.fromRGB(50, 50, 60),
            Stroke   = Color3.fromRGB(80, 80, 90),
            Text     = Color3.fromRGB(240,240,240),
            TextDark = Color3.fromRGB(150,150,150)
        }
    },
    SelectedTheme = "Default"
}

--------------------------
-- Roblox Services
--------------------------
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--------------------------
-- Utility Functions
--------------------------
local function Create(class, props, children)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    for _,child in pairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function MakeDraggable(dragFrame, mainFrame)
    local dragging = false
    local dragInput, mousePos, framePos
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.AbsolutePosition
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    dragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            local newPos = UDim2.new(0, framePos.X + delta.X, 0, framePos.Y + delta.Y)
            TweenService:Create(mainFrame, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = newPos
            }):Play()
        end
    end)
end

local function Ripple(obj, x, y)
    local circle = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.7,
        Size = UDim2.new(0,0,0,0),
        AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0, x, 0, y),
        ClipsDescendants = true,
        ZIndex = 200
    }, {
        Create("UICorner", {CornerRadius = UDim.new(1,0)})
    })
    circle.Parent = obj

    local maxSize = math.max(obj.AbsoluteSize.X, obj.AbsoluteSize.Y) * 1.4
    TweenService:Create(circle, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {
        Size = UDim2.new(0, maxSize, 0, maxSize),
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.4, function()
        circle:Destroy()
    end)
end

local function Darken(color, amount)
    -- Example function to darken a color a bit
    local h,s,v = color:ToHSV()
    v = math.clamp(v - amount, 0,1)
    return Color3.fromHSV(h,s,v)
end

--------------------------
-- UI Creation
--------------------------
local NovaScreen = Create("ScreenGui", {
    Name = "NovaUI",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false
})
if syn and syn.protect_gui then
    syn.protect_gui(NovaScreen)
    NovaScreen.Parent = CoreGui
else
    NovaScreen.Parent = CoreGui
end

--------------------------
-- NovaUI Functions
--------------------------
function NovaUI:IsMobile()
    return UserInputService.TouchEnabled
end

function NovaUI:MakeWindow(cfg)
    cfg = cfg or {}
    cfg.Name = cfg.Name or "Nova UI"
    cfg.IntroEnabled = (cfg.IntroEnabled == nil) and true or cfg.IntroEnabled
    cfg.IntroText = cfg.IntroText or "Welcome to Nova UI"
    cfg.BlurBackground = cfg.BlurBackground == true

    local isMobile = self:IsMobile()
    local defaultWidth  = isMobile and 420 or 620
    local defaultHeight = isMobile and 300 or 360

    -- Main window
    local MainFrame = Create("Frame", {
        Size = UDim2.new(0, defaultWidth, 0, defaultHeight),
        Position = UDim2.new(0.5, -defaultWidth/2, 0.5, -defaultHeight/2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Main,
        BorderSizePixel = 0,
        Parent = NovaScreen
    })

    Create("UICorner", {CornerRadius = UDim.new(0,10)}).Parent = MainFrame
    local stroke = Create("UIStroke", {Color = self.Themes[self.SelectedTheme].Stroke, Thickness = 1})
    stroke.Parent = MainFrame

    local TopBar = Create("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundColor3 = Darken(self.Themes[self.SelectedTheme].Main, 0.05),
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0,10)}).Parent = TopBar

    local Title = Create("TextLabel", {
        Size = UDim2.new(1,-50,1,0),
        Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        Text = cfg.Name,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = TopBar
    })

    local DragFrame = Create("Frame", {
        Size = UDim2.new(1,-50,1,0),
        Position = UDim2.new(0,0,0,0),
        BackgroundTransparency = 1
    })
    DragFrame.Parent = TopBar
    MakeDraggable(DragFrame, MainFrame)

    local CloseButton = Create("TextButton", {
        Size = UDim2.new(0,40,0,40),
        Position = UDim2.new(1,-40,0,0),
        BackgroundTransparency = 1,
        Text = "X",
        Font = Enum.Font.GothamBold,
        TextSize = 20,
        TextColor3 = self.Themes[self.SelectedTheme].Text,
        Parent = TopBar
    })

    CloseButton.MouseButton1Click:Connect(function()
        Ripple(CloseButton, 20, 20)
        MainFrame.Visible = false
    end)

    -- Tab holder (left side)
    local TabHolder = Create("ScrollingFrame", {
        Size = UDim2.new(0,120,1,-40),
        Position = UDim2.new(0,0,0,40),
        CanvasSize = UDim2.new(0,0,0,0),
        BackgroundColor3 = self.Themes[self.SelectedTheme].Secondary,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        Parent = MainFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0,10)}).Parent = TabHolder
    local tabList = Create("UIListLayout", {Padding = UDim.new(0,5)})
    tabList.Parent = TabHolder

    -- Main container for tab contents
    local ContainerHolder = Create("Frame", {
        Size = UDim2.new(1,-120,1,-40),
        Position = UDim2.new(0,120,0,40),
        BackgroundColor3 = Darken(self.Themes[self.SelectedTheme].Main,0.02),
        BorderSizePixel = 0,
        Parent = MainFrame
    })
    Create("UICorner", {CornerRadius = UDim.new(0,10)}).Parent = ContainerHolder

    local function HideAllContainers()
        for _, c in ipairs(ContainerHolder:GetChildren()) do
            if c:IsA("ScrollingFrame") then
                c.Visible = false
            end
        end
        for _, t in ipairs(TabHolder:GetChildren()) do
            if t:IsA("TextButton") then
                local lbl = t:FindFirstChild("TabLabel")
                if lbl then
                    TweenService:Create(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                        TextTransparency = 0.5
                    }):Play()
                end
            end
        end
    end

    local WindowAPI = {}
    function WindowAPI:MakeTab(tabCfg)
        tabCfg = tabCfg or {}
        tabCfg.Name = tabCfg.Name or "New Tab"
        local TabBtn = Create("TextButton", {
            Size = UDim2.new(1,0,0,30),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
            Parent = TabHolder
        })
        local lbl = Create("TextLabel", {
            Name = "TabLabel",
            Size = UDim2.new(1,-10,1,0),
            Position = UDim2.new(0,10,0,0),
            BackgroundTransparency = 1,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            Text = tabCfg.Name,
            TextColor3 = self.Themes[self.SelectedTheme].Text,
            TextTransparency = 0.5,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = TabBtn
        })

        local TabContainer = Create("ScrollingFrame", {
            Size = UDim2.new(1,0,1,0),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            CanvasSize = UDim2.new(0,0,0,0),
            Visible = false,
            Parent = ContainerHolder
        })
        local layout = Create("UIListLayout", {Padding = UDim.new(0,5)})
        layout.Parent = TabContainer
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContainer.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 20)
        end)

        TabBtn.MouseButton1Click:Connect(function()
            HideAllContainers()
            TabContainer.Visible = true
            TweenService:Create(lbl, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {TextTransparency = 0}):Play()
        end)

        if #TabHolder:GetChildren() == 2 then
            TabContainer.Visible = true
            lbl.TextTransparency = 0
        end

        local TabAPI = {}

        -- AddLabel
        function TabAPI:AddLabel(labelCfg)
            local text = labelCfg or "New Label"
            local lblFrame = Create("Frame", {
                Size = UDim2.new(1, -10, 0, 30),
                BackgroundTransparency = 0.5,
                BackgroundColor3 = Darken(NovaUI.Themes[NovaUI.SelectedTheme].Secondary,0.03),
                Parent = TabContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = lblFrame
            local label = Create("TextLabel", {
                Size = UDim2.new(1,-10,1,0),
                Position = UDim2.new(0,10,0,0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Text = text,
                TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = lblFrame
            })
            return {
                Set = function(_, newText)
                    label.Text = newText
                end
            }
        end

        -- AddToggle
        function TabAPI:AddToggle(toggleCfg)
            toggleCfg = toggleCfg or {}
            toggleCfg.Name = toggleCfg.Name or "New Toggle"
            toggleCfg.Default = toggleCfg.Default or false
            toggleCfg.Callback = toggleCfg.Callback or function() end

            local toggVal = toggleCfg.Default

            local toggFrame = Create("Frame", {
                Size = UDim2.new(1, -10, 0, 35),
                BackgroundColor3 = Darken(NovaUI.Themes[NovaUI.SelectedTheme].Secondary,0.03),
                Parent = TabContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = toggFrame

            local label = Create("TextLabel", {
                Size = UDim2.new(1,-50,1,0),
                Position = UDim2.new(0,10,0,0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Text = toggleCfg.Name,
                TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = toggFrame
            })

            local click = Create("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = toggFrame
            })

            local checkBox = Create("Frame", {
                Size = UDim2.new(0,25,0,25),
                Position = UDim2.new(1,-35,0.5,-12),
                BackgroundColor3 = toggVal and Color3.fromRGB(80,170,90) or Color3.fromRGB(70,70,70),
                BorderSizePixel = 0,
                Parent = toggFrame
            })
            Create("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = checkBox

            local function setValue(val)
                toggVal = val
                toggleCfg.Callback(toggVal)
                TweenService:Create(checkBox, TweenInfo.new(0.2, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = toggVal and Color3.fromRGB(80,170,90) or Color3.fromRGB(70,70,70)
                }):Play()
            end

            click.MouseButton1Click:Connect(function(x, y)
                Ripple(toggFrame, x - toggFrame.AbsolutePosition.X, y - toggFrame.AbsolutePosition.Y)
                setValue(not toggVal)
            end)

            setValue(toggVal)

            return {
                Set = setValue
            }
        end

        -- AddSlider
        function TabAPI:AddSlider(sliderCfg)
            sliderCfg = sliderCfg or {}
            sliderCfg.Name = sliderCfg.Name or "New Slider"
            sliderCfg.Min = sliderCfg.Min or 0
            sliderCfg.Max = sliderCfg.Max or 100
            sliderCfg.Default = sliderCfg.Default or 50
            sliderCfg.Callback = sliderCfg.Callback or function() end

            local sliderVal = sliderCfg.Default

            local sliderFrame = Create("Frame", {
                Size = UDim2.new(1, -10, 0, 50),
                BackgroundColor3 = Darken(NovaUI.Themes[NovaUI.SelectedTheme].Secondary,0.03),
                Parent = TabContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = sliderFrame

            local label = Create("TextLabel", {
                Size = UDim2.new(1,-10,0,20),
                Position = UDim2.new(0,10,0,5),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Text = sliderCfg.Name .. ": " .. sliderVal,
                TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = sliderFrame
            })

            local barBg = Create("Frame", {
                Size = UDim2.new(1,-20,0,10),
                Position = UDim2.new(0,10,0,30),
                BackgroundColor3 = Color3.fromRGB(70,70,70),
                BorderSizePixel = 0,
                Parent = sliderFrame
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5)}).Parent = barBg

            local fill = Create("Frame", {
                Size = UDim2.new(0,0,1,0),
                BackgroundColor3 = Color3.fromRGB(80,170,90),
                BorderSizePixel = 0,
                Parent = barBg
            })
            Create("UICorner", {CornerRadius = UDim.new(0,5)}).Parent = fill

            local function setValue(v)
                sliderVal = math.clamp(v, sliderCfg.Min, sliderCfg.Max)
                local ratio = (sliderVal - sliderCfg.Min) / (sliderCfg.Max - sliderCfg.Min)
                TweenService:Create(fill, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {
                    Size = UDim2.new(ratio,0,1,0)
                }):Play()
                label.Text = sliderCfg.Name .. ": " .. sliderVal
                sliderCfg.Callback(sliderVal)
            end

            local dragging = false
            barBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                end
            end)
            barBg.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    local ratio = math.clamp((input.Position.X - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X, 0,1)
                    local val = sliderCfg.Min + (sliderCfg.Max - sliderCfg.Min)*ratio
                    setValue(math.floor(val))
                end
            end)

            setValue(sliderVal)

            return {
                Set = setValue
            }
        end

        -- AddColorpicker
        function TabAPI:AddColorpicker(colorCfg)
            colorCfg = colorCfg or {}
            colorCfg.Name = colorCfg.Name or "New Colorpicker"
            colorCfg.Default = colorCfg.Default or Color3.fromRGB(255,0,0)
            colorCfg.Callback = colorCfg.Callback or function() end

            local colorVal = colorCfg.Default

            local cFrame = Create("Frame", {
                Size = UDim2.new(1, -10, 0, 40),
                BackgroundColor3 = Darken(NovaUI.Themes[NovaUI.SelectedTheme].Secondary,0.03),
                Parent = TabContainer
            })
            Create("UICorner", {CornerRadius = UDim.new(0,6)}).Parent = cFrame

            local label = Create("TextLabel", {
                Size = UDim2.new(1,-50,1,0),
                Position = UDim2.new(0,10,0,0),
                BackgroundTransparency = 1,
                Font = Enum.Font.GothamSemibold,
                TextSize = 14,
                Text = colorCfg.Name,
                TextColor3 = NovaUI.Themes[NovaUI.SelectedTheme].Text,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = cFrame
            })

            local colorBox = Create("Frame", {
                Size = UDim2.new(0,25,0,25),
                Position = UDim2.new(1,-35,0.5,-12),
                BackgroundColor3 = colorVal,
                BorderSizePixel = 0,
                Parent = cFrame
            })
            Create("UICorner", {CornerRadius = UDim.new(0,4)}).Parent = colorBox

            local function setColor(c)
                colorVal = c
                colorBox.BackgroundColor3 = c
                colorCfg.Callback(c)
            end
            setColor(colorVal)

            local click = Create("TextButton", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Text = "",
                Parent = cFrame
            })
            click.MouseButton1Click:Connect(function(x, y)
                Ripple(cFrame, x - cFrame.AbsolutePosition.X, y - cFrame.AbsolutePosition.Y)
                -- For demonstration, randomize color
                local randomC = Color3.fromRGB(math.random(20,255), math.random(20,255), math.random(20,255))
                setColor(randomC)
            end)

            return {
                Set = setColor
            }
        end

        return TabAPI
    end

    if cfg.IntroEnabled then
        -- optional intro fade or something
    end

    return WindowAPI
end

return NovaUI
