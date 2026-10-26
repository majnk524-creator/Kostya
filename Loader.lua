--[[ Fish Test UI | ЧАСТЬ 1/4: ядро и окно. Запускай части по порядку 1 → 2 → 3 → 4 ]]

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- чистим старый запуск
local old = getgenv().FishCore
if old and old.conns then
    for _, c in ipairs(old.conns) do pcall(function() c:Disconnect() end) end
end
local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

local Theme = {
    Bg = Color3.fromRGB(18, 18, 24),
    Panel = Color3.fromRGB(26, 26, 35),
    Element = Color3.fromRGB(34, 34, 46),
    Accent = Color3.fromRGB(88, 140, 255),
    Accent2 = Color3.fromRGB(150, 90, 255),
    Text = Color3.fromRGB(235, 235, 245),
    SubText = Color3.fromRGB(140, 140, 160),
}

-- Шрифты (Gotham). Свой .ttf: вставь прямую ссылку ниже
local FontRegular = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FontBold = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local CUSTOM_TTF_URL = ""

pcall(function()
    if CUSTOM_TTF_URL ~= "" and writefile and getcustomasset then
        writefile("fishui_font.ttf", game:HttpGet(CUSTOM_TTF_URL))
        writefile("fishui_font.json", game:GetService("HttpService"):JSONEncode({
            name = "FishFont",
            faces = { { name = "Regular", weight = 400, style = "normal", assetId = getcustomasset("fishui_font.ttf") } },
        }))
        local f = Font.new(getcustomasset("fishui_font.json"), Enum.FontWeight.Regular)
        FontRegular, FontBold = f, f
    end
end)

local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(obj, r)
    return new("UICorner", { CornerRadius = UDim.new(0, r or 8) }, obj)
end

local function stroke(obj, color, thick, trans)
    return new("UIStroke", { Color = color, Thickness = thick or 1, Transparency = trans or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj)
end

local function label(parent, text, size, bold, color)
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size or 14,
        FontFace = bold and FontBold or FontRegular,
        TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

-- ScreenGui
local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function()
    local o = parentGui:FindFirstChild("FishTestUI")
    if o then o:Destroy() end
end)
local Gui = new("ScreenGui", {
    Name = "FishTestUI", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
}, parentGui)

-- Окно
local FULL = UDim2.fromOffset(540, 340)
local Main = new("Frame", {
    Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 1,
    ClipsDescendants = true,
}, Gui)
local mainCorner = corner(Main, 12)
local mainStroke = stroke(Main, Theme.Accent, 1.5, 1)
new("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Rotation = 45 }, mainStroke)

-- заполнители под панелями: нужны, чтобы скругление окна было видно и на панелях
local FillTop = new("Frame", { BackgroundColor3 = Theme.Panel, BorderSizePixel = 0 }, Main)
local Top = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0 }, Main)
local topCorner = corner(Top, 12)
local Title = label(Top, "🐟  Fish Test UI", 16, true)
Title.Position = UDim2.fromOffset(16, 0)
Title.Size = UDim2.new(1, -80, 1, 0)
local TitleGrad = new("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2) }, Title)

local Close = new("TextButton", {
    Text = "–", TextSize = 18, FontFace = FontBold, TextColor3 = Theme.SubText,
    BackgroundColor3 = Theme.Element, AutoButtonColor = false,
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0, 8),
}, Top)
corner(Close, 8)

local FillSideT = new("Frame", { Position = UDim2.fromOffset(0, 44), BackgroundColor3 = Theme.Panel, BorderSizePixel = 0 }, Main)
local FillSideR = new("Frame", { BackgroundColor3 = Theme.Panel, BorderSizePixel = 0 }, Main)
local Side = new("Frame", {
    Position = UDim2.fromOffset(0, 44), Size = UDim2.new(0, 130, 1, -44),
    BackgroundColor3 = Theme.Panel, BorderSizePixel = 0,
}, Main)
local sideCorner = corner(Side, 12)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Side)
new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, Side)

local Content = new("Frame", {
    Position = UDim2.fromOffset(130, 44), Size = UDim2.new(1, -130, 1, -44),
    BackgroundTransparency = 1,
}, Main)

-- Перетаскивание окна
do
    local dragging, startPos, startInput
    Top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, startInput, startPos = true, i.Position, Main.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startInput
            tween(Main, 0.08, {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y),
            }, Enum.EasingStyle.Linear)
        end
    end)
end

-- единое скругление: окно, верхняя панель, сайдбар и заполнители
local function setRadius(r)
    r = math.clamp(r, 0, 20)
    for _, c in ipairs({ mainCorner, topCorner, sideCorner }) do
        c.CornerRadius = UDim.new(0, r)
    end
    FillTop.Position = UDim2.fromOffset(0, 44 - r)
    FillTop.Size = UDim2.new(1, 0, 0, r)
    FillSideT.Size = UDim2.new(0, 130, 0, r)
    FillSideR.Position = UDim2.fromOffset(130 - r, 44)
    FillSideR.Size = UDim2.new(0, r, 1, -44)
end
setRadius(12)

getgenv().FishCore = {
    setRadius = setRadius,
    Gui = Gui, Main = Main, mainStroke = mainStroke, Top = Top, Close = Close, TitleGrad = TitleGrad,
    Side = Side, Content = Content, FULL = FULL, Theme = Theme,
    FontRegular = FontRegular, FontBold = FontBold,
    tween = tween, new = new, corner = corner, stroke = stroke, label = label,
    bind = bind, conns = conns,
}
print("[FishUI] часть 1 загружена")
--[[ Fish Test UI | ЧАСТЬ 2/4: аватарка, сворачивание, RightShift ]]

local C = getgenv().FishCore
assert(C, "Сначала запусти часть 1")

local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Gui, Main, mainStroke, Close = C.Gui, C.Main, C.mainStroke, C.Close
local Theme, FontBold = C.Theme, C.FontBold
local tween, new, stroke, bind = C.tween, C.new, C.stroke, C.bind
local FULL = C.FULL

local USE_PLAYER_AVATAR = false -- true = вместо рыбки твой аватар Roblox
local AV = 60
local visible = false

local Avatar = new("TextButton", {
    Name = "Avatar", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(1, -60, 0, 80), Size = UDim2.fromOffset(0, 0),
    BackgroundColor3 = Color3.new(1, 1, 1), Text = "", AutoButtonColor = false,
    Visible = false, ZIndex = 10,
}, Gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, Avatar)
new("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2), Rotation = 45 }, Avatar)
local avStroke = stroke(Avatar, Color3.new(1, 1, 1), 2.5, 0.2)

local gloss = new("Frame", {
    Size = UDim2.fromScale(0.5, 0.28), Position = UDim2.fromScale(0.2, 0.1),
    BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.8, ZIndex = 11,
}, Avatar)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, gloss)

local avatarSet = false
if USE_PLAYER_AVATAR then
    pcall(function()
        local img = Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
        local il = new("ImageLabel", {
            Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4),
            BackgroundTransparency = 1, Image = img, ZIndex = 10,
        }, Avatar)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, il)
        avatarSet = true
    end)
