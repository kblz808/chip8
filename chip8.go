package main

import "math/rand"

var FONTSET = [80]uint8{
	0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
	0x20, 0x60, 0x20, 0x20, 0x70, // 1
	0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
	0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
	0x90, 0x90, 0xF0, 0x10, 0x10, // 4
	0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
	0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
	0xF0, 0x10, 0x20, 0x40, 0x40, // 7
	0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
	0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
	0xF0, 0x90, 0xF0, 0x90, 0x90, // A
	0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
	0xF0, 0x80, 0x80, 0x80, 0xF0, // C
	0xE0, 0x90, 0x90, 0x90, 0xE0, // D
	0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
	0xF0, 0x80, 0xF0, 0x80, 0x80, // F
}

const SCREEN_WIDTH = 64
const SCREEN_HEIGHT = 32
const START_ADDR = 0x200
const MEMORY_SIZE = 4096
const SCALE = 5
const WINDOW_WIDTH = SCREEN_WIDTH * SCALE
const WINDOW_HEIGHT = SCREEN_HEIGHT * SCALE

type Chip8 struct {
	program_counter uint16
	memory          [MEMORY_SIZE]uint8
	screen          [SCREEN_WIDTH * SCREEN_HEIGHT]bool
	v_reg           [16]uint8
	i_reg           uint16
	stack           [16]uint16
	stack_pointer   uint16
	keys            [16]bool
	delay_timer     uint8
	sound_timer     uint8
}

func NewChip8() Chip8 {
	chip8 := Chip8{
		program_counter: START_ADDR,
		memory:          [MEMORY_SIZE]uint8{},
		screen:          [SCREEN_WIDTH * SCREEN_HEIGHT]bool{},
		v_reg:           [16]uint8{},
		i_reg:           0,
		stack:           [16]uint16{},
		stack_pointer:   0,
		keys:            [16]bool{},
		delay_timer:     0,
		sound_timer:     0,
	}

	copy(chip8.memory[:80], FONTSET[:])

	return chip8
}

func (c *Chip8) reset() {
	c.program_counter = START_ADDR
	c.memory = [MEMORY_SIZE]uint8{}
	c.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
	c.v_reg = [16]uint8{}
	c.i_reg = 0
	c.stack = [16]uint16{}
	c.stack_pointer = 0
	c.keys = [16]bool{}
	c.delay_timer = 0
	c.sound_timer = 0

	copy(c.memory[:80], FONTSET[:])
}

func (c *Chip8) push(value uint16) {
	c.stack[c.stack_pointer] = value
	c.stack_pointer += 1
}

func (c *Chip8) pop() uint16 {
	c.stack_pointer -= 1
	return c.stack[c.stack_pointer]
}

func (c *Chip8) tick() {
	op := c.fetch()
	c.execute(op)
}

func (c *Chip8) fetch() uint16 {
	higher_byte := uint16(c.memory[c.program_counter])
	lower_byte := uint16(c.memory[c.program_counter+1])

	op := (higher_byte << 8) | lower_byte

	c.program_counter += 2

	return op
}

