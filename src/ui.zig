const rl = @import("raylib");
const sim = @import("./sim.zig");
const cmd = @import("./cmd.zig");
const ds = @import("./datastructs.zig");

const CellType = sim.CellType;

pub const UIState = struct {};

pub const Cursor = enum {
    none,
    addCells,
};

pub fn UISystem(comptime S: type) type {
    return struct {
        const Self = @This();

        state: *S,

        drawCursor: bool = false,
        cursorRadius: f32 = 20,
        cursorType: CellType = CellType.none,
        keyTextSize: i32 = 18,

        const backgroundColor = rl.Color.init(0, 0, 0, 255 / 2);

        pub fn init(state: *S) Self {
            return Self{
                .state = state,
            };
        }

        pub fn update(self: *Self, elapsed: u64) void {
            _ = self;
            _ = elapsed;
        }

        pub fn input(self: *Self) void {
            if (self.cursorType != CellType.none and rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
                const mousePt = ds.ScreenPoint{
                    .x = @intCast(rl.getMouseX()),
                    .y = @intCast(rl.getMouseY()),
                };
                const mapPt = ds.screenToMap(self.state.tileSize, mousePt);
                self.state.cmd.queue.push(cmd.Cmd{ .addCells = cmd.AddCellsCmd{
                    .type = self.cursorType,
                    .pt = mapPt,
                    .radius = @intFromFloat(self.cursorRadius),
                } });
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
                self.drawCursor = false;
                self.cursorType = CellType.none;
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_s)) {
                self.drawCursor = true;
                self.cursorType = CellType.sand;
            } else if (rl.isKeyPressed(rl.KeyboardKey.key_w)) {
                self.drawCursor = true;
                self.cursorType = CellType.water;
            }
        }

        pub fn draw(self: *Self) void {
            const keyText = "[S]and  [W]ater [Esc]Clear";
            const txtLen = rl.measureText(keyText, self.keyTextSize);
            const textX = self.state.screenWidth / 2 - @divFloor(txtLen, 2);
            const textY = self.state.screenHeight - self.keyTextSize;

            rl.drawRectangle(
                textX - 5,
                textY - 5,
                txtLen + 10,
                self.keyTextSize + 5,
                backgroundColor,
            );
            rl.drawText(
                keyText,
                textX,
                textY,
                self.keyTextSize,
                rl.Color.white,
            );

            if (self.drawCursor and rl.isCursorOnScreen()) {
                const mx = rl.getMouseX();
                const my = rl.getMouseY();
                var color = self.cursorType.color();
                color.a /= 2;
                rl.drawCircle(mx, my, self.cursorRadius, color);
            }
        }
    };
}