end
if not avatarSet then
    local fish = new("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "🐟", TextSize = 30,
        FontFace = FontBold, TextColor3 = Color3.new(1, 1, 1), ZIndex = 12,
    }, Avatar)
    task.spawn(function()
        while Gui.Parent do
            tween(fish, 1.2, { Rotation = 12 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
            tween(fish, 1.2, { Rotation = -12 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(1.2)
        end
    end)
end

task.spawn(function()
    while Gui.Parent do
        tween(avStroke, 1.1, { Transparency = 0.75 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.1)
        tween(avStroke, 1.1, { Transparency = 0.1 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
        task.wait(1.1)
    end
end)

local placed = false
local savedMainPos = Main.Position

local function showAvatar()
    if not placed then
        placed = true
        local p, s = Main.AbsolutePosition, Main.AbsoluteSize
        Avatar.Position = UDim2.fromOffset(p.X + s.X - AV / 2, p.Y + AV / 2)
    end
    Avatar.Visible = true
    Avatar.Size = UDim2.fromOffset(0, 0)
    tween(Avatar, 0.5, { Size = UDim2.fromOffset(AV, AV) }, Enum.EasingStyle.Back)
end

local function hideAvatar()
    local t = tween(Avatar, 0.25, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    t.Completed:Connect(function() if visible then Avatar.Visible = false end end)
end

local function setVisible(v)
    if v == visible and Main.Visible == v then return end
    visible = v
    if v then
        hideAvatar()
        Main.Visible = true
        if placed then Main.Position = Avatar.Position end
        tween(Main, 0.5, { Size = FULL, BackgroundTransparency = 0, Position = savedMainPos }, Enum.EasingStyle.Back)
        tween(mainStroke, 0.45, { Transparency = 0 })
    else
        savedMainPos = Main.Position
        showAvatar()
        tween(mainStroke, 0.25, { Transparency = 1 })
        local t = tween(Main, 0.35, {
            Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1, Position = Avatar.Position,
        }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Connect(function() if not visible then Main.Visible = false end end)
    end
end

-- клик по аватарке открывает меню, перетаскивание двигает её
do
    local dragging, moved, startIn, startPos
    Avatar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, startIn, startPos = true, false, i.Position, Avatar.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then setVisible(true) end
                end
            end)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startIn
            if d.Magnitude > 6 then moved = true end
            if moved then
                Avatar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    Avatar.MouseEnter:Connect(function()
        if not dragging then tween(Avatar, 0.2, { Size = UDim2.fromOffset(AV + 8, AV + 8) }, Enum.EasingStyle.Back) end
    end)
    Avatar.MouseLeave:Connect(function()
        tween(Avatar, 0.2, { Size = UDim2.fromOffset(AV, AV) })
    end)
end

-- кнопка сворачивания и горячая клавиша
Close.MouseEnter:Connect(function() tween(Close, 0.15, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }) end)
Close.MouseLeave:Connect(function() tween(Close, 0.15, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.SubText }) end)
Close.MouseButton1Click:Connect(function() setVisible(false) end)
bind(UIS.InputBegan, function(i, gp)
    if not gp and i.KeyCode == Enum.KeyCode.RightShift then setVisible(not visible) end
end)

-- анимированный градиент
task.spawn(function()
    local r = 0
    while Gui.Parent do
        r = (r + 1) % 360
        C.TitleGrad.Rotation = r
        local g = mainStroke:FindFirstChildOfClass("UIGradient")
        if g then g.Rotation = r end
        task.wait(0.03)
    end
end)

C.setVisible = setVisible
setVisible(true)
print("[FishUI] часть 2 загружена")
--[[ Fish Test UI | ЧАСТЬ 3/4: вкладки и элементы (Toggle, Slider, Button, Notify) ]]

local C = getgenv().FishCore
assert(C, "Сначала запусти части 1 и 2")

local Gui, Side, Content, Theme = C.Gui, C.Side, C.Content, C.Theme
local FontRegular = C.FontRegular
local tween, new, corner, stroke, label, bind = C.tween, C.new, C.corner, C.stroke, C.label, C.bind
local UIS = game:GetService("UserInputService")

local Library = {}
local tabs, activeTab = {}, nil

function Library:CreateTab(name, focus)
    local Btn = new("TextButton", {
        Text = name, TextSize = 14, FontFace = FontRegular, TextColor3 = Theme.SubText,
        BackgroundColor3 = Theme.Element, BackgroundTransparency = 1,
        AutoButtonColor = false, Size = UDim2.new(1, 0, 0, 34),
    }, Side)
    corner(Btn, 8)
    local Bar = new("Frame", {
        Size = UDim2.fromOffset(3, 0), Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
    }, Btn)
    corner(Bar, 2)

    local Page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
    }, Content)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, Page)
    new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, Page)

    local tab = { Btn = Btn, Bar = Bar, Page = Page }
    table.insert(tabs, tab)

    local function select()
        if activeTab == tab then return end
        for _, t in ipairs(tabs) do
            t.Page.Visible = false
            tween(t.Btn, 0.2, { BackgroundTransparency = 1, TextColor3 = Theme.SubText })
            tween(t.Bar, 0.2, { Size = UDim2.fromOffset(3, 0) })
        end
        activeTab = tab
        Page.Visible = true
        tween(Btn, 0.2, { BackgroundTransparency = 0, TextColor3 = Theme.Text })
        tween(Bar, 0.25, { Size = UDim2.fromOffset(3, 18) }, Enum.EasingStyle.Back)
        Page.Position = UDim2.fromOffset(0, 12)
        tween(Page, 0.3, { Position = UDim2.fromOffset(0, 0) })
    end
    Btn.MouseButton1Click:Connect(select)
    Btn.MouseEnter:Connect(function()
        if activeTab ~= tab then tween(Btn, 0.15, { BackgroundTransparency = 0.6 }) end
    end)
    Btn.MouseLeave:Connect(function()
        if activeTab ~= tab then tween(Btn, 0.15, { BackgroundTransparency = 1 }) end
    end)
    if not activeTab or focus then select() end

    local Tab = {}

    local function row(height)
        local f = new("Frame", { Size = UDim2.new(1, 0, 0, height or 38), BackgroundColor3 = Theme.Element }, Page)
        corner(f, 8)
        stroke(f, Theme.Accent, 1, 0.85)
        return f
    end

    function Tab:Label(text)
        local l = label(Page, text, 12, false, Theme.SubText)
        l.Size = UDim2.new(1, 0, 0, 18)
        return l
    end

    function Tab:Button(text, callback)
        local r = row()
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            Text = text, TextSize = 14, FontFace = FontRegular, TextColor3 = Theme.Text,
        }, r)
        b.MouseEnter:Connect(function() tween(r, 0.15, { BackgroundColor3 = Color3.fromRGB(44, 44, 60) }) end)
        b.MouseLeave:Connect(function() tween(r, 0.15, { BackgroundColor3 = Theme.Element }) end)
        b.MouseButton1Click:Connect(function()
            tween(r, 0.08, { Size = UDim2.new(1, -6, 0, 36) })
            task.delay(0.08, function() tween(r, 0.2, { Size = UDim2.new(1, 0, 0, 38) }, Enum.EasingStyle.Back) end)
            if callback then task.spawn(callback) end
        end)
    end

    function Tab:Toggle(text, default, callback)
        local state = default or false
        local r = row()
        local l = label(r, text, 14)
        l.Position = UDim2.fromOffset(12, 0)
        l.Size = UDim2.new(1, -70, 1, 0)
        local track = new("TextButton", {
            Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(42, 22),
            Position = UDim2.new(1, -54, 0.5, -11),
            BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(55, 55, 72),
        }, r)
        corner(track, 11)
        local knob = new("Frame", {
            Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Color3.new(1, 1, 1),
            Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3),
        }, track)
        corner(knob, 8)
        local function set(v)
            state = v
            tween(track, 0.2, { BackgroundColor3 = v and Theme.Accent or Color3.fromRGB(55, 55, 72) })
            tween(knob, 0.25, { Position = v and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) }, Enum.EasingStyle.Back)
            if callback then task.spawn(callback, v) end
        end
        track.MouseButton1Click:Connect(function() set(not state) end)
        return { Set = function(_, v) set(v) end, Get = function() return state end }
    end

    function Tab:Slider(text, min, max, default, callback)
        local value = default or min
        local r = row(52)
        local l = label(r, text, 14)
        l.Position = UDim2.fromOffset(12, 6)
        l.Size = UDim2.new(1, -80, 0, 18)
        local v = label(r, tostring(value), 14, true, Theme.Accent)
        v.TextXAlignment = Enum.TextXAlignment.Right
        v.Position = UDim2.new(1, -62, 0, 6)
        v.Size = UDim2.fromOffset(50, 18)
        local bar = new("Frame", {
            Position = UDim2.new(0, 12, 1, -16), Size = UDim2.new(1, -24, 0, 6),
            BackgroundColor3 = Color3.fromRGB(55, 55, 72),
        }, r)
        corner(bar, 3)
        local fill = new("Frame", {
            Size = UDim2.fromScale((value - min) / (max - min), 1), BackgroundColor3 = Theme.Accent,
        }, bar)
        corner(fill, 3)
        new("UIGradient", { Color = ColorSequence.new(Theme.Accent, Theme.Accent2) }, fill)

        local dragging = false
        local function update(x)
            local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            value = math.floor(min + (max - min) * a + 0.5)
            v.Text = tostring(value)
            tween(fill, 0.08, { Size = UDim2.fromScale(a, 1) }, Enum.EasingStyle.Linear)
            if callback then task.spawn(callback, value) end
        end
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                update(i.Position.X)
            end
        end)
        bind(UIS.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
        bind(UIS.InputChanged, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                update(i.Position.X)
            end
        end)

        return {
            Set = function(_, nv)
                value = math.clamp(nv, min, max)
                v.Text = tostring(value)
                fill.Size = UDim2.fromScale((value - min) / (max - min), 1)
            end,
        }
    end

    -- Выпадающий список с поиском. callback(индекс выбранного пункта)
    function Tab:Dropdown(text, options, callback)
        local HEAD, SEARCH, ITEM, MAXV = 38, 30, 28, 5
        local selected
        local open = false
        local listH = math.min(#options, MAXV) * (ITEM + 2)

        -- нижний регистр с поддержкой кириллицы
        local function lower(s)
            local ok, res = pcall(function()
                local out = {}
                for _, cp in utf8.codes(s) do
                    local c = cp
                    if c >= 0x41 and c <= 0x5A then c += 32
                    elseif c >= 0x410 and c <= 0x42F then c += 32
                    elseif c == 0x401 then c = 0x451 end
                    out[#out + 1] = utf8.char(c)
                end
                return table.concat(out)
            end)
            return ok and res or s:lower()
        end

        local r = new("Frame", {
            Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = Theme.Element, ClipsDescendants = true,
        }, Page)
        corner(r, 8)
        stroke(r, Theme.Accent, 1, 0.85)

        local head = new("TextButton", {
            Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
        }, r)
        local l = label(head, text, 14)
        l.Position = UDim2.fromOffset(12, 0)
        l.Size = UDim2.new(1, -44, 1, 0)
        l.TextTruncate = Enum.TextTruncate.AtEnd
        local arrow = label(head, "▼", 12, true, Theme.Accent)
        arrow.TextXAlignment = Enum.TextXAlignment.Center
        arrow.Size = UDim2.fromOffset(24, HEAD)
        arrow.Position = UDim2.new(1, -32, 0, 0)

        local box = new("TextBox", {
            Position = UDim2.fromOffset(8, HEAD + 2), Size = UDim2.new(1, -16, 0, SEARCH - 4),
            BackgroundColor3 = Theme.Panel, Text = "", PlaceholderText = "Поиск...",
            PlaceholderColor3 = Theme.SubText, TextColor3 = Theme.Text, TextSize = 13,
            FontFace = FontRegular, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        }, r)
        corner(box, 6)
        new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)

        local list = new("ScrollingFrame", {
            Position = UDim2.fromOffset(8, HEAD + SEARCH + 2), Size = UDim2.new(1, -16, 0, listH),
            BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent, CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, r)
        new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, list)

        local function fullHeight() return HEAD + SEARCH + listH + 8 end

        local function setOpen(v)
            open = v
            tween(arrow, 0.2, { Rotation = v and 180 or 0 })
            tween(r, 0.25, { Size = UDim2.new(1, 0, 0, v and fullHeight() or HEAD) })
        end

        local function choose(i)
            selected = i
            l.Text = text .. ": " .. options[i]
            setOpen(false)
            if callback then task.spawn(callback, i) end
        end

        local items, lowered = {}, {}
        for i, name in ipairs(options) do
            lowered[i] = lower(name)
            local b = new("TextButton", {
                LayoutOrder = i, Size = UDim2.new(1, -6, 0, ITEM), BackgroundColor3 = Theme.Panel,
                BackgroundTransparency = 0.4, AutoButtonColor = false, Text = name, TextSize = 13,
                FontFace = FontRegular, TextColor3 = Theme.Text,
                TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
            }, list)
            corner(b, 6)
            new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, b)
            b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0 }) end)
            b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundTransparency = 0.4 }) end)
            b.MouseButton1Click:Connect(function() choose(i) end)
            items[i] = b
        end

        box:GetPropertyChangedSignal("Text"):Connect(function()
            local q = lower(box.Text)
            local n = 0
            for i, b in ipairs(items) do
                local show = q == "" or lowered[i]:find(q, 1, true) ~= nil
                b.Visible = show
                if show then n += 1 end
            end
            listH = math.max(1, math.min(n, MAXV)) * (ITEM + 2)
            list.Size = UDim2.new(1, -16, 0, listH)
            if open then tween(r, 0.15, { Size = UDim2.new(1, 0, 0, fullHeight()) }) end
        end)
        head.MouseButton1Click:Connect(function() setOpen(not open) end)

        return {
            Get = function() return selected end,
            Set = function(_, i)
                if options[i] then
                    selected = i
                    l.Text = text .. ": " .. options[i]
                end
            end,
        }
    end

    return Tab
