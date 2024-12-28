const rl = @import("raylib");
const sim = @import("./sim.zig");

pub const UIState = struct {
    cursor: Cursor = Cursor.none,
};

pub const Cursor = enum {
    none,
    addCells,
};

pub fn UISystem(comptime S: type) type {
    return struct {
        const Self = @This();

        state: *S,

        drawCursor: bool = false,
        cursorColor: rl.Color = undefined,
        cursorRadius: f32 = 20,
        keyTextSize: i32 = 18,

        pub fn init(state: *S) Self {
            return Self{
                .state = state,
            };
        }

        pub fn update(self: *Self, elapsed: u64) void {
            _ = elapsed;

            self.input();
        }

        fn input(self: *Self) void {
            if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
                self.drawCursor = false;
                self.cursorColor = undefined;
                self.state.ui.cursor = Cursor.none;
            }
            if (rl.isKeyPressed(rl.KeyboardKey.key_s)) {
                self.drawCursor = true;
                self.cursorColor = sim.CellType.sand.color();
                self.cursorColor.a /= 2;
                self.state.ui.cursor = Cursor.addCells;
            } else if (rl.isKeyPressed(rl.KeyboardKey.key_w)) {
                self.drawCursor = true;
                self.cursorColor = sim.CellType.water.color();
                self.cursorColor.a /= 2;
                self.state.ui.cursor = Cursor.addCells;
            }
        }

        pub fn draw(self: *Self) void {
            const keyText = "[S]and  [W]ater [Esc]Clear";
            const txtLen = rl.measureText(keyText, self.keyTextSize);
            rl.drawText(
                keyText,
                self.state.screenWidth / 2 - @divFloor(txtLen, 2),
                self.state.screenHeight - self.keyTextSize,
                self.keyTextSize,
                rl.Color.white,
            );

            if (self.drawCursor and rl.isCursorOnScreen()) {
                const mx = rl.getMouseX();
                const my = rl.getMouseY();
                rl.drawCircle(mx, my, self.cursorRadius, self.cursorColor);
            }
        }
    };
}
