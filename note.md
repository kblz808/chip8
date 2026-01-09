many systems store additional parameters for each opcode in subsequent bytes (such as operands for addition), Chip-8 encodes these into the opcode itself. Due to this, all Chip-8 opcodes are exactly 2 bytes

each instruction (opcode) is stored as two bytes (16 bits) written in hex format.
so every instruction is represented as four hex digits: `XXXX`

| Symbol | Meaning |
| --- | --- |
| X | A single 4-bit register index (0–F) |
| Y | Another 4-bit register index |
| N | refers to a literal hexadecimal value. |
| NN or NNN | refers to two or three digit hex numbers |

for example: `1NNN` means 'jump to address `0xNNN`'
+ so `1234` means 'jump to address `0x234`'

another example: `6XNN` means 'set register `X` to value `NN`'
+ so `6123` means 'store the value `0x23` (35 in decimal) into register `V1`'

## fetching opcodes
in the `fetch` method of the emulator.
```odin
higher_byte := u16(this.memory[this.program_counter])
lower_byte := u16(this.memory[this.program_counter + 1])

op := (higher_byte << 8) | lower_byte
```
we're trying to fetch the opcode of the current cycle.

we're fetching 2 bytes using outhet program counter since all chip8 instructions are 2 bytes long.

`higher_byte` holds the first byte (high order byte)
`lower_byte` holds the second byte (low order byte)

for example lets take the opcode `6XNN` which means store the value `NN` into register `VX`
+ `6123` means store `0x23` into register `V1`
+ we first fetch the higher byte and lower byte from memory
    + `higher_byte = 0x61`
    + `lower_byte = 0x23`
+ we want to combine these two bytes into the 16 bit opcode `0x6123`
    + we first cast these two bytes to `u16` since the result of reading the memory results in a byte (`u8`)
        + the first byte (61 in hex) was `0110 0001` before casting to `u16` and `0000 0000 0110 0001` after casting to `u16`.
    + we shift the higher byte to the left by 8 bits
        + after shifting, the higher byte becomes `0110 0001 0000 0000`, this is equal to `0x6100` in hex (24832 in decimal).
        + this moves the high byte (`0x61`) into the upper 8 bits of the 16 bit opcode. 
    + we add the lower byte using OR
        ```text
            0110 0001 0000 0000   ← 0x6100
          | 0000 0000 0010 0011   ← 0x0023
          = -------------------
            0110 0001 0010 0011   ← 0x6123
        ```
+ the high byte (`0x61`) is now in the top half
+ the low byte (`0x23`) is now in the bottom half
+ final result `op = 0x6123`