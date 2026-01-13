package main

import "core:math/rand"

// odinfmt: disable
FONTSET := [80]u8 {
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
	0xF0, 0x80, 0xF0, 0x80, 0x80  // F
}
// odinfmt: enable

SCREEN_WIDTH :: 64
SCREEN_HEIGHT :: 32

START_ADDR :: 0x200
MEMORY_SIZE :: 4096
SCALE :: 15
WINDOW_WIDTH :: SCREEN_WIDTH * SCALE
WINDOW_HEIGHT :: SCREEN_HEIGHT * SCALE

Chip8 :: struct {
	program_counter: u16,
	memory:          [MEMORY_SIZE]u8,
	screen:          [SCREEN_WIDTH * SCREEN_HEIGHT]bool,
	v_reg:           [16]u8,
	i_reg:           u16,
	stack:           [16]u16,
	stack_pointer:   u16,
	keys:            [16]bool,
	delay_timer:     u8,
	sound_timer:     u8,
}

NewChip8 :: proc() -> Chip8 {
	chip8 := Chip8 {
		program_counter = START_ADDR,
		memory          = [MEMORY_SIZE]u8{},
		screen          = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{},
		v_reg           = [16]u8{},
		i_reg           = 0,
		stack           = [16]u16{},
		stack_pointer   = 0,
		keys            = [16]bool{},
		delay_timer     = 0,
		sound_timer     = 0,
	}

	copy(chip8.memory[:80], FONTSET[:])

	return chip8
}


reset :: proc(this: ^Chip8) {
	this.program_counter = START_ADDR
	this.memory = [MEMORY_SIZE]u8{}
	this.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
	this.v_reg = [16]u8{}
	this.i_reg = 0
	this.stack = [16]u16{}
	this.stack_pointer = 0
	this.keys = [16]bool{}
	this.delay_timer = 0
	this.sound_timer = 0

	copy(this.memory[:80], FONTSET[:])
}

push :: proc(this: ^Chip8, value: u16) {
	this.stack[this.stack_pointer] = value
	this.stack_pointer += 1
}

pop :: proc(this: ^Chip8) -> u16 {
	this.stack_pointer -= 1
	return this.stack[this.stack_pointer]
}

tick :: proc(this: ^Chip8) {
	op := fetch(this)
	execute(this, op)
}

fetch :: proc(this: ^Chip8) -> u16 {
	higher_byte := u16(this.memory[this.program_counter])
	lower_byte := u16(this.memory[this.program_counter + 1])

	op := (higher_byte << 8) | lower_byte

	this.program_counter += 2

	return op
}

