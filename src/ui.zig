const std = @import("std");
const rl = @import("raylib");
const sim = @import("./sim.zig");
const cmd = @import("./cmd.zig");
const ds = @import("./datastructs.zig");
const state = @import("./state.zig");

const time = std.time;
const Instant = time.Instant;
const CellType = sim.CellType;
const GameState = state.GameState;

pub const UIState = struct {};

pub const Cursor = enum {
    none,
    addCells,
};

pub const UISystem = struct {
    state: *GameState,

    drawCursor: bool = false,
    cursorRadius: f32 = 14,
    cursorType: CellType = CellType.none,
    cursorDensity: f32 = 1.0,

    mouseRepeatNs: u64 = 10 * time.ns_per_ms,
    mouseRepeat: ?Instant = null,

    keyRepeat: ?Instant = null,
    keyRepeatValue: rl.KeyboardKey = .key_null,
    keyRepeatNs: u64 = 75 * time.ns_per_ms,

    const infoTextSize = 16;
    const backgroundColor = rl.Color.init(0, 0, 0, 255 / 2);
    const addDensity = 0.25;
    const solidDensity = 1.0;

    pub fn init(s: *GameState) UISystem {
        return UISystem{
            .state = s,
        };
    }

    pub fn update(self: *UISystem, elapsed: u64) !void {
        _ = elapsed;

        if (self.mouseRepeat) |mouseRepeat| {
            if ((try time.Instant.now()).since(mouseRepeat) >= self.mouseRepeatNs) {
                self.addCellsCmd();
                self.mouseRepeat = try Instant.now();
            }
        }

        if (self.keyRepeat) |keyRepeat| {
            if ((try time.Instant.now()).since(keyRepeat) >= self.keyRepeatNs) {
                self.keyRepeat = try Instant.now();
                if (self.cursorRadius < 40 and self.keyRepeatValue == .key_equal) {
                    self.cursorRadius += 2;
                } else if (self.cursorRadius > 10 and self.keyRepeatValue == .key_minus) {
                    self.cursorRadius -= 2;
                }
            }
        }
    }

    pub fn input(self: *UISystem) !void {
        // const leftPressed = rl.isMouseButtonPressed(rl.MouseButton.mouse_button_left);
        // const leftReleased = rl.isMouseButtonReleased(rl.MouseButton.mouse_button_left);
        // const leftDown = rl.isMouseButtonDown(rl.MouseButton.mouse_button_left);
        // const leftUp = rl.isMouseButtonUp(rl.MouseButton.mouse_button_left);

        // // There is a weird issue in Raylib where mouse inputs are missed when they
        // // occur immediately after (~0.5s) a key press... So switching cursor type then
        // // clicking with miss both the press and release for that click.

        // std.log.debug(
        //     "pressed: {}, released: {}, down: {}, up: {}",
        //     .{ leftPressed, leftReleased, leftDown, leftUp },
        // );

        if (self.cursorType != CellType.none and
            rl.isMouseButtonPressed(.mouse_button_left))
        {
            self.mouseRepeat = try Instant.now();
        }

        if (rl.isMouseButtonReleased(.mouse_button_left)) {
            self.mouseRepeat = null;
        }

        if (rl.isKeyPressed(rl.KeyboardKey.key_escape)) {
            self.drawCursor = false;
            self.cursorType = CellType.none;
            self.mouseRepeat = null;
        }

        const ctrlPressed = rl.isKeyDown(.key_left_control) or rl.isKeyDown(.key_right_control);

        if (!ctrlPressed and rl.isKeyPressed(.key_s)) {
            self.drawCursor = true;
            self.cursorType = CellType.sand;
            self.cursorDensity = addDensity;
        }
        if (ctrlPressed and rl.isKeyPressed(.key_s)) {
            self.drawCursor = true;
            self.cursorType = CellType.sand_spout;
            self.cursorDensity = solidDensity;
        }

        if (!ctrlPressed and rl.isKeyPressed(.key_w)) {
            self.drawCursor = true;
            self.cursorType = CellType.water;
            self.cursorDensity = addDensity;
        }
        if (ctrlPressed and rl.isKeyPressed(.key_w)) {
            self.drawCursor = true;
            self.cursorType = CellType.water_spout;
            self.cursorDensity = solidDensity;
        }

        if (!ctrlPressed and rl.isKeyPressed(.key_r)) {
            self.drawCursor = true;
            self.cursorType = CellType.rock;
            self.cursorDensity = solidDensity;
        }

        if (!ctrlPressed and rl.isKeyPressed(.key_e)) {
            self.drawCursor = true;
            self.cursorType = .erase;
            self.cursorDensity = solidDensity;
        }

        if (rl.isKeyPressed(.key_minus)) {
            self.keyRepeat = try Instant.now();
            self.keyRepeatValue = .key_minus;
        }
        if (rl.isKeyPressed(.key_equal)) { // lowercase for +
            self.keyRepeat = try Instant.now();
            self.keyRepeatValue = .key_equal;
        }
        if (rl.isKeyReleased(.key_minus) or rl.isKeyReleased(.key_equal)) {
            self.keyRepeat = null;
            self.keyRepeatValue = .key_null;
        }
    }

    pub fn draw(self: *UISystem) void {
        const keyText = "[Ctrl+] Emitter   [S]and   [W]ater   [R]ock   [E]rase   [+][-] Brush Size   [Esc] Clear Cursor";
        const txtLen = rl.measureText(keyText, infoTextSize);
        const textX = self.state.screenWidth / 2 - @divFloor(txtLen, 2);
        const textY = self.state.screenHeight - infoTextSize;

        rl.drawRectangle(
            textX - 5,
            textY - 5,
            txtLen + 10,
            infoTextSize + 5,
            backgroundColor,
        );
        rl.drawText(
            keyText,
            textX,
            textY,
            infoTextSize,
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

    fn addCellsCmd(self: *UISystem) void {
        const mousePt = ds.ScreenPoint{
            .x = @intCast(rl.getMouseX()),
            .y = @intCast(rl.getMouseY()),
        };
        const mapPt = ds.screenToMap(self.state.tileSize, mousePt);
        self.state.cmd.queue.push(cmd.Cmd{
            .addCells = cmd.AddCellsCmd{
                .type = if (self.cursorType == .erase) .none else self.cursorType, // special case for erase
                .pt = mapPt,
                .radius = @intFromFloat(self.cursorRadius),
                .density = self.cursorDensity,
            },
        });
    }
};
