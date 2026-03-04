package main

import (
	"image/color"
	"log"
	"os"

	"github.com/hajimehoshi/ebiten/v2"
	"github.com/hajimehoshi/ebiten/v2/inpututil"
	"github.com/hajimehoshi/ebiten/v2/vector"
)

const TICKS_PER_FRAME = 10

type Emulator struct {
	chip8 *Chip8
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

	for i := 0; i <= TICKS_PER_FRAME; i++ {
		e.chip8.tick()
	}

	e.chip8.tick_timers()

	return nil
}

func (e *Emulator) Layout(outsideWidth, outsideHeight int) (int, int) {
	return WINDOW_WIDTH, WINDOW_HEIGHT
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

	ebiten.SetWindowSize(WINDOW_WIDTH, WINDOW_HEIGHT)
	ebiten.SetWindowTitle("chip8 visualizer")

	emulator := Emulator{&chip8}

	if err := ebiten.RunGame(&emulator); err != nil {
		log.Fatal(err)
	}
}
