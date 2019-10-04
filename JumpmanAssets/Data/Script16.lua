local read_only = require "Data/read_only";
local game_logic_module = assert(loadfile("Data/game_logic.lua"));
local hud_overlay_module = assert(loadfile("Data/hud_overlay.lua"));
local turtle_module = assert(loadfile("Data/turtle.lua"));

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

local g_title_is_done_scrolling = false;

local g_game_logic;
local g_hud_overlay;
local g_turtles = {};

local function CreateTurtle_(iX, iY)
    local new_turtle = turtle_module();
    new_turtle.GameLogic = g_game_logic;
    new_turtle.MoveRightMeshResourceIndices = { resources.MeshTurtGR1, resources.MeshTurtGR2 };
    new_turtle.MoveLeftMeshResourceIndices = { resources.MeshTurtGL1, resources.MeshTurtGL2 };
    new_turtle.HideMeshResourceIndices = { resources.MeshTurtS1, resources.MeshTurtSH1 };
    new_turtle.TextureResourceIndex = resources.TextureTurtleTexture;
    new_turtle.InitialPosX = iX;
    new_turtle.InitialPosY = iY;
    new_turtle.initialize();
    return new_turtle;
end

local function ProgressLevel_(game_input)
    local player_won = g_game_logic.progress_game(game_input);
    g_hud_overlay.update(game_input);

    if player_won then
        return;
    end

    for _, turtle in ipairs(g_turtles) do
        turtle.update(game_input, g_turtles);
    end

    g_game_logic.update_player_graphics();
end

function initialize(game_input)
    g_game_logic = game_logic_module();
    g_game_logic.ResetPlayerCallback = reset;

    g_hud_overlay = hud_overlay_module();

    table.insert(g_turtles, CreateTurtle_(128, 8));
    table.insert(g_turtles, CreateTurtle_(65, 12));
    table.insert(g_turtles, CreateTurtle_(80, 10));

    table.insert(g_turtles, CreateTurtle_(10, 66));
    table.insert(g_turtles, CreateTurtle_(26, 42));

    table.insert(g_turtles, CreateTurtle_(80, 40));

    table.insert(g_turtles, CreateTurtle_(20, 88));
    table.insert(g_turtles, CreateTurtle_(50, 88));

    table.insert(g_turtles, CreateTurtle_(90, 111));
    table.insert(g_turtles, CreateTurtle_(120, 113));

    table.insert(g_turtles, CreateTurtle_(20, 118));

    table.insert(g_turtles, CreateTurtle_(49, 144));
    table.insert(g_turtles, CreateTurtle_(60, 144));

    table.insert(g_turtles, CreateTurtle_(10, 172));
    table.insert(g_turtles, CreateTurtle_(60, 172));

    table.insert(g_turtles, CreateTurtle_(140, 170));
    table.insert(g_turtles, CreateTurtle_(140, 145));

    reset();

    -- Make sure staged initialization has happened, and Jumpman has floated to the floor
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
    ProgressLevel_(game_input);
end

function update(game_input, is_initializing)
    if not g_title_is_done_scrolling then
        g_title_is_done_scrolling = g_hud_overlay.update(game_input);
        return;
    end

    ProgressLevel_(game_input);
end

function reset()
    g_game_logic.set_player_current_position_x(27);
    g_game_logic.set_player_current_position_y(3);
    g_game_logic.set_player_current_position_z(4);
    g_game_logic.set_player_current_state(player_state.JSNORMAL);
end