end

function Library:Notify(text, duration)
    local n = new("Frame", {
        AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 300, 1, -20),
        Size = UDim2.fromOffset(240, 44), BackgroundColor3 = Theme.Panel,
    }, Gui)
    corner(n, 10)
    stroke(n, Theme.Accent, 1.2, 0.3)
    local l = label(n, text, 14)
    l.Position = UDim2.fromOffset(14, 0)
    l.Size = UDim2.new(1, -28, 1, 0)
    tween(n, 0.4, { Position = UDim2.new(1, -20, 1, -20) }, Enum.EasingStyle.Back)
    task.delay(duration or 3, function()
        local t = tween(n, 0.3, { Position = UDim2.new(1, 300, 1, -20) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        t.Completed:Connect(function() n:Destroy() end)
    end)
end

getgenv().FishUI = Library
print("[FishUI] часть 3 загружена")
--[[ Fish Test UI | ЧАСТЬ 4/4: вкладка «Игрок» (тесты движения для античита) ]]

local C, Lib = getgenv().FishCore, getgenv().FishUI
assert(C and Lib, "Сначала запусти части 1, 2 и 3")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer

-- чистим прошлый запуск этой части
if getgenv().FishPlayerConns then
    for _, c in ipairs(getgenv().FishPlayerConns) do pcall(function() c:Disconnect() end) end
end
local conns = {}
getgenv().FishPlayerConns = conns
local function bind(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end

local Flags = { inf = false, noclip = false, afk = false, ctp = false }
local S = {}
local orig = { speed = 16, jp = 50, usejp = true, grav = 196.2, fov = 70 }

-- ===== Флай =====
local bv, bg
local function stopFly()
    if bv then bv:Destroy() bv = nil end
    if bg then bg:Destroy() bg = nil end
    local h = hum()
    if h then h.PlatformStand = false end
end

local function flyStep()
    local r, h = root(), hum()
    if not (r and h) then return end
    if not bv or bv.Parent ~= r then
        if bv then bv:Destroy() end
        if bg then bg:Destroy() end
        bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bv.Velocity = Vector3.zero
        bv.Parent = r
        bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        bg.P = 1e4
        bg.Parent = r
    end
    h.PlatformStand = true
    local cf = workspace.CurrentCamera.CFrame
    local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
    local right = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
    look = look.Magnitude > 0.01 and look.Unit or Vector3.zero
    right = right.Magnitude > 0.01 and right.Unit or Vector3.zero
    local md = h.MoveDirection
    local vel = cf.LookVector * md:Dot(look) + cf.RightVector * md:Dot(right)
    if UIS:IsKeyDown(Enum.KeyCode.Space) then vel += Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel -= Vector3.yAxis end
    if vel.Magnitude > 1 then vel = vel.Unit end
    bv.Velocity = vel * S.fly.v
    if look.Magnitude > 0 then
        bg.CFrame = CFrame.lookAt(r.Position, r.Position + look)
    end
end

-- ===== сохранение / восстановление значений =====
local function capture(key)
    local h = hum()
    if key == "speed" and h then orig.speed = h.WalkSpeed
    elseif key == "jump" and h then orig.jp = h.JumpPower orig.usejp = h.UseJumpPower
    elseif key == "grav" then orig.grav = workspace.Gravity
    elseif key == "fov" then orig.fov = workspace.CurrentCamera.FieldOfView end
end

local function restore(key)
    local h = hum()
    if key == "speed" and h then h.WalkSpeed = orig.speed
    elseif key == "jump" and h then h.UseJumpPower = orig.usejp h.JumpPower = orig.jp
    elseif key == "grav" then workspace.Gravity = orig.grav
    elseif key == "fov" then workspace.CurrentCamera.FieldOfView = orig.fov
    elseif key == "fly" then stopFly() end
end

local function feature(tab, name, key, min, max, def)
    S[key] = { on = false, v = def }
    tab:Toggle(name, false, function(on)
        S[key].on = on
        if on then capture(key) else restore(key) end
    end)
    tab:Slider(name .. " (знач.)", min, max, def, function(v) S[key].v = v end)
end

-- ===== Ноуклип =====
-- Humanoid встаёт на низкие и наклонные препятствия, поэтому одного отключения
-- коллизий персонажа мало. Здесь локально отключаются все объекты выше уровня ног,
-- а пол и невысокие ступеньки остаются твёрдыми.
local modified = {}
local ncParams = OverlapParams.new()
ncParams.FilterType = Enum.RaycastFilterType.Exclude

local function unmark(p)
    if modified[p] then
        modified[p] = nil
        pcall(function() p.CanCollide = true end)
    end
end

local function clearNoclip()
    for p in pairs(modified) do unmark(p) end
end

local function topY(p)
    local cf, s = p.CFrame, p.Size
    return p.Position.Y + (math.abs(cf.XVector.Y) * s.X + math.abs(cf.YVector.Y) * s.Y + math.abs(cf.ZVector.Y) * s.Z) / 2
end

local function noclipStep()
    local c, r = LP.Character, root()
    if not (c and r) then return end
    local chars = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl.Character then table.insert(chars, pl.Character) end
    end
    ncParams.FilterDescendantsInstances = chars
    local bbCF, bbSize = c:GetBoundingBox()
    local limit = bbCF.Position.Y - bbSize.Y / 2 + 1.5
    local seen = {}
    for _, p in ipairs(workspace:GetPartBoundsInRadius(r.Position, 14, ncParams)) do
        seen[p] = true
        if topY(p) > limit then
            if p.CanCollide then
                modified[p] = true
                p.CanCollide = false
            end
        else
            unmark(p)
        end
    end
    for p in pairs(modified) do
        if not seen[p] then unmark(p) end
    end
end

-- ===== Вкладка =====
local Tab = Lib:CreateTab("Игрок")
Tab:Label("Движение")
Tab:Toggle("Бесконечный прыжок", false, function(v) Flags.inf = v end)
feature(Tab, "Скорость", "speed", 16, 250, 60)
feature(Tab, "Сила прыжка", "jump", 50, 300, 120)
feature(Tab, "Полёт", "fly", 10, 200, 60)
Tab:Label("Полёт: Space вверх, Shift вниз. На телефоне летишь туда, куда смотрит камера.")
Tab:Toggle("Ноуклип", false, function(v)
    Flags.noclip = v
    if not v then clearNoclip() end
end)

Tab:Label("Дополнительно")
feature(Tab, "Гравитация", "grav", 0, 400, 50)
feature(Tab, "Поле зрения (FOV)", "fov", 40, 120, 100)
Tab:Toggle("Анти-AFK", false, function(v) Flags.afk = v end)
Tab:Toggle("Телепорт по Ctrl+клик", false, function(v) Flags.ctp = v end)
Tab:Button("Сбросить персонажа", function()
    local h = hum()
    if h then h.Health = 0 end
end)

-- ===== Главный цикл =====
bind(RunService.Heartbeat, function()
    local h = hum()
    if not h then return end
    if S.speed.on then h.WalkSpeed = S.speed.v end
    if S.jump.on then
        h.UseJumpPower = true
        h.JumpPower = S.jump.v
    end
    if S.grav.on then workspace.Gravity = S.grav.v end
    if S.fov.on then workspace.CurrentCamera.FieldOfView = S.fov.v end
    if S.fly.on then flyStep() end
end)

bind(RunService.Stepped, function()
    if Flags.noclip then noclipStep() end
end)

bind(UIS.JumpRequest, function()
    if not Flags.inf then return end
    local h = hum()
    if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

bind(LP.Idled, function()
    if not Flags.afk then return end
    local vu = game:GetService("VirtualUser")
    vu:CaptureController()
    vu:ClickButton2(Vector2.new())
end)

bind(UIS.InputBegan, function(i, gp)
    if gp or not Flags.ctp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        local m, r = LP:GetMouse(), root()
        if r and m.Hit then r.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0)) end
    end
end)

-- ===== Настройки =====
-- вкладка «Настройки» создаётся в конце общего файла; здесь только откат функций игрока
C.unloadPlayer = function()
    for k, f in pairs(S) do
        if f.on then f.on = false restore(k) end
    end
    Flags.noclip, Flags.inf = false, false
    clearNoclip()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end

Lib:Notify("Вкладка «Игрок» загружена")
print("[FishUI] часть 4 загружена")
--[[ Fish Test UI | ЧАСТЬ 5/5: оформление (цвет, фон, скругление, радуга) в «Настройках» ]]

local C = getgenv().FishCore
assert(C and C.SettingsTab, "Сначала запусти части 1-4")

local HttpService = game:GetService("HttpService")
local Theme, Set = C.Theme, C.SettingsTab
local FILE = "fishui_theme.json"
local ROLES = { "Bg", "Panel", "Element", "Accent", "Accent2" }

local DEFAULT_THEME = {
    Bg = Color3.fromRGB(18, 18, 24),
    Panel = Color3.fromRGB(26, 26, 35),
    Element = Color3.fromRGB(34, 34, 46),
    Accent = Color3.fromRGB(88, 140, 255),
    Accent2 = Color3.fromRGB(150, 90, 255),
}
local DEFAULT_ST = { hue = 219, sat = 65, bg = 9, rad = 12 }

local st = { hue = 219, sat = 65, bg = 9, rad = 12 }
local hadSave = false
pcall(function()
    if isfile and isfile(FILE) then
        local d = HttpService:JSONDecode(readfile(FILE))
        for k, v in pairs(d) do
            if st[k] ~= nil and type(v) == "number" then st[k] = v end
        end
        hadSave = true
    end
end)

local function key(c)
    return math.floor(c.R * 255 + 0.5) * 65536 + math.floor(c.G * 255 + 0.5) * 256 + math.floor(c.B * 255 + 0.5)
end

-- собираем тему из ползунков
local function build()
    local v = st.bg / 100
    local s = st.sat / 100
    local t = {
        Accent = Color3.fromHSV(st.hue / 360, s, 1),
        Accent2 = Color3.fromHSV(((st.hue + 47) % 360) / 360, s, 1),
        Bg = Color3.fromHSV(0.667, 0.25, v),
        Panel = Color3.fromHSV(0.667, 0.25, math.min(v + 0.045, 1)),
        Element = Color3.fromHSV(0.667, 0.25, math.min(v + 0.09, 1)),
    }
    -- все пять цветов должны отличаться, иначе потом не определить, что где
    local used = {}
    for _, k in ipairs(ROLES) do
        local c = t[k]
        local r, g, b = math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
        local n = 0
        while used[key(c)] and n < 6 do
            n += 1
            c = Color3.fromRGB(r, g, (b + n) % 256)
        end
        used[key(c)] = true
        t[k] = c
    end
    return t
end

-- перекрашиваем весь интерфейс: старые цвета темы -> новые
local function applyColors(new)
    local lookup = {}
    for _, k in ipairs(ROLES) do lookup[key(Theme[k])] = k end
    local function map(c)
        local k = lookup[key(c)]
        return k and new[k] or c
    end
    for _, d in ipairs(C.Gui:GetDescendants()) do
        pcall(function()
            if d:IsA("GuiObject") then
                d.BackgroundColor3 = map(d.BackgroundColor3)
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    d.TextColor3 = map(d.TextColor3)
                end
                if d:IsA("ScrollingFrame") then
                    d.ScrollBarImageColor3 = map(d.ScrollBarImageColor3)
                end
            elseif d:IsA("UIStroke") then
                d.Color = map(d.Color)
            elseif d:IsA("UIGradient") then
                local pts = {}
                for i, kp in ipairs(d.Color.Keypoints) do
                    pts[i] = ColorSequenceKeypoint.new(kp.Time, map(kp.Value))
                end
                d.Color = ColorSequence.new(pts)
            end
        end)
    end
    for _, k in ipairs(ROLES) do Theme[k] = new[k] end
end

local function applyRadius()
    C.setRadius(st.rad)
end

-- автосохранение
local saveToken = 0
local function save()
    saveToken += 1
    local my = saveToken
    task.delay(1, function()
        if my ~= saveToken then return end
        pcall(function()
            if writefile then writefile(FILE, HttpService:JSONEncode(st)) end
        end)
    end)
end

local function refresh()
    applyColors(build())
    applyRadius()
    save()
end

-- ===== Элементы в «Настройках» =====
Set:Label("Оформление (сохраняется автоматически)")
local hueS = Set:Slider("Цвет (оттенок)", 0, 360, st.hue, function(v) st.hue = v refresh() end)
local satS = Set:Slider("Насыщенность", 10, 100, st.sat, function(v) st.sat = v refresh() end)
local bgS = Set:Slider("Яркость фона", 3, 30, st.bg, function(v) st.bg = v refresh() end)
local radS = Set:Slider("Скругление окна", 0, 20, st.rad, function(v) st.rad = v refresh() end)

local rainbow = false
Set:Toggle("Радужный режим", false, function(v) rainbow = v end)

Set:Button("Сбросить оформление", function()
    rainbow = false
    for k, v in pairs(DEFAULT_ST) do st[k] = v end
    applyColors(DEFAULT_THEME)
    applyRadius()
    hueS:Set(st.hue) satS:Set(st.sat) bgS:Set(st.bg) radS:Set(st.rad)
    save()
end)

task.spawn(function()
    while C.Gui.Parent do
        if rainbow then
            st.hue = (st.hue + 4) % 361
            applyColors(build())
            hueS:Set(st.hue)
        end
        task.wait(0.12)
    end
end)

-- применяем сохранённую тему при запуске
if hadSave then
    applyColors(build())
    applyRadius()
end

print("[FishUI] часть 5 загружена")
--[[ Fish Test UI | ЧАСТЬ 6/7: движок телепорта и данные (острова, NPC, места)
     Координаты взяты из публичных гайдов по Fisch, часть может устареть.
     Проверить свою позицию: кнопка «Мои координаты». ]]

local C, Lib = getgenv().FishCore, getgenv().FishUI
assert(C and Lib, "Сначала запусти части 1-4")

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local V = Vector3.new

local function root() local c = LP.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = LP.Character return c and c:FindFirstChildOfClass("Humanoid") end

local lift = 4
local lastPos

local function tpTo(pos)
    local r, h = root(), hum()
    if not r then Lib:Notify("Нет персонажа") return end
    if h and h.SeatPart then
        h.Sit = false
        task.wait(0.1)
    end
    pcall(function() LP:RequestStreamAroundAsync(pos) end) -- подгрузить далёкую зону
    r = root()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = CFrame.new(pos + V(0, lift, 0))
    end
end

-- поиск NPC/объекта по имени в мире (если координат нет)
local function findPos(name)
    for _, d in ipairs(workspace:GetDescendants()) do
        if d.Name == name and not (LP.Character and d:IsDescendantOf(LP.Character)) then
            if d:IsA("Model") then
                local ok, cf = pcall(function() return d:GetPivot() end)
                if ok then return cf.Position end
            elseif d:IsA("BasePart") then
                return d.Position
            end
        end
    end
end

-- запись: { название, координаты, имя для поиска, зона для подгрузки }
local function go(e)
    local label, pos, find, near = e[1], e[2], e[3], e[4]
    local r = root()
    if not r then Lib:Notify("Нет персонажа") return end
    lastPos = r.Position
    if pos then
        tpTo(pos)
        Lib:Notify("ТП: " .. label)
        return
    end
    if near then
        tpTo(near)
        task.wait(1.5)
    end
    local p = find and findPos(find)
    if p then
        tpTo(p)
        Lib:Notify("ТП: " .. label)
    else
        Lib:Notify(label .. ": не найден" .. (near and ", ты в центре зоны" or ""))
    end
end

local function back()
    local r = root()
    if not (r and lastPos) then
        Lib:Notify("Нет сохранённой точки")
        return
    end
    local cur = r.Position
    tpTo(lastPos)
    lastPos = cur
end

local function coords()
    local r = root()
    if not r then return end
    local p = r.Position
    local s = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    pcall(function() setclipboard(s) end)
    Lib:Notify(s, 5)
end

-- ===== Данные =====
local ISLANDS = {
    { "Moosewood (старт)", V(400, 135, 250) },
    { "Mushgrove Swamp", V(2420, 135, -750) },
    { "Roslit Bay", V(-1600, 130, 500) },
    { "Snowcap Island", V(2625, 135, 2370) },
    { "Statue of Sovereignty", V(35, 135, -1010) },
    { "Sunstone Island", V(-870, 135, -1100) },
    { "Terrapin Island", V(-95, 130, 1875) },
    { "Harvesters Spike", V(-1260, 135, 1550) },
    { "The Arch", V(1100, 130, -1250) },
    { "Birch Cay", V(1650, 130, -2350) },
    { "Haddock Rock", V(-500, 125, -505) },
    { "Earmark Island", V(1200, 130, 530) },
    { "Desolate Deep", V(-800, 130, -3100) },
    { "Forsaken Shores", V(-2488, 134, 1474) },
    { "Ancient Isle", V(6000, 200, 300) },
    { "Everturn Forest", V(2460, 154, -2359) },
    { "Scoria Reach", V(-4806, 138, -1368) },
    { "Castaway Cliffs (корабль)", V(347, 130, -2323) },
    { "Lost Jungle (ориентир)", V(-2902, 258, -2177) },
}

local NORTH = {
    { "Портал в экспедицию", V(-1750, 130, 3750) },
    { "Северная вершина (лагерь 1)", V(19500, 135, 5300) },
    { "Overgrowth Caves (лагерь 2)", V(20300, 275, 5400) },
    { "Frigid Cavern (лагерь 3)", V(20300, 415, 5640) },
    { "Cryogenic Canal (лагерь 4)", V(20000, 780, 5700) },
    { "Glacial Grotto (лагерь 5)", V(20000, 1040, 5700) },
}

local NPC = {
    { "Moosewood: Пьер (Pierre)", V(390, 135, 200) },
    { "Moosewood: Финеас (Phineas)", V(470, 150, 275) },
    { "Moosewood: Торговец", V(465, 150, 230) },
    { "Moosewood: Оценщик (Appraiser)", V(450, 150, 210) },
    { "Moosewood: Хранитель фонаря", V(655, 165, 260) },
    { "Roslit Bay: Кузнец", V(-1515, 140, 760) },
    { "Roslit Bay: Орк (Orc)", V(-1850, 165, 160) },
    { "Roslit Bay: Торговец", V(-1454, 133, 675) },
    { "Snowcap: Уилсон (Wilson)", V(2940, 280, 2570) },
    { "Snowcap: Торговец", V(2717, 157, 2374) },
    { "Sunstone: Мерлин (Merlin)", V(-930, 225, -990) },
    { "Sunstone: Торговец", V(-930, 130, -1105) },
    { "The Arch: Калеа (Caleia)", V(980, 130, -1230) },
    { "Terrapin: Магнит-удочка", V(-195, 130, 1930) },
    { "Mushgrove: Агарик / аллигаторы", V(2665, 130, -710) },
    { "Ancient Isle: Судостроитель", V(5970, 140, 10) },
    { "Ancient Isle: Торговец и Chiseler", V(6080, 195, 300) },
    { "Ancient Isle: Хозяин таверны", V(6050, 200, 335) },
    { "Ancient Isle: Метеоритчик", V(5920, 260, 595) },
}

local PLACES = {
    { "Ancient Isle: Древний архив (пещера)", V(5870, 160, 415) },
    { "Ancient Isle: Эклипс-тотем / Феникс", V(5950, 270, 890) },
    { "Ancient Isle: Каменное удилище", V(5500, 145, -315) },
    { "Тотем Smokescreen (Mushgrove)", V(2790, 140, -630) },
    { "Тотем Windset (Snowcap)", V(2850, 180, 2700) },
    { "Тотем Meteor (вулкан Roslit)", V(-1950, 275, 230) },
    { "Вход к Sundial (Sunstone)", V(-1215, 195, -1045) },
    { "Вход к Tempest (Terrapin)", V(20, 110, 1860) },
    { "Тотем Avalanche (экспедиция)", V(19710, 470, 6060) },
    { "Тотем Blizzard (экспедиция)", V(20150, 745, 5805) },
    { "Алтарь Хранителя (под водой)", V(1375, -805, -300) },
}

getgenv().FishTP = {
    V = V, root = root, hum = hum, tpTo = tpTo, findPos = findPos,
    go = go, back = back, coords = coords,
    setLift = function(v) lift = v end,
    getLift = function() return lift end,
    cats = {
        { "Острова", ISLANDS },
        { "Северная экспедиция", NORTH },
        { "NPC", NPC },
        { "Места и тотемы", PLACES },
    },
}

print("[FishUI] часть 6 загружена")
--[[ Fish Test UI | ЧАСТЬ 7/7: единая вкладка «Телепорт»
     Для каждой категории: кнопка «Телепорт на локацию» и ниже список выбора с поиском. ]]

local C, Lib, TP = getgenv().FishCore, getgenv().FishUI, getgenv().FishTP
assert(C and Lib and TP, "Сначала запусти части 1-6")

local Players = game:GetService("Players")
local V, root, go = TP.V, TP.root, TP.go

-- ===== Ивент FischFright 3: Caustic Hallow =====
local CENTER = V(-14706, 146.8, -9723.2) -- центр города

local EVENT = {
    { "Центр города (Vanni Kitty)", CENTER },
    { "Церковь (вход)", V(-15171.7, 167.6, -9637) },
    { "Fisch-Slinging Caster (вторник)", V(-15189, 167, -9577) },
    { "Doomsekkar (кладбище)", V(-14993, 147, -9666) },
    { "Frankenstein (круг ритуалов)", V(-15104, 146, -9621) },
    { "Webby Winston (пещера)", V(-15069, 142, -9981) },
    { "Pumpkin Pete", V(-14727, 148, -10009) },
    { "Rave (диско)", V(-14591, 198, -9936) },
    { "Диско-шар (листва)", V(-14473.7, 202.1, -9878.1) },
    { "Платформа за особняком", V(-15059, 242.1, -10164.5) },
    { "Страж-пугало (вход в лабиринт)", V(-14966, 181, -9430) },
    { "Пугало 1", V(-14951, 181, -9404) },
    { "Пугало 2", V(-14929, 181, -9346) },
    { "Пугало 3", V(-15047, 181, -9427) },
    { "Пугало 4", V(-15021, 181, -9442) },
    { "Пугало 5", V(-15066, 181, -9403) },
    { "Пугало 6", V(-15050, 182, -9552) },
    -- координат в гайдах нет: ТП в центр зоны и поиск модели по имени
    { "Pumpkin King (фонтан)", nil, "Pumpkin King", CENTER },
    { "Dullahan (особняк)", nil, "Dullahan", CENTER },
    { "Frightful Merchant", nil, "Frightful Merchant", CENTER },
    { "Youngster Goblin", nil, "Youngster Goblin", CENTER },
    { "Dutchman Merchant (корабль)", nil, "Dutchman Merchant", CENTER },
    { "Dutchman Captain (Moosewood)", nil, "Dutchman Captain", V(400, 135, 250) },
}

-- все категории: из части 6 + ивент
local cats = {}
for _, c in ipairs(TP.cats) do table.insert(cats, c) end
table.insert(cats, { "Ивент (Caustic Hallow)", EVENT })

-- ===== Вкладка =====
local Tab = Lib:CreateTab("Телепорт")
Tab:Label("Координаты из гайдов, часть может устареть")
Tab:Slider("Высота над точкой", 0, 50, TP.getLift(), TP.setLift)
Tab:Button("Назад (прошлая точка)", TP.back)
Tab:Button("Мои координаты (скопировать)", TP.coords)

-- секция: кнопка телепорта сверху, список выбора ниже
local function section(title, names, entries)
    Tab:Label(title)
    local idx
    Tab:Button("Телепорт на локацию", function()
        if not idx then
            Lib:Notify("Сначала выбери локацию")
            return
        end
        go(entries[idx])
    end)
    Tab:Dropdown("Выбор локации", names, function(i) idx = i end)
end

-- общий поиск по всем категориям
local allNames, allEntries = {}, {}
for _, c in ipairs(cats) do
    for _, e in ipairs(c[2]) do
        table.insert(allNames, "[" .. c[1] .. "] " .. e[1])
        table.insert(allEntries, e)
    end
end
section("Поиск по всем локациям", allNames, allEntries)

for _, c in ipairs(cats) do
    local names = {}
    for i, e in ipairs(c[2]) do names[i] = e[1] end
    section(c[1], names, c[2])
end

-- ===== Гоблины =====
local function nearestGoblin()
    local r = root()
    if not r then return end
    local best, bd
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name:lower():find("goblin") and not d.Name:lower():find("youngster")
            and not Players:GetPlayerFromCharacter(d) then
            local ok, cf = pcall(function() return d:GetPivot() end)
            -- только гоблины на островах: всё, что у Caustic Hallow, пропускаем
            if ok and (cf.Position - CENTER).Magnitude > 2500 then
                local dist = (cf.Position - r.Position).Magnitude
                if not bd or dist < bd then best, bd = cf.Position, dist end
            end
        end
    end
    return best
end

Tab:Label("Гоблины: спавн каждые 5 минут, на задание 15 минут")
Tab:Button("ТП к ближайшему гоблину", function()
    local p = nearestGoblin()
    if p then
        go({ "Гоблин", p })
    else
        Lib:Notify("Гоблинов сейчас нет (или они не подгружены)", 4)
    end
end)

local watch = false
local lastNote = 0
if getgenv().FishGobConn then pcall(function() getgenv().FishGobConn:Disconnect() end) end
getgenv().FishGobConn = workspace.DescendantAdded:Connect(function(d)
    if watch and d:IsA("Model") and d.Name:lower():find("goblin") and not d.Name:lower():find("youngster")
        and not Players:GetPlayerFromCharacter(d) then
        if os.clock() - lastNote > 3 then
            lastNote = os.clock()
            Lib:Notify("Появился гоблин: " .. d.Name, 5)
        end
    end
end)
Tab:Toggle("Уведомлять о появлении гоблинов", false, function(v) watch = v end)

print("[FishUI] часть 7 загружена")
--[[ Fish Test UI | ЧАСТЬ 8/9: ядро автоматики ивента
     Нажатия на подсказки, клики по диалогам (реальные клики мыши), разблокировка экрана, диагностика. ]]

local C, Lib, TP = getgenv().FishCore, getgenv().FishUI, getgenv().FishTP
assert(C and Lib and TP, "Сначала запусти части 1-7")

local Players = game:GetService("Players")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local LP = Players.LocalPlayer
local V, root, hum = TP.V, TP.root, TP.hum

local runId = (getgenv().FishEvRun or 0) + 1
getgenv().FishEvRun = runId
local function alive() return getgenv().FishEvRun == runId and C.Gui.Parent ~= nil end

local CENTER = V(-14706, 146.8, -9723.2) -- центр Caustic Hallow
local MOOSE = V(400, 135, 250)
local F = {} -- флаги функций

local function low(s) return string.lower(tostring(s or "")) end
local function plain(o) return (tostring(o.Text):gsub("<[^>]+>", "")) end
local function pgui() return LP:FindFirstChildOfClass("PlayerGui") end

-- ===== Перемещение и подсказки (ProximityPrompt) =====
local function near(pos)
    if not root() then return false end
    pcall(function() LP:RequestStreamAroundAsync(pos) end)
    local r = root()
    if r then
        r.AssemblyLinearVelocity = Vector3.zero
        r.CFrame = CFrame.new(pos + V(0, 3, 0))
    end
    task.wait(0.35)
    return true
end

local function onEvent()
    local r = root()
    return r ~= nil and (r.Position - CENTER).Magnitude < 2500
end

local function promptPos(p)
    local a = p.Parent
    if not a then return end
    if a:IsA("BasePart") then return a.Position end
    if a:IsA("Attachment") then return a.WorldPosition end
    if a:IsA("Model") then
        local ok, cf = pcall(function() return a:GetPivot() end)
        if ok then return cf.Position end
    end
end

local function press(p)
    pcall(function() p.HoldDuration = 0 end)
    pcall(function() p.RequiresLineOfSight = false end)
    if fireproximityprompt then
        pcall(fireproximityprompt, p)
    else
        pcall(function() p:InputHoldBegin() task.wait(0.1) p:InputHoldEnd() end)
    end
end

-- ближайший включённый промпт к точке; match(prompt) уточняет выбор
local function promptNear(pos, radius, match)
    local best, bd
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local pp = promptPos(d)
            if pp then
                local dist = (pp - pos).Magnitude
                if dist <= radius and (not bd or dist < bd) and (not match or match(d)) then
                    best, bd = d, dist
                end
            end
        end
    end
    return best
end

-- ===== Интерфейс игры: поиск и клик =====
local function shown(o)
    while o and o ~= game do
        if o:IsA("GuiObject") and not o.Visible then return false end
        if o:IsA("ScreenGui") and not o.Enabled then return false end
        o = o.Parent
    end
    return true
end

-- все видимые тексты в ScreenGui игрока (подсказки над объектами не считаются)
local function uiTexts()
    local list, gui = {}, pgui()
    if not gui then return list end
    for _, d in ipairs(gui:GetDescendants()) do
        if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" and d.AbsoluteSize.X > 0
            and d:FindFirstAncestorOfClass("ScreenGui") and shown(d) then
            list[#list + 1] = d
        end
    end
    return list
end

-- короткий видимый текст (вариант ответа), содержащий слова include и не содержащий exclude
local function findOption(include, exclude)
    local best
    for _, d in ipairs(uiTexts()) do
        local t = low(plain(d))
        if #t > 0 and #t <= 40 then
            for _, k in ipairs(include) do
                if t:find(k, 1, true) then
                    local bad = false
                    for _, x in ipairs(exclude or {}) do
                        if t:find(x, 1, true) then bad = true end
                    end
                    if not bad and (not best or d:IsA("TextButton")) then best = d end
                    break
                end
            end
        end
    end
    return best
end

local function clickBtn(b) -- запасной способ: вызвать обработчики кнопки напрямую
    if getconnections then
        for _, sig in ipairs({ b.MouseButton1Click, b.Activated }) do
            local ok, cs = pcall(getconnections, sig)
            if ok and #cs > 0 then
                for _, c in ipairs(cs) do pcall(function() c:Fire() end) end
                return true
            end
        end
    end
    if firesignal then
        pcall(firesignal, b.MouseButton1Click)
        pcall(firesignal, b.Activated)
        return true
    end
    return false
end

local function realClick(o, dy) -- настоящий клик мыши по центру элемента
    local p, s = o.AbsolutePosition, o.AbsoluteSize
    local x, y = p.X + s.X / 2, p.Y + s.Y / 2 + dy
    pcall(function()
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait(0.05)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.06)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

-- нажимает элемент и проверяет, что он пропал или изменился
local function activate(o)
    local text = plain(o)
    local function changed() return not o.Parent or not shown(o) or plain(o) ~= text end
    local sg = o:FindFirstAncestorOfClass("ScreenGui")
    local inset = (sg and not sg.IgnoreGuiInset) and GuiService:GetGuiInset().Y or 0
    for _, dy in ipairs(inset == 0 and { 0 } or { inset, 0 }) do
        realClick(o, dy)
        task.wait(0.8)
        if changed() then return true end
    end
    local b = o:IsA("GuiButton") and o or o:FindFirstAncestorWhichIsA("GuiButton")
    if b and clickBtn(b) then
        task.wait(0.8)
        return changed()
    end
    return false
end

-- многошаговый диалог: жмёт подходящие кнопки, пока они появляются
local function choose(include, exclude, timeout)
    local t0, clicked, miss = os.clock(), false, 0
    while os.clock() - t0 < timeout do
        local o = findOption(include, exclude)
        if o then
            miss = 0
            if activate(o) then clicked = true end
            task.wait(0.4)
        else
            miss += 1
            if clicked and miss >= 4 then break end
            task.wait(0.3)
        end
    end
    return clicked
end

-- ===== Катсцена диалога и разблокировка =====
local snap = {}
local function sceneActive() return workspace.CurrentCamera.CameraType == Enum.CameraType.Scriptable end

local function takeSnap() -- запомнить, какие окна были включены в нормальном состоянии
    local g = pgui()
    if not g or sceneActive() then return end
    snap = {}
    for _, d in ipairs(g:GetChildren()) do
        if d:IsA("ScreenGui") then snap[d] = d.Enabled end
    end
end
takeSnap()

local function unstick()
    for g, en in pairs(snap) do
        if g.Parent then pcall(function() g.Enabled = en end) end
    end
    local cam = workspace.CurrentCamera
    pcall(function()
        cam.CameraType = Enum.CameraType.Custom
        local h = hum()
        if h then cam.CameraSubject = h end
    end)
    local r = root()
    if r then pcall(function() r.Anchored = false end) end
    for _ = 1, 3 do
        local o = findOption({ "goodbye", "bye", "leave", "close", "nevermind", "exit" })
        if not o then break end
        activate(o)
    end
    pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, true) end)
    Lib:Notify("Экран разблокирован. Если не помогло, перезайди на сервер", 5)
end

local CLOSERS = { "continue", "next", "thank", "bye", "goodbye", "close", "leave", "okay" }
-- ждёт конца катсцены, по пути закрывая «продолжить/пока»
local function waitScene(t)
    local t0 = os.clock()
    while sceneActive() and os.clock() - t0 < t do
        local o = findOption(CLOSERS, { "trick" })
        if o then activate(o) end
        task.wait(0.4)
    end
    return not sceneActive()
end

-- ===== Инвентарь и корабль =====
local function equip(part)
    for _, cont in ipairs({ LP.Character, LP:FindFirstChildOfClass("Backpack") }) do
        if cont then
            for _, t in ipairs(cont:GetChildren()) do
                if t:IsA("Tool") and low(t.Name):find(part, 1, true) then
                    local h = hum()
                    if h and t.Parent ~= LP.Character then h:EquipTool(t) task.wait(0.3) end
                    return t
                end
            end
        end
    end
end

-- на ивентовый остров только через капитана: Candy Bucket выдаётся при прибытии
local function sail()
    if onEvent() then return true end
    Lib:Notify("Плыву на остров...")
    for _, base in ipairs({ MOOSE, V(700, 135, 250) }) do
        near(base)
        local p = TP.findPos("Dutchman Captain")
        if p then
            near(p)
            local pr = promptNear(p, 25)
            if pr then
                press(pr)
                choose({ "set sail" }, nil, 8)
                for _ = 1, 40 do
                    if onEvent() then task.wait(1.5) takeSnap() return true end
                    task.wait(0.5)
                end
            end
        end
    end
    Lib:Notify("Не удалось сесть на корабль")
    return false
end

-- ===== Диагностика (результат уходит в буфер обмена и в консоль) =====
local function out(lines, title)
    local s = table.concat(lines, "\n")
    print("[FishUI] " .. title .. "\n" .. s)
    pcall(function() setclipboard(s) end)
    Lib:Notify(title .. ": строк " .. #lines .. " (скопировано)", 4)
end

local function dump(title)
    local lines = { "camera=" .. tostring(workspace.CurrentCamera.CameraType) }
    local g = pgui()
    if g then
        for _, d in ipairs(g:GetChildren()) do
            if d:IsA("ScreenGui") then lines[#lines + 1] = "gui " .. d.Name .. " enabled=" .. tostring(d.Enabled) end
        end
    end
    for i, d in ipairs(uiTexts()) do
        if i > 150 then break end
        local kind = d:IsA("GuiButton") and "button" or (d:FindFirstAncestorWhichIsA("GuiButton") and "in-button" or "label")
        lines[#lines + 1] = string.format("%s | %q | %s", kind, plain(d), d:GetFullName())
    end
    out(lines, title)
end

local function scanPrompts()
    local r = root()
    if not r then return end
    local lines = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local pp = promptPos(d)
            if pp and (pp - r.Position).Magnitude < 40 then
                lines[#lines + 1] = string.format("action=%q object=%q hold=%s enabled=%s path=%s",
                    d.ActionText, d.ObjectText, tostring(d.HoldDuration), tostring(d.Enabled), d:GetFullName())
            end
        end
    end
    out(lines, "Промпты рядом")
end

-- ===== Рабочие циклы =====
local function loop(key, fn)
    task.spawn(function()
        while alive() do
            if F[key] then
                local ok, err = pcall(fn)
                if not ok then
                    warn("[FishUI] " .. key .. ": " .. tostring(err))
                    task.wait(2)
                end
            end
            task.wait(0.5)
        end
    end)
end

getgenv().FishEV = {
    F = F, alive = alive, low = low, CENTER = CENTER, near = near, onEvent = onEvent,
    promptPos = promptPos, press = press, promptNear = promptNear, findOption = findOption,
    activate = activate, choose = choose, sceneActive = sceneActive, waitScene = waitScene,
    takeSnap = takeSnap, unstick = unstick, equip = equip, sail = sail,
    dump = dump, scanPrompts = scanPrompts, loop = loop,
}
print("[FishUI] часть 8 загружена")
--[[ Fish Test UI | ЧАСТЬ 9/9: вкладка «Ивент» (FischFright 3)
     Стук по домам, квесты NPC, продажа рыбы, сундуки, гоблины. Всё через клики по интерфейсу игры. ]]

local C, Lib, TP, EV = getgenv().FishCore, getgenv().FishUI, getgenv().FishTP, getgenv().FishEV
assert(C and Lib and TP and EV, "Сначала запусти части 1-8")

local Players = game:GetService("Players")
local V, root = TP.V, TP.root
local F, low, near, press, promptNear = EV.F, EV.low, EV.near, EV.press, EV.promptNear
local CENTER = EV.CENTER

local cooldown = 500 -- секунд между стуками в один дом (по гайдам 8-10 минут)

-- ===== Trick-or-Treat: 16 домов (номер, X, Y, Z) =====
local HOUSES = {
    { 293, -14809, 151, -9802 }, { 506, -14754, 148, -9794 }, { 167, -14891, 146, -9754 },
    { 374, -14861, 146, -9713 }, { 111, -14821, 147, -9660 }, { 632, -14809, 155, -9714 },
    { 745, -14702, 149, -9766 }, { 429, -14725, 147, -9719 }, { 891, -14630, 146, -9756 },
    { 477, -14532, 144, -9746 }, { 666, -14627, 146, -9593 }, { 979, -14699, 157, -9454 },
    { 813, -14992, 182, -9571 }, { 249, -14716, 147, -9976 }, { 358, -14717, 147, -10055 },
    { 467, -14823, 146, -10100 },
}
local last = {}

local function isDoor(p)
    local t = low(p.ActionText) .. " " .. low(p.ObjectText)
    return t:find("trick") or t:find("treat") or t:find("knock")
end

-- один стук. true = всё прошло чисто, false = диалог завис (скрипт остановится)
local function knock(h)
    local pos = V(h[2], h[3], h[4])
    EV.takeSnap()
    near(pos)
    local pr = promptNear(pos, 30, isDoor)
    if not pr then
        last[h[1]] = os.clock() - cooldown + 60 -- нет промпта (кулдаун?), вернёмся через минуту
        return true
    end
    press(pr)
    local opt
    for i = 1, 36 do -- ждём до ~9 секунд, пока откроется диалог
        opt = EV.findOption({ "treat!" }, { "trick" })
        if not opt and i > 16 then opt = EV.findOption({ "treat" }, { "trick", "treats" }) end
        if opt then break end
        task.wait(0.25)
    end
    if not opt then
        EV.dump("Нет кнопки Treat, дом " .. h[1])
        EV.unstick()
        return false
    end
    if not EV.activate(opt) then
        EV.dump("Клик не сработал, дом " .. h[1])
        EV.unstick()
        return false
    end
    if not EV.waitScene(10) then
        EV.dump("Сцена зависла, дом " .. h[1])
        EV.unstick()
        return false
    end
    last[h[1]] = os.clock()
    return true
end

local function treatPass()
    if not EV.sail() then F.treat = false Lib:Notify("Авто-конфеты остановлены") return end
    local todo = {}
    for _, h in ipairs(HOUSES) do
        if not last[h[1]] or os.clock() - last[h[1]] >= cooldown then todo[#todo + 1] = h end
    end
    if #todo == 0 then task.wait(3) return end
    local r = root()
    local cur = r and r.Position or CENTER
    while #todo > 0 and F.treat and EV.alive() do
        if EV.sceneActive() and not EV.waitScene(6) then
            EV.unstick()
            F.treat = false
            return
        end
        table.sort(todo, function(a, b)
            return (V(a[2], a[3], a[4]) - cur).Magnitude < (V(b[2], b[3], b[4]) - cur).Magnitude
        end)
        local h = table.remove(todo, 1)
        if not EV.equip("candy bucket") then
            F.treat = false
            Lib:Notify("Нет Candy Bucket: сядь на корабль заново")
            return
        end
        if not knock(h) then
            F.treat = false
            Lib:Notify("Остановлено: диалог завис. Данные в буфере, пришли их мне", 6)
            return
        end
        cur = V(h[2], h[3], h[4])
        task.wait(0.7)
    end
end

-- ===== Квесты NPC ивента =====
local ACCEPT = { "accept", "yes", "sure", "continue", "next", "claim", "turn in", "complete", "i'll help", "let's", "okay" }
local AVOID = { "no thanks", "not now", "bye", "leave", "buy", "sell", "decline", "later" }

local NPCS = {
    { "Pumpkin King" }, { "Beatrix" }, { "Dentist Dreadmore" }, { "Youngster Goblin" },
    { "Pumpkin Pete", V(-14727, 148, -10009) },
    { "Webby Winston", V(-15069, 142, -9981) },
    { "Gatekeeper Scarecrow", V(-14966, 181, -9430) },
    { "Scarecrow 1", V(-14951, 181, -9404) }, { "Scarecrow 2", V(-14929, 181, -9346) },
    { "Scarecrow 3", V(-15047, 181, -9427) }, { "Scarecrow 4", V(-15021, 181, -9442) },
    { "Scarecrow 5", V(-15066, 181, -9403) }, { "Scarecrow 6", V(-15050, 182, -9552) },
    { "Dullahan", V(-15028.6, 267.7, -9919.3) },
    { "Butler Bartholomew", V(-15031.2, 267.7, -9954.9) },
    { "Chef Ghoulash", V(-15050, 267.8, -9982.2) },
    { "Maid Marrow", V(-15104, 267.7, -9931.2) },
    { "Lady Lenore", V(-15066.5, 267.7, -9907.5) },
    { "Portrait of Percival", V(-15075.2, 291.5, -9931.6) },
    { "Nanny Nocturne", V(-15037.6, 291.5, -9927.5) },
    { "Doomsekkar", V(-14993, 147, -9666) },
    { "Frankenstein", V(-15104, 146, -9621) },
    { "Rave", V(-14591, 198, -9936) },
    { "Fisch-Slinging Caster", V(-15189, 167, -9577) },
}

-- true = можно идти дальше, false = диалог завис
local function talk(e)
    local pos = e[2]
    if not pos then
        near(CENTER)
        task.wait(0.8)
        pos = TP.findPos(e[1])
        if not pos then return true end
    end
    near(pos)
    local pr = promptNear(pos, 20, function(p) return not isDoor(p) end) -- не стучим в соседний дом
    if not pr then return true end
    EV.takeSnap()
    press(pr)
    EV.choose(ACCEPT, AVOID, 7)
    if not EV.waitScene(8) then
        EV.dump("Сцена зависла, NPC " .. e[1])
        EV.unstick()
        return false
    end
    return true
end

local function questPass()
    if not EV.sail() then return end
    for _, e in ipairs(NPCS) do
        if not (F.quest and EV.alive()) then return end
        if not talk(e) then
            F.quest = false
            Lib:Notify("Квесты остановлены: диалог завис. Данные в буфере", 6)
            return
        end
        task.wait(0.5)
    end
    for _ = 1, 180 do -- пауза до следующего круга
        if not (F.quest and EV.alive()) then return end
        task.wait(1)
    end
end

-- ===== Продажа ивентовых рыб =====
local function sellFish()
    if not EV.sail() then return end
    near(CENTER)
    task.wait(0.8)
    local pr
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local m = d:FindFirstAncestorOfClass("Model")
            local n = m and low(m.Name) or ""
            if n:find("merchant") and not n:find("dutchman") then pr = d break end
        end
    end
    local pos = pr and EV.promptPos(pr)
    if not pos then Lib:Notify("Frightful Merchant не найден") return end
    near(pos)
    EV.takeSnap()
    press(pr)
    EV.choose({ "sell my haunted", "fischfright inventory" }, nil, 6)
    EV.choose({ "yes", "confirm" }, { "no thanks" }, 3)
    if not EV.waitScene(8) then EV.unstick() end
    Lib:Notify("Продажа выполнена (если диалог совпал)")
end

-- ===== Гоблины на островах =====
local function isIslandGoblin(d)
    return d:IsA("Model") and low(d.Name):find("goblin") and not low(d.Name):find("youngster")
        and not Players:GetPlayerFromCharacter(d)
end

local function esp(m)
    if m:FindFirstChild("FishESP") then return end
    local h = Instance.new("Highlight")
    h.Name = "FishESP"
    h.FillColor = C.Theme.Accent
    h.OutlineColor = Color3.new(1, 1, 1)
    h.FillTransparency = 0.6
    h.Parent = m
end

local function espAll(on)
    for _, d in ipairs(workspace:GetDescendants()) do
        if isIslandGoblin(d) then
            if on then esp(d) else
                local h = d:FindFirstChild("FishESP")
                if h then h:Destroy() end
            end
        end
    end
end

local seen = {}
if getgenv().FishEvConn then pcall(function() getgenv().FishEvConn:Disconnect() end) end
getgenv().FishEvConn = workspace.DescendantAdded:Connect(function(d)
    if not EV.alive() or not isIslandGoblin(d) or seen[d] then return end
    seen[d] = true
    if F.esp then esp(d) end
    if F.gob then
        task.delay(1.5, function()
            local ok, cf = pcall(function() return d:GetPivot() end)
            if not (ok and (cf.Position - CENTER).Magnitude > 2500) then return end
            near(cf.Position)
            local pr = promptNear(cf.Position, 25)
            if pr then
                EV.takeSnap()
                press(pr)
                EV.choose(ACCEPT, AVOID, 6)
                if not EV.waitScene(8) then EV.unstick() end
            end
        end)
    end
end)

-- ===== Циклы =====
EV.loop("treat", treatPass)
EV.loop("quest", questPass)
EV.loop("casket", function()
    local t = EV.equip("casket")
    if t then
        pcall(function() t:Activate() end)
        task.wait(1.5)
    else
        task.wait(2)
    end
end)

-- ===== Вкладка =====
local Tab = Lib:CreateTab("Ивент (бета)")
Tab:Label("FischFright 3: автоматика (best-effort)")
Tab:Button("Плыть на остров (Dutchman Captain)", function() EV.sail() end)
Tab:Button("Разблокировать экран (если завис)", function() EV.unstick() end)

Tab:Label("Конфеты (Treats)")
Tab:Button("Тест: один дом (ближайший)", function()
    if not EV.sail() then return end
    if not EV.equip("candy bucket") then Lib:Notify("Нет Candy Bucket") return end
    local r = root()
    local best, bd
    for _, h in ipairs(HOUSES) do
        local d = (V(h[2], h[3], h[4]) - r.Position).Magnitude
        if not bd or d < bd then best, bd = h, d end
    end
    last[best[1]] = nil
    if knock(best) then Lib:Notify("Дом " .. best[1] .. ": стук выполнен") end
end)
Tab:Toggle("Авто Trick-or-Treat (16 домов)", false, function(v) F.treat = v end)
Tab:Slider("Перерыв на дом (сек)", 300, 720, cooldown, function(v) cooldown = v end)
Tab:Button("Продать ивентовых рыб (Merchant)", function() sellFish() end)
Tab:Toggle("Авто-открытие Frightful Caskets", false, function(v) F.casket = v end)

Tab:Label("Квесты")
Tab:Toggle("Авто-квесты у NPC ивента (цикл)", false, function(v) F.quest = v end)

Tab:Label("Гоблины на островах")
Tab:Toggle("Авто-ТП и диалог с новым гоблином", false, function(v) F.gob = v end)
Tab:Toggle("Подсветка гоблинов", false, function(v)
    F.esp = v
    espAll(v)
end)

Tab:Label("Диагностика (результат копируется в буфер)")
Tab:Button("Сканер: весь текст на экране", function() EV.dump("Текст на экране") end)
Tab:Button("Сканер: промпты рядом", function() EV.scanPrompts() end)

print("[FishUI] часть 9 загружена")
