const std = @import("std");
const rl = @import("raylib");
const sim = @import("./sim.zig");
const cmd = @import("./cmd.zig");
const ds = @import("./datastructs.zig");

const time = std.time;
const Instant = time.Instant;
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
        cursorRepeatNs: u64 = 50 * time.ns_per_ms,
        lastRepeat: ?Instant = null,
        keyTextSize: i32 = 18,

        const backgroundColor = rl.Color.init(0, 0, 0, 255 / 2);

        pub fn init(state: *S) Self {
            return Self{
                .state = state,
            };
        }

        pub fn update(self: *Self, elapsed: u64) !void {
            _ = elapsed;

            if (self.lastRepeat) |lastRepeat| {
                if ((try time.Instant.now()).since(lastRepeat) >= self.cursorRepeatNs) {
                    self.addCellsCmd();
                    self.lastRepeat = try Instant.now();
                }
            }
        }

        pub fn input(self: *Self) !void {
            const leftPressed = rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left);
            const leftReleased = rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left);
            const leftDown = rl.isMouseButtonDown(rl.MouseButton.mouse_button_left);
            const leftUp = rl.isMouseButtonUp(rl.MouseButton.mouse_button_left);

            // There is a weird issue in Raylib where mouse inputs are missed when they
            // occur immediately after (~0.5s) a key press... So switching cursor type then
            // clicking with miss both the press and release for that click.

            std.log.debug(
                "pressed: {}, released: {}, down: {}, up: {}",
                .{ leftPressed, leftReleased, leftDown, leftUp },
            );

            if (self.cursorType != CellType.none and
                rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left))
            {
                self.lastRepeat = try Instant.now();
                self.addCellsCmd();
            }

            if (rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left)) {
                self.lastRepeat = null;
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
                self.drawCursor = false;
                self.cursorType = CellType.none;
                self.lastRepeat = null;
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_s)) {
                self.drawCursor = true;
                self.cursorType = CellType.sand;
            }

            if (rl.isKeyPressed(rl.KeyboardKey.key_w)) {
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
            rl.drawFPS(0, 0);

            if (self.drawCursor and rl.isCursorOnScreen()) {
                const mx = rl.getMouseX();
                const my = rl.getMouseY();
                var color = self.cursorType.color();
                color.a /= 2;
                rl.drawCircle(mx, my, self.cursorRadius, color);
            }
        }

        fn addCellsCmd(self: *Self) void {
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
    };
}
