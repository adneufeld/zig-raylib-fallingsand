# zig-raylib-fallingsand

This project is a simple simulation game in the classic [Falling Sand genre](https://en.wikipedia.org/wiki/Falling-sand_game).

The goal of this project was to learn to use both the Zig language and the game framework [Raylib](https://www.raylib.com/).

A small amount of performance optimization was done on this by writing pixel color changes to a texture rather than drawing directly to the screen. This allows the simulation to run at a smooth 60 FPS even for small pixels and larger screen sizes. 

## Demo

![Falling Sand GIF](https://github.com/adneufeld/zig-raylib-fallingsand/blob/master/res/zig-falling-sand_2025-01.gif?raw=true)
