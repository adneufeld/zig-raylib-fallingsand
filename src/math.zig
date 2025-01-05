pub fn pointInCircle(xCenter: f32, yCenter: f32, radius: f32, x: f32, y: f32) bool {
    const xDiff = x - xCenter;
    const yDiff = y - yCenter;
    const distance = @sqrt(xDiff * xDiff + yDiff * yDiff);
    return distance <= radius;
}
