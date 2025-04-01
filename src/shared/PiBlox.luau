local PiBlox = {}

local SFX_ID = "rbxassetid://18215163477"
local UPDATES_PER_TICK = 1000
local MAX_SOUND_POOL = 25       

-- [Block Class]
local Block = {}
Block.__index = Block

function Block:New(color)
    color = color or Color3.new(math.random(), math.random(), math.random())
    local self = setmetatable({}, Block)
    
    self.Density = 1
    self.Position = Vector3.new(0, 0, 0)
    self.Velocity = Vector3.new(0, 0, 0)
    self.Size = Vector3.new(1, 1, 1)
    self.mass = self.Size.X * self.Size.Y * self.Density
    
    self.__part__ = Instance.new("Part")
    self.__part__.Color = color
    self.__part__.Parent = workspace
    self.__part__.Anchored = true
    self.__part__.CanCollide = false
    self.__part__.Size = self.Size

    
    local sg = Instance.new("SurfaceGui")
    local tb = Instance.new("TextBox")
    tb.Parent = sg
    tb.BackgroundTransparency = 1
    tb.TextScaled = true
    tb.Text = ""
    tb.Size = UDim2.new(1,0,1,0)
    sg.Parent = self.__part__

    self.label = tb

    return self
end

function Block:SetMass(toMass)
    self.label.Text = toMass.."kg"
    self.mass = toMass
end
function Block:Destroy()
    self.__part__:Destroy()
end

function Block:__SetPartPos__()
    self.__part__.Position = self.Position
end

function Block:Update()
    self.Position = self.Position + self.Velocity
    self:__SetPartPos__()
end

function Block:SetSize(newX, newY)
    self.Size = Vector3.new(newX, newY, 1)
    self.__part__.Size = self.Size
end

function Block:SetPosition(newX, newY)
    self.Position = Vector3.new(newX, newY, 0)
    self:__SetPartPos__()
end

function Block:TransferVelocity(other)
    local mass1 = self.mass --  self.Size.X * self.Size.Y * self.Density
    local mass2 = other.mass -- other.Size.X * other.Size.Y * other.Density

    local v1x, v2x = self.Velocity.X, other.Velocity.X
    local newV1x = ((v1x * (mass1 - mass2)) + (2 * mass2 * v2x)) / (mass1 + mass2)
    local newV2x = ((v2x * (mass2 - mass1)) + (2 * mass1 * v1x)) / (mass1 + mass2)

    self.Velocity = Vector3.new(newV1x, self.Velocity.Y, 0)
    other.Velocity = Vector3.new(newV2x, other.Velocity.Y, 0)
end

function Block:isColliding(otherObject)
    local obj1Left = self.Position.X - self.Size.X / 2
    local obj1Right = self.Position.X + self.Size.X / 2
    local obj1Top = self.Position.Y + self.Size.Y / 2
    local obj1Bottom = self.Position.Y - self.Size.Y / 2

    local obj2Left = otherObject.Position.X - otherObject.Size.X / 2
    local obj2Right = otherObject.Position.X + otherObject.Size.X / 2
    local obj2Top = otherObject.Position.Y + otherObject.Size.Y / 2
    local obj2Bottom = otherObject.Position.Y - otherObject.Size.Y / 2

    return not (obj1Right <= obj2Left or obj1Left >= obj2Right or obj1Bottom >= obj2Top or obj1Top <= obj2Bottom)
end

-- [Simulation Class]
local Simulation = {}
Simulation.__index = Simulation

function Simulation:New(pow)
    local sound = Instance.new("Sound")
    sound.SoundId = SFX_ID
    sound.Parent = workspace
    local self = setmetatable({pow = pow, instances = {}, sounds = {sound},  task = nil, collisions = 0 }, Simulation)
    return self
end

function Simulation:Run(onCollisionCallback: (any) -> ()?)

 

    local rightWall = Block:New()
    rightWall:SetSize(100, 1000)
    rightWall:SetPosition(175, 0)

    local block1 = Block:New(Color3.new(1,1,1))
    local block2 = Block:New()

    block1:SetSize(10, 10)
    block1:SetPosition(100, block1.Size.Y/2)
    block1:SetMass(1)

    block2:SetMass(math.pow(100, self.pow))
    block2:SetSize(40, 40)
    block2:SetPosition(60, block2.Size.Y/2)
    block2.Velocity = Vector3.new(.001, 0, 0)

    self.instances = {block1, block2, rightWall}

    local function onColisionTask()
        
        self.collisions = self.collisions + 1

        if onCollisionCallback then
            onCollisionCallback({["collisions"]=self.collisions, ["pow"] = self.pow})
        end

        local selectedSound = nil
        for i, sound: Sound in self.sounds do
            if not sound.IsPlaying then
                selectedSound = sound
                break
            end
        end
        if selectedSound == nil then
            if #self.sounds == MAX_SOUND_POOL then
                selectedSound = self.sounds[1 +  self.collisions % MAX_SOUND_POOL] 
            else
                selectedSound = Instance.new("Sound")
                selectedSound.Parent = workspace
                selectedSound.SoundId = SFX_ID
                table.insert(self.sounds, selectedSound)
            end
        end
        if not selectedSound.IsPlaying then
            selectedSound:Play()
        end
    end
    
       
    if onCollisionCallback then
        onCollisionCallback({["collisions"]=self.collisions,["pow"]=self.pow})
    end

    self.task = task.spawn(function()
        while task.wait() do

            for i=1, UPDATES_PER_TICK do
                if block1:isColliding(block2) then
                    block1:TransferVelocity(block2)
                    onColisionTask()
                end

                if block1:isColliding(rightWall) then
                    block1.Velocity = Vector3.new(-block1.Velocity.X, 0, 0)
                    onColisionTask()

                end

                if block2:isColliding(rightWall) then
                    block2.Velocity = Vector3.new(-block2.Velocity.X, 0, 0)
                    onColisionTask()
                end

                
                block1:Update()
                block2:Update()
            end
        end
    end)
end

function Simulation:Destroy()
    task.cancel(self.task)
    for _, inst in self.instances do
        inst:Destroy()
    end
end


return {
    ["Simulation"] = Simulation 
}
