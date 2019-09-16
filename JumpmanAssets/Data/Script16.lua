local read_only = require "Data/read_only";

-- TODO: Move this into a shared file, split into separate tables by type. Or inject from engine?
local player_state = {
    JSNORMAL = 0,
    JSJUMPING = 1,
    JSRIGHT = 2,
    JSLEFT = 4,
    JSFALLING = 8,
    JSLADDER = 16,
    JSKICK = 32,
    JSROLL = 64,
    JSPUNCH = 128,
    JSDYING = 256,
    JSVINE = 1024,
};
player_state = read_only.make_table_read_only(player_state);

-- TODO: Auto-generate this table as separate file, and import it here?
local resources = {
    TextureJumpman = 0,
    TextureClassicPlatform = 1,
    TextureBlueMarble = 2,
    TextureRedMetal = 3,
    TextureSky = 4,
    SoundJump = 0,
    SoundChomp = 1,
    SoundBonk = 2,
    SoundFire = 3,
    ScriptBullet = 0,
    MeshBullet1 = 0,
    MeshBullet2 = 1,
    TextureBullet = 5,
    TextureTurtleTexture = 6,
    MeshTurtGL1 = 2,
    MeshTurtGL2 = 3,
    MeshTurtGR1 = 4,
    MeshTurtGR2 = 5,
    MeshTurtS1 = 6,
    MeshTurtSH1 = 7,
    MeshTurtSH2 = 8,
    ScriptTurtle = 1,
};
resources = read_only.make_table_read_only(resources);

-- TODO: Separate file?
local turtle_properties = {
    TurtleStartX = 0,
    TurtleStartY = 1,
    TurtleIInit = 2,
    TurtleIX = 3,
    TurtleIY = 4,
    TurtleIZ = 5,
    TurtleIFrame = 6,
    TurtleIStatus = 7,
    TurtleICount = 8,
    TurtleISlow = 9,
    TurtleISlowFrame = 10,
    TurtleAngle = 11,
    TurtleIMeshes = 12,
};
turtle_properties = read_only.make_table_read_only(turtle_properties);

local is_initialized = false;

function update()
    if not is_initialized then
        is_initialized = true;

        CreateTurtle(128, 8);
        CreateTurtle(65, 12);
        CreateTurtle(80, 10);

        CreateTurtle(10, 66);
        CreateTurtle(26, 42);

        CreateTurtle(80, 40);

        CreateTurtle(20, 88);
        CreateTurtle(50, 88);

        CreateTurtle(90, 111);
        CreateTurtle(120, 113);

        CreateTurtle(20, 118);

        CreateTurtle(49, 144);
        CreateTurtle(60, 144);

        CreateTurtle(10, 172);
        CreateTurtle(60, 172);

        CreateTurtle(140, 170);
        CreateTurtle(140, 145);
    end
end

function CreateTurtle(iX, iY)
    local iTemp = spawn_object(resources.ScriptTurtle);
    set_object_global_data(iTemp, turtle_properties.TurtleStartX, iX);
    set_object_global_data(iTemp, turtle_properties.TurtleStartY, iY);
end

function reset()
    set_player_current_position_x(27);
    set_player_current_position_y(3);
    set_player_current_position_z(4);
    set_player_current_state(player_state.JSNORMAL);
end
