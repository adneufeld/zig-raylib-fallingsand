const std = @import("std");
const ui = @import("./ui.zig");
const sim = @import("./sim.zig");

const Allocator = std.mem.Allocator;
const Instant = std.time.Instant;

const Cell = sim.Cell;
const CellType = sim.CellType;
const CellTime = std.EnumArray(CellType, u64);
const UIState = ui.UIState;

pub fn State(comptime screenWidth: u16, comptime screenHeight: u16, comptime tileSize: u8) type {
    const mapWidth = screenWidth / tileSize;
    const mapHeight = screenHeight / tileSize;

    return struct {
        const Self = @This();

        screenWidth: u16 = screenWidth,
        screenHeight: u16 = screenHeight,

        mapWidth: u16 = mapWidth,
        mapHeight: u16 = mapHeight,
        map: [mapHeight][mapWidth]Cell = undefined,

        tileSize: u8 = tileSize,

        startTime: Instant,
        lastTick: CellTime = undefined,
        // tickRemainder: CellTime = undefined,

        ui: UIState = UIState{},

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
}
