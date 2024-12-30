const std = @import("std");

const expectEqual = std.testing.expectEqual;

// A Queue implementation which silently drops any additional items that are added which are beyond the capacity
pub fn DropQueue(comptime T: type, capacity: usize) type {
    return struct {
        const Self = @This();

        items: [capacity]T = undefined,
        capacity: usize = capacity,
        size: usize = 0,

        pub fn init() Self {
            return Self{};
        }

        // push a new item onto the back
        pub fn push(self: *Self, t: T) void {
            if (self.size + 1 > self.capacity) return;

            self.size += 1;
            self.items[self.size - 1] = t;
        }

        // pop off the next items from the front
        pub fn front(self: *Self) ?T {
            if (self.size <= 0) return null;

            const item = self.items[0];
            self.size -= 1;

            if (self.size == 0) return item;

            // shift all items toward front
            var i: usize = 1;
            while (i <= self.size) : (i += 1) {
                self.items[i - 1] = self.items[i];
            }

            return item;
        }
    };
}

test "DropQueue simple usage" {
    var queue = DropQueue(i32, 5).init();

    queue.push(10);
    queue.push(20);
    try expectEqual(queue.size, 2);

    queue.push(30);
    queue.push(40);
    queue.push(50);
    try expectEqual(queue.size, 5);

    // ensure additional items pushed into the queue are silently dropped
    queue.push(11111);
    try expectEqual(queue.size, 5);

    try expectEqual(queue.front().?, 10);
    try expectEqual(queue.size, 4);
    try expectEqual(queue.front().?, 20);
    try expectEqual(queue.size, 3);
    try expectEqual(queue.front().?, 30);
    try expectEqual(queue.size, 2);
    try expectEqual(queue.front().?, 40);
    try expectEqual(queue.size, 1);
    try expectEqual(queue.front().?, 50);
    try expectEqual(queue.size, 0);

    // ensure front returns null when no items in the queue
    try expectEqual(queue.front(), null);
}

pub const ScreenPoint = Point(u16);
pub const MapPoint = Point(u16);

fn Point(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn sub(self: Self, pt2: Self) Self {
            return Self{
                .x = self.x - pt2.x,
                .y = self.y - pt2.y,
            };
        }

        pub fn add(self: Self, pt2: Self) Self {
            return Self{
                .x = self.x + pt2.x,
                .y = self.y + pt2.y,
            };
        }
    };
}

pub fn screenToMap(tileSize: u8, sPt: ScreenPoint) MapPoint {
    return MapPoint{ .x = sPt.x / tileSize, .y = sPt.y / tileSize };
}
