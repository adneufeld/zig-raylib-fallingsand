const ds = @import("./datastructs.zig");
const state = @import("./state.zig");
const sim = @import("./sim.zig");

const CmdQueue = ds.DropQueue(Cmd, 8);
const GameState = state.GameState;
const CellType = sim.CellType;
const PointU16 = ds.PointU16;

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
};

pub const AddCellsCmd = struct {
    radius: f32,
    pt: PointU16,
    type: CellType,

    pub fn execute(s: *GameState) void {
        _ = s;
    }
};
