package main

import (
	"fmt"
	"image"
	"image/color"
	"log"
	"os"

	"github.com/ebitengine/debugui"
	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
	"github.com/hajimehoshi/ebiten/v2/vector"
)

const TICKS_PER_FRAME = 10

type Emulator struct {
	debugui debugui.DebugUI
	chip8   *Chip8
}

var KEY_MAP = [16]ebiten.Key{
	ebiten.KeyX,
	ebiten.Key1,
	ebiten.Key2,
	ebiten.Key3,
	ebiten.KeyQ,
	ebiten.KeyW,
	ebiten.KeyE,
	ebiten.KeyA,
	ebiten.KeyS,
	ebiten.KeyD,
	ebiten.KeyZ,
	ebiten.KeyC,
	ebiten.Key4,
	ebiten.KeyR,
	ebiten.KeyF,
	ebiten.KeyV,
}

func (e *Emulator) Update() error {
	if ebiten.IsKeyPressed(ebiten.KeyEscape) {
		// stop game
	}

	for i, key := range KEY_MAP {
		if inpututil.IsKeyJustPressed(key) {
			e.chip8.KeyPress(uint8(i), true)
		}

		if inpututil.IsKeyJustReleased(key) {
			e.chip8.KeyPress(uint8(i), false)
		}
	}

	// for i := 0; i <= TICKS_PER_FRAME; i++ {
	// 	e.chip8.tick()
	// }

	op := e.chip8.fetch()

	if _, err := e.debugui.Update(func(ctx *debugui.Context) error {
		ctx.Window("debug", image.Rect(WINDOW_WIDTH+20, 10, 760, 500), func(layout debugui.ContainerLayout) {
			ctx.Header("info", true, func() {
				ctx.Text(fmt.Sprintf("FPS: %0.2f", ebiten.ActualFPS()))
				ctx.Text(fmt.Sprintf("PC: %x", e.chip8.program_counter))
				ctx.Text(fmt.Sprintf("OPCODE: %x", op))
			})

			ctx.Header("v-reg", true, func() {
				ctx.SetGridLayout([]int{-1, -1, -1, -1}, nil)
				for i, v := range e.chip8.v_reg {
					ctx.Text(fmt.Sprintf("%x - %x", i, v))
				}
			})

			ctx.Header("stack", true, func() {
				ctx.SetGridLayout([]int{-1, -1, -1, -1}, nil)
				for i, v := range e.chip8.stack {
					ctx.Text(fmt.Sprintf("%x - %x", i, v))
				}
			})

		})

		// ctx.Window("v-reg", image.Rect(WINDOW_WIDTH+100, 10, 260, 400), func(layout debugui.ContainerLayout) {
		// 	for i, v := range e.chip8.v_reg {
		// 		ctx.Text(fmt.Sprintf("reg: %d - %x", i, v))
		// 	}
		// })

		return nil
	}); err != nil {
		return err
	}

	e.chip8.execute(op)

	e.chip8.tick_timers()

	return nil
}

func (e *Emulator) Layout(outsideWidth, outsideHeight int) (int, int) {
	return WINDOW_WIDTH * 4, WINDOW_HEIGHT * 4
}

func (e *Emulator) Draw(screen *ebiten.Image) {
	screen.Fill(color.Black)

	screen_buffer := e.chip8.get_display()

	for i, pixel := range screen_buffer {
		if pixel {
			x := (i % SCREEN_WIDTH)
			y := (i / SCREEN_WIDTH)
			vector.FillRect(screen, float32(x*SCALE), float32(y*SCALE), float32(SCALE), float32(SCALE), color.White, false)
		}
	}

	e.debugui.Draw(screen)
}

func main() {
	args := os.Args
	if len(args) != 2 {
		log.Println("usage: chip8 path/to/game")
		return
	}

	chip8 := NewChip8()

	data, err := os.ReadFile(args[1])
	if err != nil {
		log.Println("failed to load rom data")
		return
	}

	chip8.Load(data)
	log.Println("game loaded")

	ebiten.SetWindowSize(WINDOW_WIDTH*4, WINDOW_HEIGHT*4)
	ebiten.SetWindowTitle("chip8 visualizer")

	// ebiten.SetVsyncEnabled(false)
	// ebiten.SetTPS(1)

	emulator := Emulator{debugui.DebugUI{}, &chip8}

	if err := ebiten.RunGame(&emulator); err != nil {
		log.Fatal(err)
	}
}
