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
    const Self = @This();

    screenWidth: u16 = SCREEN_WIDTH,
    screenHeight: u16 = SCREEN_HEIGHT,

    mapWidth: u16 = SCREEN_WIDTH / TILE_SIZE,
    mapHeight: u16 = SCREEN_HEIGHT / TILE_SIZE,
    map: [SCREEN_HEIGHT / TILE_SIZE][SCREEN_WIDTH / TILE_SIZE]Cell = undefined,

    tileSize: u8 = TILE_SIZE,

    startTime: Instant,
    lastTick: CellTime = undefined,
    // tickRemainder: CellTime = undefined,

    ui: UIState = UIState{},
    cmd: CmdState = CmdState{},

    // TODO - add time control for speed & pause

    // TODO - add undo

    pub fn init() !Self {
        const startTime = try Instant.now();
        var new = Self{
            .startTime = startTime,
        };

        {
            // little sand column to show our simulation works
            const width = 4;
            const wStart = new.mapHeight / 2 - width / 2;
            const wEnd = wStart + width;
            for (10..35) |hInd| {
                for (wStart..wEnd) |wInd| {
                    new.map[hInd][wInd].type = CellType.sand;
                }
            }
        }

        {
            // little water to drop on the sand
            const width = 30;
            const wStart = new.mapHeight / 2 - width / 2;
            const wEnd = wStart + width;
            for (0..4) |hInd| {
                for (wStart..wEnd) |wInd| {
                    new.map[hInd][wInd].type = CellType.water;
                }
            }
        }

        return new;
    }
};
