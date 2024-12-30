const std = @import("std");
const ds = @import("./datastructs.zig");
const state = @import("./state.zig");
const sim = @import("./sim.zig");
const math = std.math;

const CmdQueue = ds.DropQueue(Cmd, 8);
const GameState = state.GameState;
const CellType = sim.CellType;
const PointU16 = ds.MapPoint;

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
    const Self = @This();

    radius: u16,
    pt: PointU16,
    type: CellType,

    pub fn execute(self: Self, s: *GameState) void {
        const tileRadius: u16 = self.radius / s.tileSize;
        const topLeft = self.pt.sub(PointU16{ .x = tileRadius, .y = tileRadius });
        const bottomRight = topLeft.add(PointU16{ .x = 2 * tileRadius + 1, .y = 2 * tileRadius + 1 });
        for (topLeft.y..bottomRight.y) |y| {
            for (topLeft.x..bottomRight.x) |x| {
                if (pointInCircle(
                    @floatFromInt(self.pt.x),
                    @floatFromInt(self.pt.y),
                    @floatFromInt(tileRadius),
                    @floatFromInt(x),
                    @floatFromInt(y),
                ) and s.map[y][x].type == CellType.none) {
                    s.map[y][x].type = self.type;
                    s.map[y][x].dirty = true;
                }
            }
        }
    }
};

fn pointInCircle(xCenter: f32, yCenter: f32, radius: f32, x: f32, y: f32) bool {
    const xDiff = x - xCenter;
    const yDiff = y - yCenter;
    const distance = @sqrt(xDiff * xDiff + yDiff * yDiff);
    return distance <= radius;
}
