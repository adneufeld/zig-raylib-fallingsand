const std = @import("std");
const ds = @import("./datastructs.zig");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const math = @import("./math.zig");

const CmdQueue = ds.DropQueue(Cmd, 8);
const GameState = state.GameState;
const CellType = sim.CellType;
const PointU16 = ds.MapPoint;

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
    pt: PointU16,
    type: CellType,
    density: f32 = 1.0, // 0 to 1

    pub fn execute(self: AddCellsCmd, s: *GameState) void {
        const tileRadius: u16 = self.radius / s.tileSize;
        const topLeft = self.pt.sub(PointU16{ .x = tileRadius, .y = tileRadius });
        const bottomRight = topLeft.add(PointU16{ .x = 2 * tileRadius + 1, .y = 2 * tileRadius + 1 });
        for (topLeft.y..bottomRight.y) |y| {
            for (topLeft.x..bottomRight.x) |x| {
                if (prng.random().float(f32) <= self.density and
                    math.pointInCircle(
                    @floatFromInt(self.pt.x),
                    @floatFromInt(self.pt.y),
                    @floatFromInt(tileRadius),
                    @floatFromInt(x),
                    @floatFromInt(y),
                ) and s.insideMap(x, y)) {
                    s.map[y][x].type = self.type;
                    s.map[y][x].dirty = true;
                }
            }
        }
    }
};
