-- Think of the train as a dog with a blindfold on and it's sniffing it's way through the map

-- Direction enum
local Direction = {
    NONE  = 0,
    LEFT  = 1,
    RIGHT = 2,
    BACK  = 3,
    FRONT = 4
}
local LinearDirection = {
    Direction.LEFT,
    Direction.RIGHT,
    Direction.BACK,
    Direction.FRONT
}
local directionTranslation = {
    "NONE", "LEFT", "RIGHT", "BACK", "FRONT"
}

local function adjustY(inputVec, yAdjust)
    inputVec.y = inputVec.y + yAdjust
    return inputVec
end

local Sniffs = {          -- Direction enum translation
    vector.new(-1, 0, 0), -- LEFT
    vector.new( 1, 0, 0), -- RIGHT
    vector.new( 0, 0,-1), -- BACK
    vector.new( 0, 0, 1)  -- FRONT
}
local function isRail(position)
    return minetest.get_item_group(minetest.get_node(position).name, "rail") > 0
end
local function sniffDirection(position)
    for index, modifier in ipairs(Sniffs) do
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

debugEntity.direction   = Direction.NONE
debugEntity.onRail      = false
debugEntity.flatOffset  = -0.25
debugEntity.progress    = 0
debugEntity.currentTile = vector.new()
debugEntity.rotationAdjustment = 1 -- Multiplies math.pi so 2 would be 180 degrees, 3 270, etc

-- Rail memory will be added into later on
-- Rail memory is an optimization that allows for the train to use it's previous calculations to automatically move rail cars over it's previous positions
debugEntity.railMemory = {}


-- Pass the pointer because I'm lazy
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

    local name = minetest.get_node(object:get_pos()).name


    local wasOnRail = self.onRail

    self.onRail = minetest.get_item_group(name, "rail") > 0

    -- Sniff for that rail

    if not wasOnRail and self.onRail then

        local newPos = vector.round(object:get_pos())
        
        object:set_pos(adjustY(newPos, self.flatOffset))

        object:set_acceleration(vector.new(0,0,0))

        object:set_velocity(vector.new(0,0,0))
    end

    -- The train successfully plopped itself into a rail, now poll for a free direction
    if self.onRail and self.direction == Direction.NONE then

        local newDir = sniffDirection(object:get_pos())

        print(directionTranslation[newDir])

        self.direction = LinearDirection[newDir]
    end

    -- The train is still free floating in the environment, let it exist
    if not (self.onRail or self.direction) then
        print("I cannot do anything, I'm not on a rail")
        return
    end




end

minetest.register_entity("train_api:debug", debugEntity)