execute :: proc(this: ^Chip8, op: u16) {
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
			this.screen = [SCREEN_WIDTH * SCREEN_HEIGHT]bool{}
		case 0xEE:
			// 00EE:
			return_address := pop(this)
			this.program_counter = return_address
		}
	case 0x1:
		// 1NNN:
		nnn := op & 0xFFF
		this.program_counter = nnn
	case 0x2:
		// 2NNN:
		nnn := op & 0xFFF
		push(this, this.program_counter)
		this.program_counter = nnn
	case 0x3:
		// 3XNN:
		x := digit2
		nn := u8(op & 0xFF)
		if this.v_reg[x] == nn {
			this.program_counter += 2
		}
	case 0x4:
		// 4XNN:
		x := digit2
		nn := u8(op & 0xFF)
		if this.v_reg[x] != nn {
			this.program_counter += 2
		}
	case 0x5:
		// 5XY0:
		x := digit2
		y := digit3
		if this.v_reg[x] == this.v_reg[y] {
			this.program_counter += 2
		}

	case 0x6:
		// 6XNN:
		x := digit2
		nn := u8(op & 0xFF)
		this.v_reg[x] = nn
	case 0x7:
		// 7XNN
		x := digit2
		nn := u8(op & 0xFF)
		this.v_reg[x] = nn
	case 0x8:
		switch digit4 {
		case 0x0:
			// 8XY0:
			x := digit2
			y := digit3
			this.v_reg[x] = this.v_reg[y]
		case 0x1:
			// 8XY1: OR
			x := digit2
			y := digit3
			this.v_reg[x] |= this.v_reg[y]
		case 0x2:
			// 8XY2: AND
			x := digit2
			y := digit3
			this.v_reg[x] &= this.v_reg[y]
		case 0x3:
			// 8XY3: XOR
			x := digit2
			y := digit3
			this.v_reg[x] ~= this.v_reg[y]
		case 0x4:
			// 8XY4: ADD
			x := digit2
			y := digit3
			sum := u16(this.v_reg[x]) + u16(this.v_reg[y])
			this.v_reg[x] = u8(sum)
			this.v_reg[0xF] = u8(sum > 255)
		case 0x5:
			// 8XY5:
			x := digit2
			y := digit3
			this.v_reg[0xF] = u8(this.v_reg[x] >= this.v_reg[y])
			this.v_reg[x] -= this.v_reg[y]
		case 0x6:
			// 8XY6:
			x := digit2
			lsb := this.v_reg[x] & 0x1
			this.v_reg[x] >>= 1
			this.v_reg[0xF] = lsb
		case 0x7:
			// 8XY7:
			x := digit2
			y := digit3
			this.v_reg[0xF] = u8(this.v_reg[y] >= this.v_reg[x])
			this.v_reg[x] = this.v_reg[y] - this.v_reg[x]
		case 0xE:
			// 8XYE:
			x := digit2
			msb := (this.v_reg[x] >> 7) & 0x1
			this.v_reg[x] <<= 1
			this.v_reg[0xF] = msb
		}
	case 0x9:
		// 9XY0:
		x := digit2
		y := digit3
		if this.v_reg[x] != this.v_reg[y] {
			this.program_counter += 2
		}
	case 0xA:
		// ANNN:
		nnn := op & 0xFFF
		this.i_reg = nnn
	case 0xB:
		// BNNN:
		nnn := op & 0xFFF
		this.program_counter = u16(this.v_reg[0]) + nnn
	case 0xC:
		// CXNN:
		x := digit2
		nn := u8(op & 0xFF)
		rng := u8(rand.uint32())
		this.v_reg[x] = rng & nn

	case 0xD:
		// DXYN:
		x_coord := this.v_reg[digit2]
		y_coord := this.v_reg[digit3]

		rows := digit4

		flipped := false

		for y_line := u16(0); y_line < rows; y_line += 1 {
			addr := (this.i_reg + y_line) % MEMORY_SIZE
			pixels := this.memory[addr]

			for x_line := u16(0); x_line < 8; x_line += 1 {
				if (pixels & (0x80 >> x_line)) != 0 {
					x := (u16(x_coord) + x_line) % SCREEN_WIDTH
					y := (u16(y_coord) + y_line) % SCREEN_HEIGHT

					idx := x + SCREEN_WIDTH * y

					flipped |= this.screen[idx]
					this.screen[idx] ~= true
				}
			}

		}

		if flipped {
			this.v_reg[0xF] = 1
		} else {
			this.v_reg[0xF] = 0
		}
	case 0xE:
		switch op & 0x00FF {
		case 0x9E:
			// EX9E:
			x := digit2
			if this.keys[this.v_reg[x]] {
				this.program_counter += 2
			}
		case 0xA1:
			// EXA1:
			x := digit2
			if !this.keys[this.v_reg[x]] {
				this.program_counter += 2
			}
		}
	case 0xF:
		switch op & 0x00FF {
		case 0x07:
			// FX07:
			x := digit2
			this.v_reg[x] = this.delay_timer
		case 0x0A:
			// FX0A:
			x := digit2
			pressed := false
			for i := u8(0); i < len(this.keys); i += 1 {
				if this.keys[i] {
					this.v_reg[x] = i
					pressed = true
					break
				}
			}
			if !pressed {
				this.program_counter -= 2
			}
		case 0x15:
			// FX15:
			x := digit2
			this.delay_timer = this.v_reg[x]
		case 0x18:
			// FX18:
			x := digit2
			this.sound_timer = this.v_reg[x]
		case 0x1E:
			// FX1E:
			x := digit2
			this.i_reg += u16(this.v_reg[x])
		case 0x29:
			// FX29:
			x := digit2
			this.i_reg = u16(this.v_reg[x]) * 5
		case 0x33:
			// FX33:
			x := digit2
			this.memory[this.i_reg] = this.v_reg[x] / 100
			this.memory[this.i_reg + 1] = (this.v_reg[x] / 10) % 10
			this.memory[this.i_reg + 2] = this.v_reg[x] % 10
		case 0x55:
			// FX55:
			x := digit2
			for i := u16(0); i <= x; i += 1 {
				this.memory[this.i_reg + i] = this.v_reg[i]
			}
		case 0x65:
			// FX65:
			x := digit2
			for i := u16(0); i <= x; i += 1 {
				this.v_reg[i] = this.memory[this.i_reg + i]
			}
		}
	}

}

tick_timers :: proc(this: ^Chip8) {
	if this.delay_timer > 0 {
		this.delay_timer -= 1
	}

	if this.sound_timer > 0 {
		if this.sound_timer == 1 {
			// beep
		}
		this.sound_timer -= 1
	}

}

get_display :: proc(this: ^Chip8) -> []bool {
	return this.screen[:]
}

keypress :: proc(this: ^Chip8, idx: u8, pressed: bool) {
	this.keys[idx] = pressed
}

load :: proc(this: ^Chip8, data: []byte) {
	copy(this.memory[START_ADDR:], data[:])
}
