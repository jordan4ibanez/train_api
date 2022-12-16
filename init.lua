
local Direction = {
    NONE  = 0,
    LEFT  = 1,
    RIGHT = 2,
    BACK  = 3,
    FRONT = 4
}

local debugEntity = {
    direction = Direction.NONE
}



minetest.register_entity("train_api:debug", debugEntity)