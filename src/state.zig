const std = @import("std");
const ui = @import("./ui.zig");
const sim = @import("./sim.zig");
const cmd = @import("./cmd.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const Cell = sim.Cell;
const CellType = sim.CellType;
const CellTime = std.EnumArray(CellType, u64);
const UIState = ui.UIState;
const CmdState = cmd.CmdState;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 456;
const TILE_SIZE = 8;

pub const GameState = struct {
    screenWidth: u16 = SCREEN_WIDTH,
    screenHeight: u16 = SCREEN_HEIGHT,

    mapWidth: u16 = SCREEN_WIDTH / TILE_SIZE,
    mapHeight: u16 = SCREEN_HEIGHT / TILE_SIZE,
    map: [SCREEN_HEIGHT / TILE_SIZE][SCREEN_WIDTH / TILE_SIZE]Cell = undefined,

    tileSize: u8 = TILE_SIZE,

    startTime: Instant,
    lastTick: CellTime = undefined,

    // TODO - We lose some accuracy because any remainder of each tick is disregarded when the
    // tick is slightly later than the exact time for the next simulation
    // tickRemainder: CellTime = undefined,

    ui: UIState = UIState{},
    cmd: CmdState = CmdState{},

    // TODO - add time control for speed & pause

    // TODO - add undo while paused

    pub fn init(startTime: Instant) GameState {
        return GameState{
            .startTime = startTime,
        };
    }
};
