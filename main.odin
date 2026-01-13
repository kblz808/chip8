package main

import "core:fmt"
import "core:os"
import rl "vendor:raylib"

TICKS_PER_FRAME :: 10

KEY_MAP := [16]rl.KeyboardKey {
	rl.KeyboardKey.X,
	rl.KeyboardKey.ONE,
	rl.KeyboardKey.TWO,
	rl.KeyboardKey.THREE,
	rl.KeyboardKey.Q,
	rl.KeyboardKey.W,
	rl.KeyboardKey.E,
	rl.KeyboardKey.A,
	rl.KeyboardKey.S,
	rl.KeyboardKey.D,
	rl.KeyboardKey.Z,
	rl.KeyboardKey.C,
	rl.KeyboardKey.FOUR,
	rl.KeyboardKey.R,
	rl.KeyboardKey.F,
	rl.KeyboardKey.V,
}

main :: proc() {
	args := os.args
	if len(args) != 2 {
		fmt.println("usage: chip8 path/to/game")
		return
	}

	chip8 := NewChip8()

	data, ok := os.read_entire_file(args[1])
	if !ok {
		fmt.println("failed to load rom data")
		return
	}
	defer delete(data)

	load(&chip8, data)
	fmt.println("game loaded")

	rl.InitWindow(WINDOW_WIDTH, WINDOW_HEIGHT, "chip8")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)


	for !rl.WindowShouldClose() {
		for key, i in KEY_MAP {
			is_down := rl.IsKeyDown(key)
			if chip8.keys[i] != is_down {
				keypress(&chip8, u8(i), is_down)
			}
		}

		for _ in 0 ..< TICKS_PER_FRAME {
			tick(&chip8)
		}

		tick_timers(&chip8)
		draw_screen(&chip8)
	}
}

draw_screen :: proc(chip8: ^Chip8) {
	rl.BeginDrawing()
	rl.DrawFPS(0, 0)

	rl.ClearBackground(rl.Color{0, 0, 0, 0})

	screen_buffer := get_display(chip8)

	for pixel, i in screen_buffer {
		if pixel {
			x := (i % SCREEN_WIDTH)
			y := (i / SCREEN_WIDTH)
			rect := rl.Rectangle{f32(x * SCALE), f32(y * SCALE), f32(SCALE), f32(SCALE)}
			rl.DrawRectangleRec(rect, rl.Color{255, 255, 255, 255})
		}
	}

	rl.EndDrawing()
}
