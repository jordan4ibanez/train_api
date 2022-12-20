
-- Direction enum
local Direction = {
    NONE  = 0,
    LEFT  = 1,
    RIGHT = 2,
    BACK  = 3,
    FRONT = 4
}

local function adjustY(inputVec, yAdjust)
    inputVec.y = inputVec.y + yAdjust
    return inputVec
end

-- Debug Entity class
local debugEntity = {}
debugEntity.initial_properties = {
    physical = true,
    collide_with_objects = false,
    collisionbox = {-0.3, -0.25, -0.3, 0.3, 0.3, 0.3},
    visual = "mesh",
    mesh = "debug_train.b3d",
    visual_size = {x = 0.65, y = 0.65},
    textures = {"debug_train.png"},
    initial_sprite_basepos = {x = 0, y = 0}
}

debugEntity.direction  = Direction.NONE
debugEntity.onRail     = false
debugEntity.flatOffset = 0.3


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

    if not wasOnRail and self.onRail then

        local newPos = vector.round(object:get_pos())
        
        object:set_pos(newPos)

        object:set_acceleration(vector.new(0,0,0))

        object:set_velocity(vector.new(0,0,0))
    end

    if self.onRail and self.direction == Direction.NONE then

        print("Poll this crap")

    end
end

minetest.register_entity("train_api:debug", debugEntity)