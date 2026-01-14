package main

import "core:fmt"
import "core:os"
import sdl "vendor:sdl3"

TICKS_PER_FRAME :: 10

// odinfmt: disable
KEY_MAP := [16]sdl.Keycode {
	sdl.K_X,
	sdl.K_1,
	sdl.K_2,
	sdl.K_3,
	sdl.K_Q,
	sdl.K_W,
	sdl.K_E,
	sdl.K_A,
	sdl.K_S,
	sdl.K_D,
	sdl.K_Z,
	sdl.K_C,
	sdl.K_4,
	sdl.K_R,
	sdl.K_F,
	sdl.K_V,
}
// odinfmt: enable

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

	if !sdl.Init({.VIDEO}) {
		fmt.eprintf("sdl init failed: %v\n", sdl.GetError())
		return
	}
	defer sdl.Quit()

	window := sdl.CreateWindow("chip8", WINDOW_WIDTH, WINDOW_HEIGHT, {})
	if window == nil {
		fmt.eprintf("failed to create window: %v\n", sdl.GetError())
		return
	}
	defer sdl.DestroyWindow(window)

	renderer := sdl.CreateRenderer(window, nil)
	if renderer == nil {
		fmt.eprintf("failed to create renderer: %v\n", sdl.GetError())
		return
	}
	defer sdl.DestroyRenderer(renderer)

	sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)

	event: sdl.Event
	running := true

	for running {
		for sdl.PollEvent(&event) {
			#partial switch event.type {
			case .QUIT:
				running = false
			case .WINDOW_CLOSE_REQUESTED:
				running = false
			case .KEY_DOWN:
				if event.key.key == sdl.K_ESCAPE {
					running = false
				}

				for key, i in KEY_MAP {
					if event.key.key == key {
						keypress(&chip8, u8(i), true)
					}
				}
			case .KEY_UP:
				for key, i in KEY_MAP {
					if event.key.key == key {
						keypress(&chip8, u8(i), false)
					}
				}
			}
		}

		for _ in 0 ..< TICKS_PER_FRAME {
			tick(&chip8)
		}

		tick_timers(&chip8)

		sdl.SetRenderDrawColor(renderer, 0, 0, 0, 255)
		sdl.RenderClear(renderer)

		sdl.SetRenderDrawColor(renderer, 255, 255, 255, 255)

		screen_buffer := get_display(&chip8)

		for pixel, i in screen_buffer {
			if pixel {
				x := (i % SCREEN_WIDTH)
				y := (i / SCREEN_WIDTH)
				rect := sdl.FRect{f32(x * SCALE), f32(y * SCALE), f32(SCALE), f32(SCALE)}
				sdl.RenderFillRect(renderer, &rect)
			}
		}

		sdl.RenderPresent(renderer)

		sdl.DelayNS(16_666_667)
	}
}