func (c *Chip8) execute(op uint16) {
	digit1 := (op & 0xF000) >> 12
	digit2 := (op & 0x0F00) >> 8
	digit3 := (op & 0x00F0) >> 4
	digit4 := (op & 0x000F)

	switch digit1 {
	case 0x0:
		switch op & 0x00FF {
		case 0x00:
			// 0000:
			return
		case 0xE0:
			// 00E0:
			c.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
		case 0xEE:
			// 00EE:
			return_address := c.pop()
			c.program_counter = return_address
		}
	case 0x1:
		// 1NNN:
		nnn := op & 0xFFF
		c.program_counter = nnn
	case 0x2:
		// 2NNN:
		nnn := op & 0xFFF
		c.push(c.program_counter)
		c.program_counter = nnn
	case 0x3:
		// 3XNN:
		x := digit2
		nn := uint8(op & 0xFF)
		if c.v_reg[x] == nn {
			c.program_counter += 2
		}
	case 0x4:
		// 4XNN:
		x := digit2
		nn := uint8(op & 0xFF)
		if c.v_reg[x] != nn {
			c.program_counter += 2
		}
	case 0x5:
		// 5XY0:
		x := digit2
		y := digit3
		if c.v_reg[x] == c.v_reg[y] {
			c.program_counter += 2
		}

	case 0x6:
		// 6XNN:
		x := digit2
		nn := uint8(op & 0xFF)
		c.v_reg[x] = nn
	case 0x7:
		// 7XNN
		x := digit2
		nn := uint8(op & 0xFF)
		c.v_reg[x] += nn
	case 0x8:
		switch digit4 {
		case 0x0:
			// 8XY0:
			x := digit2
			y := digit3
			c.v_reg[x] = c.v_reg[y]
		case 0x1:
			// 8XY1: OR
			x := digit2
			y := digit3
			c.v_reg[x] |= c.v_reg[y]
		case 0x2:
			// 8XY2: AND
			x := digit2
			y := digit3
			c.v_reg[x] &= c.v_reg[y]
		case 0x3:
			// 8XY3: XOR
			x := digit2
			y := digit3
			c.v_reg[x] ^= c.v_reg[y]
		case 0x4:
			// 8XY4: ADD
			x := digit2
			y := digit3
			sum := uint16(c.v_reg[x]) + uint16(c.v_reg[y])
			c.v_reg[x] = uint8(sum)
			c.v_reg[0xF] = uint8(b2u8(sum > 255))
		case 0x5:
			// 8XY5:
			x := digit2
			y := digit3
			c.v_reg[0xF] = b2u8(c.v_reg[x] >= c.v_reg[y])
			c.v_reg[x] -= c.v_reg[y]
		case 0x6:
			// 8XY6:
			x := digit2
			lsb := c.v_reg[x] & 0x1
			c.v_reg[x] >>= 1
			c.v_reg[0xF] = lsb
		case 0x7:
			// 8XY7:
			x := digit2
			y := digit3
			c.v_reg[0xF] = b2u8(c.v_reg[y] >= c.v_reg[x])
			c.v_reg[x] = c.v_reg[y] - c.v_reg[x]
		case 0xE:
			// 8XYE:
			x := digit2
			msb := (c.v_reg[x] >> 7) & 0x1
			c.v_reg[x] <<= 1
			c.v_reg[0xF] = msb
		}
	case 0x9:
		// 9XY0:
		x := digit2
		y := digit3
		if c.v_reg[x] != c.v_reg[y] {
			c.program_counter += 2
		}
	case 0xA:
		// ANNN:
		nnn := op & 0xFFF
		c.i_reg = nnn
	case 0xB:
		// BNNN:
		nnn := op & 0xFFF
		c.program_counter = uint16(c.v_reg[0]) + nnn
	case 0xC:
		// CXNN:
		x := digit2
		nn := uint8(op & 0xFF)
		rng := uint8(rand.Uint32())
		c.v_reg[x] = rng & nn

	case 0xD:
		// DXYN:
		x_coord := c.v_reg[digit2]
		y_coord := c.v_reg[digit3]

		rows := digit4

		flipped := false

		for y_line := uint16(0); y_line < rows; y_line += 1 {
			addr := (c.i_reg + y_line) % MEMORY_SIZE
			pixels := c.memory[addr]

			for x_line := uint16(0); x_line < 8; x_line += 1 {
				if (pixels & (0x80 >> x_line)) != 0 {
					x := (uint16(x_coord) + x_line) % SCREEN_WIDTH
					y := (uint16(y_coord) + y_line) % SCREEN_HEIGHT

					idx := x + SCREEN_WIDTH*y

					flipped = flipped || c.screen[idx]
					c.screen[idx] = !c.screen[idx]
				}
			}

		}

		if flipped {
			c.v_reg[0xF] = 1
		} else {
			c.v_reg[0xF] = 0
		}
	case 0xE:
		switch op & 0x00FF {
		case 0x9E:
			// EX9E:
			x := digit2
			if c.keys[c.v_reg[x]] {
				c.program_counter += 2
			}
		case 0xA1:
			// EXA1:
			x := digit2
			if !c.keys[c.v_reg[x]] {
				c.program_counter += 2
			}
		}
	case 0xF:
		switch op & 0x00FF {
		case 0x07:
			// FX07:
			x := digit2
			c.v_reg[x] = c.delay_timer
		case 0x0A:
			// FX0A:
			x := digit2
			pressed := false
			for i := uint8(0); i < uint8(len(c.keys)); i += 1 {
				if c.keys[i] {
					c.v_reg[x] = i
					pressed = true
					break
				}
			}
			if !pressed {
				c.program_counter -= 2
			}
		case 0x15:
			// FX15:
			x := digit2
			c.delay_timer = c.v_reg[x]
		case 0x18:
			// FX18:
			x := digit2
			c.sound_timer = c.v_reg[x]
		case 0x1E:
			// FX1E:
			x := digit2
			c.i_reg += uint16(c.v_reg[x])
		case 0x29:
			// FX29:
			x := digit2
			c.i_reg = uint16(c.v_reg[x]) * 5
		case 0x33:
			// FX33:
			x := digit2
			c.memory[c.i_reg] = c.v_reg[x] / 100
			c.memory[c.i_reg+1] = (c.v_reg[x] / 10) % 10
			c.memory[c.i_reg+2] = c.v_reg[x] % 10
		case 0x55:
			// FX55:
			x := digit2
			for i := uint16(0); i <= x; i += 1 {
				c.memory[c.i_reg+i] = c.v_reg[i]
			}
		case 0x65:
			// FX65:
			x := digit2
			for i := uint16(0); i <= x; i += 1 {
				c.v_reg[i] = c.memory[c.i_reg+i]
			}
		}
	}

}

func (c *Chip8) tick_timers() {
	if c.delay_timer > 0 {
		c.delay_timer -= 1
	}

	if c.sound_timer > 0 {
		if c.sound_timer == 1 {
			// beep
		}
		c.sound_timer -= 1
	}

}

func (c *Chip8) get_display() []bool {
	return c.screen[:]
}

func (c *Chip8) KeyPress(idx uint8, pressed bool) {
	c.keys[idx] = pressed
}

func (c *Chip8) Load(data []byte) {
	copy(c.memory[START_ADDR:], data[:])
}

func b2u8(b bool) uint8 {
	if b {
		return 1
	}
	return 0
}
