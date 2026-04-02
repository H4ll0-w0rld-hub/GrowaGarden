--[[
    ╔══════════════════════════════════════════╗
    ║       H4LL0 W0RLD HUB | GAG            ║
    ║         Grow a Garden  •  v1.0          ║
    ║            KEY: GaG_key                 ║
    ╚══════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Debris           = game:GetService("Debris")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ═══════════════════════
--   ENIGMA HORROR THEME
-- ═══════════════════════
local C = {
    BG        = Color3.fromRGB(14, 14, 16),
    BG2       = Color3.fromRGB(18, 18, 22),
    BG3       = Color3.fromRGB(22, 22, 28),
    Card      = Color3.fromRGB(26, 26, 32),
    Accent    = Color3.fromRGB(180, 20, 20),
    AccentDim = Color3.fromRGB(100, 10, 10),
    AccentGlow= Color3.fromRGB(220, 40, 40),
    ON        = Color3.fromRGB(180, 20, 20),
    OFF       = Color3.fromRGB(40, 40, 50),
    Text      = Color3.fromRGB(230, 225, 235),
    TextSub   = Color3.fromRGB(140, 130, 155),
    TextDim   = Color3.fromRGB(80, 75, 95),
    Border    = Color3.fromRGB(45, 42, 55),
    BorderAcc = Color3.fromRGB(90, 20, 20),
    Green     = Color3.fromRGB(50, 200, 120),
    Gold      = Color3.fromRGB(255, 200, 50),
    Purple    = Color3.fromRGB(168, 85, 247),
    Blue      = Color3.fromRGB(50, 150, 255),
    Cyan      = Color3.fromRGB(50, 200, 220),
}

local Toggles = {
    AutoFarm   = false,
    GodMode    = false,
    AutoBuy    = false,
    ESP        = false,
    Fly        = false,
    NoClip     = false,
    InfMoney   = false,
    AntiAFK    = false,
    BoostFPS   = false,
    StealFree  = false,
    AutoPet    = false,
    AutoSeed   = false,
}

local Settings = {
    FlySpeed   = 40,
    FarmDelay  = 1,
    BuyItem    = "Seed", -- item yang di-auto buy
    TPTarget   = nil,
}

local Connections = {}
local Minimized   = false
local VALID_KEY   = "GaG_key"

-- ═══════════════════
--   HELPERS
-- ═══════════════════
local function New(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do pcall(function() obj[k]=v end) end
    if parent then obj.Parent=parent end
    return obj
end
local function Corner(p,r) return New("UICorner",{CornerRadius=UDim.new(0,r or 6)},p) end
local function Stroke(p,col,th) return New("UIStroke",{Color=col or C.Border,Thickness=th or 1},p) end
local function Tween(obj,props,t)
    pcall(function() TweenService:Create(obj,TweenInfo.new(t or 0.2,Enum.EasingStyle.Quart),props):Play() end)
end
local function GetChar()
    local char=LocalPlayer.Character
    if not char then return nil,nil,nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end
local function StopAll()
    for k,c in pairs(Connections) do pcall(function() c:Disconnect() end); Connections[k]=nil end
end
local function ClearESP()
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            local root=plr.Character:FindFirstChild("HumanoidRootPart")
            if root then local bb=root:FindFirstChild("GAG_ESP"); if bb then pcall(function() bb:Destroy() end) end end
            local hl=plr.Character:FindFirstChild("GAG_HL"); if hl then pcall(function() hl:Destroy() end) end
        end
    end
end

-- ═══════════════════════════
--   FEATURE FUNCTIONS
-- ═══════════════════════════

-- Find remote by name pattern
local function FindRemote(pattern)
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if (v:IsA("RemoteEvent") or v:IsA("RemoteFunction")) and v.Name:lower():find(pattern:lower()) then
            return v
        end
    end
    return nil
end

-- Find all coins/items in workspace
local function FindCoins()
    local coins = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("money") or name:find("cash") or
               name:find("gold") or name:find("reward") or name:find("collect") or
               name:find("pickup") or name:find("drop") then
                table.insert(coins, obj)
            end
        end
    end
    return coins
end

-- Find all pets in workspace
local function FindPets()
    local pets = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("pet") or name:find("animal") or name:find("egg") then
                table.insert(pets, obj)
            end
        end
    end
    return pets
end

-- Find seeds in workspace
local function FindSeeds()
    local seeds = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            if name:find("seed") or name:find("plant") or name:find("crop") or
               name:find("fruit") or name:find("veggie") or name:find("flower") then
                table.insert(seeds, obj)
            end
        end
    end
    return seeds
end

-- Find shop/buy proximity prompts
local function FindBuyPrompts()
    local prompts = {}
    for _,obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local name = obj.ActionText:lower()
            if name:find("buy") or name:find("purchase") or name:find("shop") or
               name:find("get") or name:find("beli") then
                table.insert(prompts, obj)
            end
        end
    end
    return prompts
end

local function ApplyFeature(key, val)
    local char,hrp,hum = GetChar()

    -- ── AUTO FARM ──
    if key=="AutoFarm" then
        if val then
            Connections.AutoFarm = RunService.Heartbeat:Connect(function()
                local _,hrp2,_ = GetChar()
                if not hrp2 then return end
                pcall(function()
                    -- Collect coins/items
                    local coins = FindCoins()
                    for _,coin in ipairs(coins) do
                        local pos = coin:IsA("Model") and
                            (coin.PrimaryPart and coin.PrimaryPart.Position or coin:GetPivot().Position)
                            or coin.Position
                        local dist = (pos - hrp2.Position).Magnitude
                        if dist < 60 then
                            hrp2.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
                        end
                    end
                    -- Fire collect remotes
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("collect") or
                            v.Name:lower():find("farm") or
                            v.Name:lower():find("harvest") or
                            v.Name:lower():find("pick")
                        ) then
                            pcall(function() v:FireServer() end)
                        end
                    end
                    -- Fire proximity prompts
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local act = obj.ActionText:lower()
                            if act:find("collect") or act:find("harvest") or act:find("pick") then
                                pcall(function() fireproximityprompt(obj) end)
                            end
                        end
                    end
                end)
            end)
        else
            if Connections.AutoFarm then pcall(function() Connections.AutoFarm:Disconnect() end); Connections.AutoFarm=nil end
        end

    -- ── GOD MODE ──
    elseif key=="GodMode" then
        if val then
            Connections.GodMode=RunService.Heartbeat:Connect(function()
                local _,_,h=GetChar(); if h and h.Health<h.MaxHealth then h.Health=h.MaxHealth end
            end)
        else
            if Connections.GodMode then pcall(function() Connections.GodMode:Disconnect() end); Connections.GodMode=nil end
        end

    -- ── AUTO BUY ──
    elseif key=="AutoBuy" then
        if val then
            Connections.AutoBuy = RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Fire buy remotes
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("buy") or
                            v.Name:lower():find("purchase") or
                            v.Name:lower():find("shop")
                        ) then
                            v:FireServer(Settings.BuyItem)
                        end
                    end
                    -- Fire buy prompts
                    local prompts = FindBuyPrompts()
                    for _,p in ipairs(prompts) do
                        pcall(function() fireproximityprompt(p) end)
                    end
                end)
            end)
        else
            if Connections.AutoBuy then pcall(function() Connections.AutoBuy:Disconnect() end); Connections.AutoBuy=nil end
        end

    -- ── ESP ──
    elseif key=="ESP" then
        if val then
            Connections.ESP=RunService.Heartbeat:Connect(function()
                local _,hrp2,_=GetChar()
                for _,plr in ipairs(Players:GetPlayers()) do
                    if plr~=LocalPlayer and plr.Character then
                        local root=plr.Character:FindFirstChild("HumanoidRootPart")
                        if root and not root:FindFirstChild("GAG_ESP") then
                            pcall(function()
                                local dist=hrp2 and math.floor((root.Position-hrp2.Position).Magnitude) or 0
                                local bb=New("BillboardGui",{Name="GAG_ESP",Size=UDim2.new(0,120,0,32),StudsOffset=Vector3.new(0,4,0),AlwaysOnTop=true},root)
                                New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🌱 "..plr.Name.."\n📏 "..dist.."m",TextColor3=C.Green,TextSize=11,Font=Enum.Font.GothamBold,TextWrapped=true},bb)
                                local hl=Instance.new("Highlight"); hl.Name="GAG_HL"
                                hl.FillColor=Color3.fromRGB(50,200,120)
                                hl.OutlineColor=Color3.fromRGB(100,255,150)
                                hl.FillTransparency=0.5
                                hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                                hl.Adornee=plr.Character; hl.Parent=plr.Character
                            end)
                        end
                    end
                end
            end)
        else
            if Connections.ESP then pcall(function() Connections.ESP:Disconnect() end); Connections.ESP=nil end
            ClearESP()
        end

    -- ── FLY ──
    elseif key=="Fly" then
        if val then
            pcall(function()
                if not hrp then return end
                local bg=Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.P=1e4; bg.Parent=hrp
                local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.zero; bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hrp
                Connections.Fly=RunService.Heartbeat:Connect(function()
                    local cam=workspace.CurrentCamera
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then bv.Velocity=cam.CFrame.LookVector*Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then bv.Velocity=-cam.CFrame.LookVector*Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then bv.Velocity=-cam.CFrame.RightVector*Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.D) then bv.Velocity=cam.CFrame.RightVector*Settings.FlySpeed
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.Space) then bv.Velocity=Vector3.new(0,Settings.FlySpeed,0)
                    elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then bv.Velocity=Vector3.new(0,-Settings.FlySpeed,0)
                    else bv.Velocity=Vector3.zero end
                    bg.CFrame=cam.CFrame
                end)
            end)
        else
            if Connections.Fly then pcall(function() Connections.Fly:Disconnect() end); Connections.Fly=nil end
            if hrp then for _,obj in ipairs(hrp:GetChildren()) do if obj:IsA("BodyGyro") or obj:IsA("BodyVelocity") then pcall(function() obj:Destroy() end) end end end
        end

    -- ── NOCLIP ──
    elseif key=="NoClip" then
        if val then
            Connections.NoClip=RunService.Stepped:Connect(function()
                local c=LocalPlayer.Character
                if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=false end) end end end
            end)
        else
            if Connections.NoClip then pcall(function() Connections.NoClip:Disconnect() end); Connections.NoClip=nil end
        end

    -- ── INFINITE MONEY ──
    elseif key=="InfMoney" then
        if val then
            Connections.InfMoney=RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Find leaderstats money values
                    local ls=LocalPlayer:FindFirstChild("leaderstats")
                    if ls then
                        for _,v in ipairs(ls:GetChildren()) do
                            if v:IsA("IntValue") or v:IsA("NumberValue") then
                                if v.Name:lower():find("coin") or v.Name:lower():find("money") or
                                   v.Name:lower():find("cash") or v.Name:lower():find("gold") or
                                   v.Name:lower():find("gem") or v.Name:lower():find("credit") then
                                    if v.Value < 999999 then
                                        pcall(function() v.Value=999999 end)
                                    end
                                end
                            end
                        end
                    end
                    -- Fire money remote
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("money") or v.Name:lower():find("coin") or
                            v.Name:lower():find("cash") or v.Name:lower():find("earn")
                        ) then
                            pcall(function() v:FireServer(9999) end)
                        end
                    end
                end)
            end)
        else
            if Connections.InfMoney then pcall(function() Connections.InfMoney:Disconnect() end); Connections.InfMoney=nil end
        end

    -- ── STEAL FREE ──
    elseif key=="StealFree" then
        if val then
            Connections.StealFree=RunService.Heartbeat:Connect(function()
                pcall(function()
                    local _,hrp2,_=GetChar()
                    if not hrp2 then return end
                    -- Teleport ke item gratis/steal
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("BasePart") or obj:IsA("Model") then
                            local name=obj.Name:lower()
                            if name:find("free") or name:find("steal") or name:find("loot") or name:find("drop") then
                                local pos=obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                                local dist=(pos-hrp2.Position).Magnitude
                                if dist<100 then
                                    hrp2.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
                                end
                            end
                        end
                    end
                    -- Fire steal remotes
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("steal") or v.Name:lower():find("loot") or v.Name:lower():find("grab")
                        ) then
                            pcall(function() v:FireServer() end)
                        end
                    end
                end)
            end)
        else
            if Connections.StealFree then pcall(function() Connections.StealFree:Disconnect() end); Connections.StealFree=nil end
        end

    -- ── AUTO PET SPAWNER ──
    elseif key=="AutoPet" then
        if val then
            Connections.AutoPet=RunService.Heartbeat:Connect(function()
                pcall(function()
                    -- Fire pet spawn remotes
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("pet") or v.Name:lower():find("hatch") or v.Name:lower():find("egg")
                        ) then
                            v:FireServer()
                        end
                    end
                    -- Proximity prompt pets
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local act=obj.ActionText:lower()
                            if act:find("hatch") or act:find("pet") or act:find("egg") then
                                pcall(function() fireproximityprompt(obj) end)
                            end
                        end
                    end
                end)
            end)
        else
            if Connections.AutoPet then pcall(function() Connections.AutoPet:Disconnect() end); Connections.AutoPet=nil end
        end

    -- ── AUTO SEED SPAWNER ──
    elseif key=="AutoSeed" then
        if val then
            Connections.AutoSeed=RunService.Heartbeat:Connect(function()
                pcall(function()
                    local _,hrp2,_=GetChar()
                    if not hrp2 then return end
                    -- Collect seeds nearby
                    local seeds=FindSeeds()
                    for _,seed in ipairs(seeds) do
                        local pos=seed:IsA("Model") and seed:GetPivot().Position or seed.Position
                        local dist=(pos-hrp2.Position).Magnitude
                        if dist<50 then
                            hrp2.CFrame=CFrame.new(pos+Vector3.new(0,3,0))
                        end
                    end
                    -- Fire seed remotes
                    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
                        if v:IsA("RemoteEvent") and (
                            v.Name:lower():find("seed") or v.Name:lower():find("plant") or v.Name:lower():find("grow")
                        ) then
                            pcall(function() v:FireServer() end)
                        end
                    end
                    -- Proximity prompts
                    for _,obj in ipairs(workspace:GetDescendants()) do
                        if obj:IsA("ProximityPrompt") then
                            local act=obj.ActionText:lower()
                            if act:find("plant") or act:find("seed") or act:find("grow") then
                                pcall(function() fireproximityprompt(obj) end)
                            end
                        end
                    end
                end)
            end)
        else
            if Connections.AutoSeed then pcall(function() Connections.AutoSeed:Disconnect() end); Connections.AutoSeed=nil end
        end

    -- ── ANTI AFK ──
    elseif key=="AntiAFK" then
        if val then
            Connections.AntiAFK=RunService.Heartbeat:Connect(function()
                pcall(function() LocalPlayer:Move(Vector3.new(0,0,0)) end)
            end)
        else
            if Connections.AntiAFK then pcall(function() Connections.AntiAFK:Disconnect() end); Connections.AntiAFK=nil end
        end

    -- ── BOOST FPS ──
    elseif key=="BoostFPS" then
        if val then
            for _,obj in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        obj.Enabled=false
                    end
                end)
            end
        end
    end
