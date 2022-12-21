-- Think of the train as a dog with a blindfold on and it's sniffing it's way through the map

--! Important note: There will be absolutely NO optimizations to this at all until there is at least a functioning 10 car train

-- I'm actually surprised these two functions are missing from both LuaJIT and Minetest
function math.fma(x, y, z)
    return (x * y) + z
end
--* Interpolation amount is a value in range of 0.0 to 1.0
function vector.lerp(vectorOrigin, vectorDestination, interpolationAmount)
    return vector.new(
        math.fma(vectorDestination.x - vectorOrigin.x, interpolationAmount, vectorOrigin.x),
        math.fma(vectorDestination.y - vectorOrigin.y, interpolationAmount, vectorOrigin.y),
        math.fma(vectorDestination.z - vectorOrigin.z, interpolationAmount, vectorOrigin.z)
    )
end

local HALF_PI = math.pi / 2

-- Direction enum
local Direction = {
    NONE  = 0,
    LEFT  = 1,
    BACK  = 2,
    RIGHT = 3,
    FRONT = 4
}
local LinearDirection = {
    Direction.LEFT,
    Direction.BACK,
    Direction.RIGHT,
    Direction.FRONT
}
local DirectionTranslation = {
    "NONE",
    "LEFT",
    "BACK",
    "RIGHT",
    "FRONT"
}
local DirectionLiteral = { -- Direction enum translation
    vector.new(-1, 0, 0),  -- LEFT
    vector.new( 0, 0,-1),  -- BACK
    vector.new( 1, 0, 0),  -- RIGHT
    vector.new( 0, 0, 1)   -- FRONT
}

--Todo: direction blocking translation, doesn't allow train back down the path it came from

local function adjustY(inputVec, yAdjust)
    inputVec.y = inputVec.y + yAdjust
    return inputVec
end


local function isRail(position)
    return minetest.get_item_group(minetest.get_node(position).name, "rail") > 0
end
local function sniffDirection(position)
    for index, modifier in ipairs(DirectionLiteral) do
        if isRail(vector.add(position, modifier)) then
             return LinearDirection[index]
        end
    end
end


-- Debug Entity class
local debugEntity = {}
debugEntity.initial_properties = {}
local initProps = debugEntity.initial_properties

initProps.physical = true
initProps.collide_with_objects = false
initProps.collisionbox = {-0.3, -0.25, -0.3, 0.3, 0.3, 0.3}
initProps.visual = "mesh"
initProps.mesh = "debug_train.b3d"
initProps.visual_size = {x = 0.65, y = 0.65}
initProps.textures = {"debug_train.png"}
initProps.initial_sprite_basepos = {x = 0, y = 0}

--* Visual elements
debugEntity.flatOffset  = -0.25

--* Path sniffing elements
debugEntity.direction   = Direction.NONE
debugEntity.onRail      = false
debugEntity.currentTile = nil
debugEntity.headWayTile = nil
debugEntity.rotationAdjustment = 0 -- Multiplies math.pi so 2 would be 180 degrees, 3 270, etc

--* Interpolation elements
debugEntity.progress    = 0

-- Rail memory will be added into later on
-- Rail memory is an optimization that allows for the train to use it's previous calculations to automatically move rail cars over it's previous positions
debugEntity.railMemory  = {}


-- Reuse the pointer to ease the pressure on the garbage collector
local object

function debugEntity:on_activate(staticdata, dtime_s)
    object = self.object

    object:set_armor_groups({immortal = 1})

    if not self.onRail then

        print("I am not on a rail")

        object:set_acceleration(vector.new(0,-9.81,0))

    end

end

function debugEntity:on_step(dtime)
    object = self.object

    local wasOnRail = self.onRail

    -- Train thinks it's on a tile
    if self.currentTile then
        self.onRail = isRail(self.currentTile)
    -- Train was not on a tile, or did not successfully restore tile memory - latter would be an engine bug or host machine failure
    else
        self.onRail = isRail(vector.round(object:get_pos()))
    end

    -- Train is about to fall of the rail
    if self.headWayTile then
        if not isRail(self.headWayTile) then
            self.direction = Direction.NONE
            self.headWayTile = nil
        end
    end

    --* These two functions are for when a train has a state update

    -- Train fell off rail OR rail was modified by external mod/player
    if wasOnRail and not self.onRail then

        object:set_acceleration(vector.new(0,-9.81, 0))

        self.direction = Direction.NONE

        print("rail failure")

    -- Check if current position is a rail
    elseif not wasOnRail and self.onRail then

        print("rail update")

        local newPos = vector.round(object:get_pos())

        self.currentTile = vector.copy(newPos)
        
        object:set_pos(adjustY(newPos, self.flatOffset))

        object:set_acceleration(vector.new(0,0,0))

        object:set_velocity(vector.new(0,0,0))
    end

    -- The train successfully snapped itself into a rail, now poll for a free direction
    if self.onRail and self.direction == Direction.NONE then

        local newDir = sniffDirection(object:get_pos())

        print(DirectionTranslation[newDir])

        self.direction = LinearDirection[newDir]

        print("My direction = " .. self.direction)

        if self.direction ~= Direction.NONE then
            self.headWayTile = vector.add(self.currentTile, DirectionLiteral[self.direction])
        end
    end

    -- The train is still free floating in the environment, let it exist
    --[[
    if not self.onRail or self.direction == Direction.NONE then
        print("I cannot do anything, I'm not on a rail")
        return
    end
    ]]

    if not self.onRail then
        print("I am not on a rail, I will not continue")
        return
    end
    
    if self.direction == Direction.NONE then
        -- Doesn't matter what this direction is, if it's on a solo rail, they always face this way. Just make the train look like it's on it
        object:set_yaw(HALF_PI * (Direction.FRONT + self.rotationAdjustment))
        print("I have no where to go, I will not continue")
        return
    end

    object:set_yaw(HALF_PI * (self.direction + self.rotationAdjustment))

    print("Yaw: " .. object:get_yaw())

    if self.progress < 1 then
        self.progress = self.progress + dtime
        object:set_pos(adjustY(vector.lerp(self.currentTile, self.headWayTile, self.progress), self.flatOffset))
    else
        self.progress = 0
        self.currentTile = self.headWayTile
        self.headWayTile = nil
        self.direction = Direction.NONE
    end


end

minetest.register_entity("train_api:debug", debugEntity)