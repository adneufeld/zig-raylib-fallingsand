const std = @import("std");
const rl = @import("raylib");

const Instant = std.time.Instant;
const CellSimTick = std.EnumArray(CellType, bool);

pub const Cell = struct {
    type: CellType = CellType.none,
    dirty: bool = false,
};

pub const CellType = enum(u8) {
    none = 0,
    sand,
    water,

    pub fn color(self: CellType) rl.Color {
        return switch (self) {
            CellType.none => rl.Color.black,
            CellType.sand => rl.Color.init(191, 164, 94, 255),
            CellType.water => rl.Color.init(80, 107, 243, 255),
        };
    }

    pub fn freq(self: CellType) u64 {
        return switch (self) {
            else => 100 * std.time.ns_per_ms,
        };
    }
};

pub fn CellularAutomata(comptime S: type) type {
    return struct {
        const Self = @This();

        state: *S,

        pub fn init(state: *S) Self {
            return Self{
                .state = state,
            };
        }

        pub fn simulate(self: *Self, elapsed: u64) !void {
            var simThisTick: CellSimTick = self.doesCellSimulateThisTick(elapsed);

            // do the simulation bottom to top for falling cells
            var h: i32 = @as(i32, self.state.mapHeight) - 1;
            while (h >= 0) : (h -= 1) {
                const hInd: usize = @intCast(h);

                // PROBLEM: anything moving towards the right has the "left" cell simulated moving rightwards
                // then the right cell is simulated and the first target is leftware so it moves right back. Also
                // because the update order is left to right only the right-most cell in a line of potentially
                // right-moving cells ever updates.

                for (0..self.state.mapWidth) |wInd| {
                    const cell = self.state.map[hInd][wInd];

                    if (!simThisTick.get(cell.type) or cell.dirty) continue;

                    switch (cell.type) {
                        CellType.sand => self.sand(wInd, hInd),
                        CellType.water => self.water(wInd, hInd),
                        else => continue,
                    }
                }
            }
        }

        // Whether each cell type should simulate their cellular automata on this specific update tick
        fn doesCellSimulateThisTick(self: *Self, elapsed: u64) CellSimTick {
            var simThisTick = CellSimTick.initFill(false);
            var it = simThisTick.iterator();
            while (it.next()) |entry| {
                const cell = entry.key;
                const cellLastTick = self.state.lastTick.get(cell);
                const cellFreq = cell.freq();
                // const tickRemainder = state.tickRemainder.get(Cell.sand);

                if (elapsed > cellLastTick + cellFreq) {
                    simThisTick.set(cell, true);
                    self.state.lastTick.set(cell, elapsed);
                    // const newTickRemainder = elapsed - lastTick; - Cell.sand.freq();
                    // state.tickRemainder.set(Cell.sand, newTickRemainder);
                }
            }
            return simThisTick;
        }

        fn insideMap(self: *Self, x: usize, y: usize) bool {
            return x >= 0 and x <= self.state.mapWidth - 1 and
                y >= 0 and y <= self.state.mapHeight - 1;
        }

        fn sand(self: *Self, x: usize, y: usize) void {
            const targets = [3]struct { x: usize, y: usize }{
                .{ .x = x, .y = y + 1 }, // down
                .{ .x = x -% 1, .y = y + 1 }, // down-left
                .{ .x = x + 1, .y = y + 1 }, // down-right
            };

            for (targets) |t| {
                if (!self.insideMap(t.x, t.y)) continue;
                if (self.state.map[t.y][t.x].type != CellType.none) continue;

                self.state.map[y][x].type = CellType.none;
                self.state.map[t.y][t.x].type = CellType.sand;
                self.state.map[t.y][t.x].dirty = true;
                return;
            }
        }

        fn water(self: *Self, x: usize, y: usize) void {
            const targets = [_]struct { x: usize, y: usize }{
                .{ .x = x, .y = y + 1 }, // down
                .{ .x = x -% 1, .y = y + 1 }, // down-left
                .{ .x = x + 1, .y = y + 1 }, // down-right
                .{ .x = x -% 1, .y = y }, // left
                .{ .x = x + 1, .y = y }, // right
            };

            for (targets) |t| {
                if (!self.insideMap(t.x, t.y)) continue;
                if (self.state.map[t.y][t.x].type != CellType.none) continue;

                self.state.map[y][x].type = CellType.none;
                self.state.map[t.y][t.x].type = CellType.water;
                self.state.map[t.y][t.x].dirty = true;
                return;
            }

            // TODO - Consider for left and right using a 3x3 neighbourhood... Perhaps this would be enough
            // info to prevent sliding back and forth constantly.
        }
    };
}