end

-- ═══════════════════════════
--        KEY SCREEN
-- ═══════════════════════════
local GUI=New("ScreenGui",{Name="H4ll0GaG",ResetOnSpawn=false,DisplayOrder=999,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},game.CoreGui)

local KeyScreen=New("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.BG,BorderSizePixel=0},GUI)

-- Grid lines
for i=1,30 do
    New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/30,0,0,0),BackgroundColor3=C.Border,BackgroundTransparency=0.9,BorderSizePixel=0},KeyScreen)
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,i/30,0),BackgroundColor3=C.Border,BackgroundTransparency=0.9,BorderSizePixel=0},KeyScreen)
end

local KeyCard=New("Frame",{Size=UDim2.new(0,360,0,300),Position=UDim2.new(0.5,-180,0.5,-150),BackgroundColor3=C.BG2,BorderSizePixel=0},KeyScreen)
Corner(KeyCard,14); Stroke(KeyCard,C.Border,1)
New("Frame",{Size=UDim2.new(1,0,0,3),BackgroundColor3=C.Green,BorderSizePixel=0},KeyCard)

local iconLbl=New("TextLabel",{Size=UDim2.new(0,60,0,60),Position=UDim2.new(0.5,-30,0,14),BackgroundTransparency=1,Text="🌱",TextSize=44,Font=Enum.Font.GothamBold},KeyCard)
task.spawn(function()
    while iconLbl and iconLbl.Parent do
        task.wait(math.random(2,5))
        iconLbl.TextTransparency=0.7; task.wait(0.07)
        iconLbl.TextTransparency=0; task.wait(0.07)
        iconLbl.TextTransparency=0.5; task.wait(0.05)
        iconLbl.TextTransparency=0
    end
end)

