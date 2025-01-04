const std = @import("std");
const rl = @import("raylib");
const state = @import("./state.zig");

const Instant = std.time.Instant;
const CellSimTick = std.EnumArray(CellType, bool);

const GameState = state.GameState;

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
            else => 5 * std.time.ns_per_ms,
        };
    }

    pub fn density(self: CellType) u8 {
        return switch (self) {
            CellType.none => 255,
            CellType.water => 150,
            CellType.sand => 200,
        };
    }
};

pub const CellularAutomata = struct {
    state: *GameState,
    leftToRight: bool = false,

    pub fn init(s: *GameState) CellularAutomata {
        return CellularAutomata{
            .state = s,
        };
    }

    pub fn simulate(self: *CellularAutomata, elapsed: u64) !void {
        var simThisTick: CellSimTick = self.doesCellSimulateThisTick(elapsed);

        // do the simulation bottom to top for falling cells
        var h: i32 = @as(i32, self.state.mapHeight) - 1;
        while (h >= 0) : (h -= 1) {
            const hInd: usize = @intCast(h);

            const ltr = (hInd % 2) == 0;
            for (0..self.state.mapWidth) |w| {
                // alternate left-to-right and right-to-left to partially resolve the left-bias
                const wInd = if (ltr) w else self.state.mapWidth - 1 - w;
                const cell = self.state.map[hInd][wInd];

                if (!simThisTick.get(cell.type) or cell.dirty) continue;

                // simulate density
                if (self.insideMap(wInd, hInd + 1) and
                    cell.type.density() > self.state.map[hInd + 1][wInd].type.density())
                {
                    self.swapCell(wInd, hInd, wInd, hInd + 1);
                }

                // simulate cell types
                switch (cell.type) {
                    CellType.sand => self.sand(wInd, hInd),
                    CellType.water => self.water(wInd, hInd),
                    CellType.none => continue,
                }
            }
        }
    }

    // Whether each cell type should simulate their cellular automata on this specific update tick
    fn doesCellSimulateThisTick(self: *CellularAutomata, elapsed: u64) CellSimTick {
        var simThisTick = CellSimTick.initFill(false);
        var it = simThisTick.iterator();
        while (it.next()) |entry| {
            const cell = entry.key;
            const cellLastTick = self.state.lastTick.get(cell);
            const cellFreq = cell.freq(); // TODO consider scaling the freq/speed based on the tile size
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

    pub fn insideMap(self: *CellularAutomata, x: usize, y: usize) bool {
        return x >= 0 and x <= self.state.mapWidth - 1 and
            y >= 0 and y <= self.state.mapHeight - 1;
    }

    // swap two cells with non-none types
    fn swapCell(self: *CellularAutomata, x1: usize, y1: usize, x2: usize, y2: usize) void {
        if (!self.insideMap(x1, y1) or self.state.map[y1][x1].type == CellType.none) return;
        if (!self.insideMap(x2, y2) or self.state.map[y2][x2].type == CellType.none) return;

        const topCell = self.state.map[y1][x1];
        self.state.map[y1][x1] = self.state.map[y2][x2];
        self.state.map[y2][x2] = topCell;

        self.state.map[y1][x1].dirty = true;
        self.state.map[y2][x2].dirty = true;
    }

    // move a non-none cell into an empty (none) cell
    fn moveCell(self: *CellularAutomata, x1: usize, y1: usize, x2: usize, y2: usize) void {
        if (self.state.map[y2][x2].type != CellType.none) {
            @panic("cannot moveCell into a non-none cell");
        }

        self.state.map[y2][x2] = self.state.map[y1][x1];
        self.state.map[y2][x2].dirty = true;
        self.state.map[y1][x1].type = CellType.none;
        self.state.map[y1][x1].dirty = true;
    }

    fn sand(self: *CellularAutomata, x: usize, y: usize) void {
        const targets = [3]struct { x: usize, y: usize }{
            .{ .x = x, .y = y + 1 }, // down
            .{ .x = x -% 1, .y = y + 1 }, // down-left
            .{ .x = x + 1, .y = y + 1 }, // down-right
        };

        for (targets) |t| {
            if (!self.insideMap(t.x, t.y)) continue;

            const targetHasCell = self.state.map[t.y][t.x].type != CellType.none;
            const targetIsLowerDensity = CellType.sand.density() > self.state.map[t.y][t.x].type.density();

            if (targetHasCell and !targetIsLowerDensity) continue;

            if (targetHasCell and targetIsLowerDensity) {
                self.swapCell(x, y, t.x, t.y);
            } else {
                self.moveCell(x, y, t.x, t.y);
            }

            return;
        }
    }

    fn water(self: *CellularAutomata, x: usize, y: usize) void {
        const targets = [_]struct { x: usize, y: usize }{
            .{ .x = x, .y = y + 1 }, // down
            .{ .x = x -% 1, .y = y + 1 }, // down-left
            .{ .x = x + 1, .y = y + 1 }, // down-right
            .{ .x = x -% 1, .y = y }, // left
            .{ .x = x + 1, .y = y }, // right
        };

        // TODO there is still a problem where water doesn't move rightwards correctly because of the left target
        // occurring first in the targets list. The first update tick moves the cell rightward, then the next
        // update tick moves them back leftward. We may need to store a small "direction" value on the cell struct
        // and attempt to maintain the current direction when both left & right are available.
        //
        // This further reinforces how we move cells left and right awkwardly with gaps in between due to the
        // order of updates and the dirty flag. Perhaps this could be improved with a double buffer system...

        for (targets) |t| {
            if (!self.insideMap(t.x, t.y)) continue;

            const targetHasCell = self.state.map[t.y][t.x].type != CellType.none;
            const targetIsLowerDensity = CellType.water.density() > self.state.map[t.y][t.x].type.density();

            if (targetHasCell and !targetIsLowerDensity) continue;

            if (targetHasCell and targetIsLowerDensity) {
                self.swapCell(x, y, t.x, t.y);
            } else {
                self.moveCell(x, y, t.x, t.y);
            }

            return;
        }
    }
};
