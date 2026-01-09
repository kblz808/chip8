package main

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


Chip8 :: struct {
	program_counter: u16,
	memory:          [4096]u8,
	screen:          [64 * 32]bool,
	v_reg:           [16]u8,
	i_reg:           u16,
	stack:           [16]u16,
	stack_pointer:   u16,
	keys:            [16]bool,
	delay_timer:     u8,
	sound_timer:     u8,
	fetch:           proc(_: ^Chip8) -> u16,
	tick:            proc(_: ^Chip8),
}

NewChip8 :: proc() -> Chip8 {
	chip8 := Chip8 {
		program_counter = 0x200,
		memory          = [4096]u8{},
		screen          = [64 * 32]bool{},
		v_reg           = [16]u8{},
		i_reg           = 0,
		stack           = [16]u16{},
		stack_pointer   = 0,
		keys            = [16]bool{},
		delay_timer     = 0,
		sound_timer     = 0,
	}

	copy(chip8.memory[:80], FONTSET[:])

	chip8.fetch = fetch
	chip8.tick = tick

	return chip8
}


reset :: proc(this: ^Chip8) {
	this.program_counter = 0x200
	this.memory = [4096]u8{}
	this.screen = [64 * 32]bool{}
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
	op := this.fetch(this)
}

fetch :: proc(this: ^Chip8) -> u16 {
	higher_byte := u16(this.memory[this.program_counter])
	lower_byte := u16(this.memory[this.program_counter + 1])

	op := (higher_byte << 8) | lower_byte

	this.program_counter += 2

	return op
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