New("TextLabel",{Size=UDim2.new(1,0,0,24),Position=UDim2.new(0,0,0,80),BackgroundTransparency=1,Text="H4LL0 W0RLD HUB | GAG",TextColor3=C.Text,TextSize=13,Font=Enum.Font.GothamBold},KeyCard)
New("TextLabel",{Size=UDim2.new(1,0,0,18),Position=UDim2.new(0,0,0,102),BackgroundTransparency=1,Text="Grow a Garden  •  Key Needed",TextColor3=C.TextDim,TextSize=11,Font=Enum.Font.Gotham},KeyCard)

local inputBG=New("Frame",{Size=UDim2.new(1,-40,0,38),Position=UDim2.new(0,20,0,132),BackgroundColor3=C.BG3,BorderSizePixel=0},KeyCard)
Corner(inputBG,8); Stroke(inputBG,C.Border,1)
local KInput=New("TextBox",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,PlaceholderText="Enter key...",PlaceholderColor3=C.TextDim,Text="",TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},inputBG)

local DiscBtn=New("TextButton",{Size=UDim2.new(0,100,0,32),Position=UDim2.new(0,20,0,182),BackgroundColor3=C.BG3,Text="💬 Discord",TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyCard); Corner(DiscBtn,7); Stroke(DiscBtn,C.Border,1)
local PasteBtn=New("TextButton",{Size=UDim2.new(0,80,0,32),Position=UDim2.new(0.5,-40,0,182),BackgroundColor3=C.BG3,Text="📋 Paste",TextColor3=C.TextSub,TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyCard); Corner(PasteBtn,7); Stroke(PasteBtn,C.Border,1)
local EnterBtn=New("TextButton",{Size=UDim2.new(0,80,0,32),Position=UDim2.new(1,-100,0,182),BackgroundColor3=C.Accent,Text="▶ Enter",TextColor3=Color3.fromRGB(255,200,200),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},KeyCard); Corner(EnterBtn,7)
local KStatus=New("TextLabel",{Size=UDim2.new(1,-40,0,20),Position=UDim2.new(0,20,0,224),BackgroundTransparency=1,Text="Enter key to access GaG Hub",TextColor3=C.TextDim,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.Gotham},KeyCard)

local hintBox=New("Frame",{Size=UDim2.new(1,-40,0,38),Position=UDim2.new(0,20,0,252),BackgroundColor3=C.AccentDim,BackgroundTransparency=0.7,BorderSizePixel=0},KeyCard)
Corner(hintBox,7); Stroke(hintBox,C.BorderAcc,1)
New("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="🔑 Join Discord → dapat key gratis!",TextColor3=C.Accent,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.GothamBold,TextWrapped=true},hintBox)

DiscBtn.MouseButton1Click:Connect(function()
    pcall(function() setclipboard("https://discord.gg/xCV9Tf4y5N") end)
    DiscBtn.Text="✓ Copied!"; DiscBtn.BackgroundColor3=C.Green
    task.wait(2); DiscBtn.Text="💬 Discord"; DiscBtn.BackgroundColor3=C.BG3
end)
PasteBtn.MouseButton1Click:Connect(function()
    local ok,cb=pcall(getclipboard); if ok and cb~="" then KInput.Text=cb end
end)

-- ═══════════════════════════
--        MAIN GUI
-- ═══════════════════════════
local function BuildMain()
    KeyScreen:Destroy()

    local Win=New("Frame",{Size=UDim2.new(0,560,0,440),Position=UDim2.new(0.5,-280,0.5,-220),BackgroundColor3=C.BG,BorderSizePixel=0,Active=true},GUI)
    Corner(Win,12); Stroke(Win,C.Border,1)
    New("Frame",{Size=UDim2.new(1,0,0,2),BackgroundColor3=C.Green,BorderSizePixel=0},Win)

    for i=1,20 do
        New("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(i/20,0,0,0),BackgroundColor3=C.Border,BackgroundTransparency=0.94,BorderSizePixel=0,ZIndex=0},Win)
    end

    -- Drag
    local drag,dStart,dPos=false,nil,nil
    Win.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; dStart=i.Position; dPos=Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dStart
            Win.Position=UDim2.new(dPos.X.Scale,dPos.X.Offset+d.X,dPos.Y.Scale,dPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)

    -- TopBar
    local Top=New("Frame",{Size=UDim2.new(1,0,0,44),BackgroundColor3=C.BG2,BorderSizePixel=0,ZIndex=5},Win)
    New("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BackgroundColor3=C.Border,BorderSizePixel=0,ZIndex=6},Top)
    New("TextLabel",{Size=UDim2.new(0,22,1,0),Position=UDim2.new(0,12,0,0),BackgroundTransparency=1,Text="🌱",TextSize=18,ZIndex=6},Top)
    New("TextLabel",{Size=UDim2.new(0,220,1,0),Position=UDim2.new(0,38,0,0),BackgroundTransparency=1,Text="H4ll0 W0rld Hub | GaG",TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=6},Top)

    local gagBadge=New("Frame",{Size=UDim2.new(0,60,0,20),Position=UDim2.new(0,262,0.5,-10),BackgroundColor3=Color3.fromRGB(8,20,10),BorderSizePixel=0,ZIndex=6},Top)
    Corner(gagBadge,5); Stroke(gagBadge,C.Green,1)
    New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="🌱 GaG",TextColor3=C.Green,TextSize=9,Font=Enum.Font.GothamBold,ZIndex=7},gagBadge)

    local MinBtn=New("TextButton",{Size=UDim2.new(0,26,0,22),Position=UDim2.new(1,-60,0.5,-11),BackgroundColor3=C.BG3,Text="─",TextColor3=C.TextSub,TextSize=13,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top); Corner(MinBtn,5)
    local CloseBtn=New("TextButton",{Size=UDim2.new(0,26,0,22),Position=UDim2.new(1,-28,0.5,-11),BackgroundColor3=C.Accent,Text="✕",TextColor3=Color3.fromRGB(255,200,200),TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0,ZIndex=6},Top); Corner(CloseBtn,5)
    CloseBtn.MouseButton1Click:Connect(function() StopAll(); ClearESP(); Tween(Win,{Size=UDim2.new(0,560,0,0)},0.3); task.wait(0.35); GUI:Destroy() end)
    MinBtn.MouseButton1Click:Connect(function()
        Minimized=not Minimized
        if Minimized then Tween(Win,{Size=UDim2.new(0,560,0,44)},0.3); MinBtn.Text="□"
        else Tween(Win,{Size=UDim2.new(0,560,0,440)},0.3); MinBtn.Text="─" end
    end)

    -- ENIGMA TABS
    local TabBar=New("Frame",{Size=UDim2.new(1,-24,0,34),Position=UDim2.new(0,12,0,52),BackgroundColor3=C.BG3,BorderSizePixel=0,ZIndex=5},Win)
    Corner(TabBar,8); Stroke(TabBar,C.Border,1)
    New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,3)},TabBar)
    New("UIPadding",{PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3)},TabBar)

    local CA=New("Frame",{Size=UDim2.new(1,-24,1,-104),Position=UDim2.new(0,12,0,94),BackgroundTransparency=1,ClipsDescendants=true},Win)

    local Pages,TabBtns={},{}
    local function MakePage(name)
        local pg=New("ScrollingFrame",{Name=name,Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Green,CanvasSize=UDim2.new(0,0,0,0),Visible=false},CA)
        local ll=New("UIListLayout",{Padding=UDim.new(0,8)},pg)
        New("UIPadding",{PaddingTop=UDim.new(0,4)},pg)
        ll:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pg.CanvasSize=UDim2.new(0,0,0,ll.AbsoluteContentSize.Y+16) end)
        Pages[name]=pg; return pg
    end
    local function SetTab(name)
        for n,pg in pairs(Pages) do pg.Visible=(n==name) end
        for n,btn in pairs(TabBtns) do
            if n==name then Tween(btn,{BackgroundColor3=C.Green,TextColor3=Color3.fromRGB(200,255,220)},0.15)
            else Tween(btn,{BackgroundColor3=Color3.fromRGB(0,0,0),TextColor3=C.TextSub},0.15); btn.BackgroundTransparency=1 end
        end
    end
    for _,t in ipairs({{"Farm","🌱"},{"Items","🛒"},{"Player","🏃"},{"Visual","👁"},{"Settings","⚙"}}) do
        MakePage(t[1])
        local btn=New("TextButton",{Size=UDim2.new(0.2,-3,1,0),BackgroundTransparency=1,BackgroundColor3=Color3.fromRGB(0,0,0),Text=t[2].." "..t[1],TextColor3=C.TextSub,TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0},TabBar)
        Corner(btn,6); TabBtns[t[1]]=btn
        btn.MouseButton1Click:Connect(function() SetTab(t[1]) end)
    end

    -- HELPER WIDGETS
    local function Label(parent,txt,col)
        local f=New("Frame",{Size=UDim2.new(1,0,0,18),BackgroundTransparency=1},parent)
        New("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=txt,TextColor3=col or C.TextDim,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.GothamBold},f)
    end
    local function Toggle(parent,label,key,desc,col)
        local card=New("Frame",{Size=UDim2.new(1,0,0,desc and 54 or 42),BackgroundColor3=C.Card,BorderSizePixel=0},parent)
        Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text=label,TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        if desc then New("TextLabel",{Size=UDim2.new(1,-70,0,16),Position=UDim2.new(0,12,0,26),BackgroundTransparency=1,Text=desc,TextColor3=C.TextDim,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,Font=Enum.Font.Gotham},card) end
        local onCol=col or C.ON
        local pill=New("TextButton",{Size=UDim2.new(0,44,0,22),Position=UDim2.new(1,-56,0.5,-11),BackgroundColor3=C.OFF,Text="",BorderSizePixel=0},card); Corner(pill,11)
        local dot=New("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,0.5,-8),BackgroundColor3=Color3.fromRGB(200,200,210),BorderSizePixel=0},pill); Corner(dot,8)
        pill.MouseButton1Click:Connect(function()
            Toggles[key]=not Toggles[key]; local on=Toggles[key]
            Tween(pill,{BackgroundColor3=on and onCol or C.OFF},0.2)
            Tween(dot,{Position=on and UDim2.new(0,25,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.2)
            if on then dot.BackgroundColor3=Color3.fromRGB(255,255,255) else dot.BackgroundColor3=Color3.fromRGB(200,200,210) end
            pcall(function() ApplyFeature(key,on) end)
        end)
    end
    local function Btn(parent,label,col,fn)
        local b=New("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=col or C.Card,Text=label,TextColor3=col and Color3.fromRGB(200,255,220) or C.Text,TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},parent)
        Corner(b,8); if not col then Stroke(b,C.Border,1) end
        b.MouseButton1Click:Connect(function() pcall(fn); b.BackgroundColor3=C.Green; task.wait(0.4); b.BackgroundColor3=col or C.Card end)
        return b
    end
    local function InputSlider(parent,label,min,max,def,fn,suffix)
        local card=New("Frame",{Size=UDim2.new(1,0,0,66),BackgroundColor3=C.Card,BorderSizePixel=0},parent); Corner(card,8); Stroke(card,C.Border,1)
        New("TextLabel",{Size=UDim2.new(0.6,0,0,20),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text=label,TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},card)
        local valBG=New("Frame",{Size=UDim2.new(0,80,0,24),Position=UDim2.new(1,-92,0,6),BackgroundColor3=C.BG3,BorderSizePixel=0},card); Corner(valBG,6); Stroke(valBG,C.Border,1)
        local valBox=New("TextBox",{Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),BackgroundTransparency=1,Text=tostring(def)..(suffix or ""),TextColor3=C.Green,TextXAlignment=Enum.TextXAlignment.Center,TextSize=11,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},valBG)
        local track=New("Frame",{Size=UDim2.new(1,-24,0,6),Position=UDim2.new(0,12,0,40),BackgroundColor3=C.BG3,BorderSizePixel=0},card); Corner(track,3)
        local pct=(def-min)/(max-min)
        local fill=New("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=C.Green,BorderSizePixel=0},track); Corner(fill,3)
        local thumb=New("Frame",{Size=UDim2.new(0,14,0,14),Position=UDim2.new(pct,-7,0.5,-7),BackgroundColor3=Color3.fromRGB(200,255,220),BorderSizePixel=0},track); Corner(thumb,7)
        local sliding=false
        track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=true end end)
        UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then sliding=false end end)
        UserInputService.InputChanged:Connect(function(i)
            if sliding and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local rel=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                local v=math.floor(min+(max-min)*rel)
                valBox.Text=tostring(v)..(suffix or ""); fill.Size=UDim2.new(rel,0,1,0); thumb.Position=UDim2.new(rel,-7,0.5,-7)
                pcall(fn,v)
            end
        end)
        valBox.FocusLost:Connect(function()
            local v=tonumber(valBox.Text:match("%d+"))
            if v then
                v=math.clamp(v,min,max); local r=(v-min)/(max-min)
                fill.Size=UDim2.new(r,0,1,0); thumb.Position=UDim2.new(r,-7,0.5,-7)
                valBox.Text=tostring(v)..(suffix or ""); pcall(fn,v)
            end
        end)
    end

    -- ══════════════════
    --   🌱 FARM TAB
    -- ══════════════════
    local FP=Pages["Farm"]
    Label(FP,"  AUTO FARM",C.Green)
    Toggle(FP,"🌱 Auto Farm Coins","AutoFarm","Auto collect coins & harvest di sekitar")
    InputSlider(FP,"⏱️ Farm Delay",0.1,5,1,function(v) Settings.FarmDelay=v end,"s")
    Toggle(FP,"💰 Infinite Money","InfMoney","Tambah money leaderstats terus",C.Gold)
    Toggle(FP,"🆓 Steal Free Items","StealFree","Auto ambil item gratis/drop di map",C.Purple)

    Btn(FP,"💰 Collect All Coins Now",C.Green,function()
        local _,hrp2,_=GetChar()
        if not hrp2 then return end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local name=obj.Name:lower()
                if name:find("coin") or name:find("money") or name:find("cash") then
                    local dist=(obj.Position-hrp2.Position).Magnitude
                    if dist<100 then
                        hrp2.CFrame=CFrame.new(obj.Position+Vector3.new(0,3,0))
                        task.wait(0.05)
                    end
                end
            end
        end
    end)

    -- ══════════════════
    --   🛒 ITEMS TAB
    -- ══════════════════
    local IP=Pages["Items"]
    Label(IP,"  SPAWNER",C.Green)
    Toggle(IP,"🐾 Auto Pet Spawner","AutoPet","Auto hatch/spawn pet dari egg")
    Toggle(IP,"🌿 Auto Seed Spawner","AutoSeed","Auto collect & plant seed di map")
    Toggle(IP,"🛒 Auto Buy Item","AutoBuy","Auto beli item dari shop",C.Gold)

    -- Buy item input
    local buyCard=New("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=C.Card,BorderSizePixel=0},IP); Corner(buyCard,8); Stroke(buyCard,C.Border,1)
    New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,12,0,6),BackgroundTransparency=1,Text="🛒 Item to Buy",TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},buyCard)
    local buyBG=New("Frame",{Size=UDim2.new(1,-20,0,24),Position=UDim2.new(0,10,0,26),BackgroundColor3=C.BG3,BorderSizePixel=0},buyCard); Corner(buyBG,6); Stroke(buyBG,C.Border,1)
    local buyBox=New("TextBox",{Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),BackgroundTransparency=1,Text="Seed",TextColor3=C.Green,TextXAlignment=Enum.TextXAlignment.Left,TextSize=11,Font=Enum.Font.GothamBold,ClearTextOnFocus=false},buyBG)
    buyBox.FocusLost:Connect(function() Settings.BuyItem=buyBox.Text end)

    Btn(IP,"🛒 Buy Now (1x)",C.AccentDim,function()
        for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") and v.Name:lower():find("buy") then
                pcall(function() v:FireServer(Settings.BuyItem) end)
            end
        end
        for _,obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.ActionText:lower():find("buy") then
                pcall(function() fireproximityprompt(obj) end)
            end
        end
    end)

    -- ══════════════════
    --   🏃 PLAYER TAB
    -- ══════════════════
    local PP=Pages["Player"]
    Label(PP,"  MOVEMENT",C.Green)
    Toggle(PP,"✈️ Fly","Fly","Terbang (WASD + Space + Shift)")
    InputSlider(PP,"✈️ Fly Speed",10,200,40,function(v) Settings.FlySpeed=v end,"")
    Toggle(PP,"🚫 NoClip","NoClip","Tembus tembok/objek")
    Toggle(PP,"🦘 God Mode","GodMode","HP selalu penuh",C.Green)
    Toggle(PP,"💤 Anti AFK","AntiAFK","Cegah kick AFK")

    Label(PP,"  TELEPORT",C.Green)
    -- Player teleport list
    local tpCard=New("Frame",{Size=UDim2.new(1,0,0,96),BackgroundColor3=C.Card,BorderSizePixel=0},PP); Corner(tpCard,8); Stroke(tpCard,C.Border,1)
    New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.new(0,12,0,4),BackgroundTransparency=1,Text="🌀 Teleport to Player",TextColor3=C.Text,TextXAlignment=Enum.TextXAlignment.Left,TextSize=12,Font=Enum.Font.GothamBold},tpCard)
    local tpList=New("ScrollingFrame",{Size=UDim2.new(1,-20,0,48),Position=UDim2.new(0,10,0,26),BackgroundColor3=C.BG3,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.Green,CanvasSize=UDim2.new(0,0,0,0)},tpCard); Corner(tpList,5)
    local tpLL=New("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,Padding=UDim.new(0,4)},tpList); New("UIPadding",{PaddingLeft=UDim.new(0,4)},tpList)

    local function RefreshTP()
        for _,c in ipairs(tpList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,plr in ipairs(Players:GetPlayers()) do
            if plr~=LocalPlayer then
                local b=New("TextButton",{Size=UDim2.new(0,80,0,42),BackgroundColor3=C.BG3,Text=plr.Name,TextColor3=C.TextSub,TextSize=9,Font=Enum.Font.GothamBold,BorderSizePixel=0},tpList)
                Corner(b,5); Stroke(b,C.Border,1)
                b.MouseButton1Click:Connect(function()
                    if plr.Character then
                        local root=plr.Character:FindFirstChild("HumanoidRootPart")
                        local _,hrp2,_=GetChar()
                        if root and hrp2 then hrp2.CFrame=CFrame.new(root.Position+Vector3.new(3,0,0)) end
                    end
                end)
            end
        end
        tpLL:ApplyLayout(); tpList.CanvasSize=UDim2.new(0,tpLL.AbsoluteContentSize.X+10,0,0)
    end
    RefreshTP()
    Btn(tpCard,"🔄 Refresh",nil,RefreshTP)

    -- Tool teleport
    Btn(PP,"🔧 TP Tool (Teleport to Click)",C.AccentDim,function()
        local _,hrp2,_=GetChar()
        if not hrp2 then return end
        local con; con=UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 then
                local ray=workspace:Raycast(Camera.CFrame.Position,Camera.CFrame.LookVector*500)
                if ray then hrp2.CFrame=CFrame.new(ray.Position+Vector3.new(0,5,0)) end
                pcall(function() con:Disconnect() end)
            end
        end)
        task.delay(10, function() pcall(function() con:Disconnect() end) end)
    end)

    -- ══════════════════
    --   👁 VISUAL TAB
    -- ══════════════════
    local VP=Pages["Visual"]
    Label(VP,"  ESP",C.Green)
    Toggle(VP,"👁 Player ESP","ESP","Highlight + nama + jarak player",C.Green)
    Toggle(VP,"🚀 Boost FPS","BoostFPS","Matikan partikel & efek berat")
    Btn(VP,"☀️ Full Bright",C.AccentDim,function()
        local L=game:GetService("Lighting"); L.Brightness=10; L.ClockTime=14; L.FogEnd=1e6; L.GlobalShadows=false
    end)
    Btn(VP,"🌙 Reset Lighting",nil,function()
        local L=game:GetService("Lighting"); L.Brightness=1; L.ClockTime=14; L.FogEnd=100000; L.GlobalShadows=true
    end)

    -- ══════════════════
    --   ⚙ SETTINGS TAB
    -- ══════════════════
    local SETP=Pages["Settings"]
    Label(SETP,"  SERVER",C.Green)
    Btn(SETP,"🔄 Rejoin Server",C.AccentDim,function()
        game:GetService("TeleportService"):Teleport(game.PlaceId,LocalPlayer)
    end)
    Btn(SETP,"🌐 Server Hop",C.AccentDim,function()
        pcall(function()
            local data=game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
            local servers={}
            for _,s in ipairs(data.data) do if s.playing<s.maxPlayers then table.insert(servers,s.id) end end
            if #servers>0 then game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,servers[math.random(1,#servers)],LocalPlayer) end
        end)
    end)
    Label(SETP,"  ABOUT",C.Green)
    local about=New("Frame",{Size=UDim2.new(1,0,0,76),BackgroundColor3=C.Card,BorderSizePixel=0},SETP); Corner(about,8); Stroke(about,C.Green,1)
    New("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=C.Green,BorderSizePixel=0},about)
    New("TextLabel",{Size=UDim2.new(1,-20,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,
        Text="🌱  H4ll0 W0rld Hub | GaG  v1.0\nGame   : Grow a Garden\nKey    : GaG_key\nDiscord: discord.gg/xCV9Tf4y5N",
        TextColor3=C.TextSub,TextXAlignment=Enum.TextXAlignment.Left,TextSize=10,TextWrapped=true,Font=Enum.Font.Gotham},about)

    local stopBtn=New("TextButton",{Size=UDim2.new(1,0,0,36),BackgroundColor3=C.Accent,Text="⛔  Stop All Features",TextColor3=Color3.fromRGB(255,200,200),TextSize=12,Font=Enum.Font.GothamBold,BorderSizePixel=0},SETP); Corner(stopBtn,8)
    stopBtn.MouseButton1Click:Connect(function()
        StopAll(); ClearESP()
        for k in pairs(Toggles) do Toggles[k]=false end
        stopBtn.Text="✅ All Stopped"; task.wait(2); stopBtn.Text="⛔  Stop All Features"
    end)

    SetTab("Farm")
end

-- ═══════════════════════════
--      KEY VALIDATION
-- ═══════════════════════════
EnterBtn.MouseButton1Click:Connect(function()
    if KInput.Text==VALID_KEY then
        KStatus.Text="✅ Key Valid! Loading..."; KStatus.TextColor3=C.Green
        for _,obj in ipairs(KeyScreen:GetDescendants()) do
            pcall(function()
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then Tween(obj,{TextTransparency=1},0.3) end
                if obj:IsA("Frame") then Tween(obj,{BackgroundTransparency=1},0.3) end
            end)
        end
        Tween(KeyScreen,{BackgroundTransparency=1},0.3)
        task.wait(0.5); BuildMain()
    else
        KStatus.Text="❌ Key salah!"; KStatus.TextColor3=C.Accent
        Tween(inputBG,{BackgroundColor3=Color3.fromRGB(40,8,8)},0.2)
        task.wait(0.4); Tween(inputBG,{BackgroundColor3=C.BG3},0.2)
    end
end)
