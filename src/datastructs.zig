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

pub const ScreenPoint = Point(i16);
pub const MapPoint = Point(i16);

fn Point(comptime T: type) type {
    return struct {
        const Self = @This();

        x: T,
        y: T,

        pub fn sub(self: Self, pt2: Self) Self {
            return Self{
                .x = self.x -% pt2.x,
                .y = self.y -% pt2.y,
            };
        }

        pub fn add(self: Self, pt2: Self) Self {
            return Self{
                .x = self.x +% pt2.x,
                .y = self.y +% pt2.y,
            };
        }

        pub fn isInRect(self: Self, x: T, y: T, width: usize, height: usize) bool {
            const tWidth: T = @intCast(width);
            const tHeight: T = @intCast(height);
            return self.x >= x and self.x < x + tWidth and
                self.y >= y and self.y < y + tHeight;
        }
    };
}

pub fn screenToMap(tileSize: u8, sPt: ScreenPoint) MapPoint {
    const iTileSize: i16 = @intCast(tileSize);
    return MapPoint{
        .x = @divTrunc(sPt.x, iTileSize),
        .y = @divTrunc(sPt.y, iTileSize),
    };
}

pub fn RingBuffer(comptime T: type, capacity: usize) type {
    return struct {
        const Self = @This();

        capacity: usize = capacity,
        items: [capacity]T = undefined,
        count: usize = 0, // total items put in
        nextIdx: usize = 0, // the location for the next item, also the oldest item when count == capacity

        pub fn put(self: *Self, item: T) void {
            self.items[self.nextIdx] = item;
            self.nextIdx = (self.nextIdx + 1) % self.capacity;
            if (self.count < self.capacity) self.count += 1;
        }
    };
}

test "RingBuffer" {
    var rb = RingBuffer(i32, 5){};

    rb.put(1);
    rb.put(2);
    rb.put(3);
    try expectEqual(rb.count, 3);

    rb.put(4);
    rb.put(5);

    rb.put(6);
    try expectEqual(rb.items[0], 6);
    try expectEqual(rb.count, rb.capacity);

    rb.put(7);
    try expectEqual(rb.items[1], 7);
    try expectEqual(rb.count, rb.capacity);
}
