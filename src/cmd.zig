const std = @import("std");
const ds = @import("./datastructs.zig");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const math = @import("./math.zig");

const CmdQueue = ds.DropQueue(Cmd, 8);
const GameState = state.GameState;
const CellType = sim.CellType;
const MapPoint = ds.MapPoint;

var prng = std.rand.DefaultPrng.init(0);

pub const CmdState = struct {
    queue: CmdQueue = CmdQueue.init(),
};

pub const Cmd = union(enum) {
    addCells: AddCellsCmd,

    pub fn execute(self: Cmd, s: *GameState) void {
        switch (self) {
            inline else => |case| case.execute(s),
        }
    }
};

pub const CmdSystem = struct {
    const Self = @This();

    state: *GameState,

    pub fn init(gameState: *GameState) Self {
        return Self{
            .state = gameState,
        };
    }

    pub fn update(self: *Self) void {
        if (self.state.cmd.queue.size <= 0) return; // shouldn't be needed but the debugger goes into the loop below weirdly without this
        while (self.state.cmd.queue.front()) |c| {
            c.execute(self.state);
        }
    }
};

pub const AddCellsCmd = struct {
    radius: u16,
    pt: MapPoint,
    type: CellType,
    density: f32 = 1.0, // 0 to 1

    pub fn execute(self: AddCellsCmd, s: *GameState) void {
        const tileRadius: u16 = self.radius / s.tileSize;
        const topLeft = self.pt.sub(MapPoint{
            .x = @intCast(tileRadius),
            .y = @intCast(tileRadius),
        });
        const bottomRight = topLeft.add(MapPoint{
            .x = @intCast(2 * tileRadius + 1),
            .y = @intCast(2 * tileRadius + 1),
        });

        var y = topLeft.y;
        while (y < bottomRight.y) : (y += 1) {
            var x = topLeft.x;
            while (x < bottomRight.x) : (x += 1) {
                // ensure x, y are in map bounds
                if (!(MapPoint{ .x = x, .y = y }).isInRect(0, 0, s.mapWidth, s.mapHeight)) continue;
                const ux: u16 = @intCast(x);
                const uy: u16 = @intCast(y);

                if (prng.random().float(f32) > self.density) continue;
                if (!math.pointInCircle(
                    @floatFromInt(self.pt.x),
                    @floatFromInt(self.pt.y),
                    @floatFromInt(tileRadius),
                    @floatFromInt(x),
                    @floatFromInt(y),
                )) {
                    continue;
                }
                if (!s.insideMap(ux, uy)) {
                    continue;
                }

                s.map[uy][ux].type = self.type;
                s.map[uy][ux].dirty = true;
                s.map[uy][ux].frame = self.type.numFrames();
            }
        }
    }
};
