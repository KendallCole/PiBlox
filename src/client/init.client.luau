local PiBlox = require(game.ReplicatedStorage.Shared.PiBlox)

local camera = workspace.CurrentCamera
local UI = game.StarterGui:WaitForChild("UI"):Clone()
local POW = 1
local victorySound = Instance.new("Sound")
victorySound.SoundId = "rbxassetid://6684542570"

UI.Parent = game:GetService("Players").LocalPlayer.PlayerGui


local cb = function(params)
    UI.Counter.Text = ("Collisions: " ..  tostring(params.collisions))
    local pi = math.floor(math.pi * math.pow(10,  params.pow))
    if pi == params.collisions then
        UI.Counter.TextColor3 = Color3.fromHex("#fff712")
        print("Hey, thats like Pi!")
        game:GetService("SoundService"):PlayLocalSound(victorySound)
    else
        UI.Counter.TextColor3 = Color3.new(0,0,0)
    end
end


local sim = PiBlox.Simulation:New(1)
sim:Run(cb)


UI.Reset.MouseButton1Down:Connect(function()
    if sim then
        sim:Destroy()
    end
    sim = PiBlox.Simulation:New(POW)
    sim:Run(cb)
end)

UI.Frame.Dragger.TextLabel.Text = "^"..1
local dragger: UIDragDetector = UI.Frame.Dragger.UIDragDetector
dragger.DragContinue:Connect(function()
    local n =(math.clamp(math.ceil((UI.Frame.Dragger.Position.X.Scale)*4), 1, 4))
    UI.Frame.Dragger.TextLabel.Text = "^"..n
    POW = n
end)

dragger.DragEnd:Connect(function()
    if sim then
        sim:Destroy()
    end
    sim = PiBlox.Simulation:New(POW)
    sim:Run(cb)
end)


camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(100, 25, -50.477005, -0.99993366, 0.00320791942, -0.0110633494, 0, 0.960439682, 0.278488278, 0.0115190465, 0.278469801, -0.960375965)