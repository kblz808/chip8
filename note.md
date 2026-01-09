each instruction (opcode) is stored as two bytes (16 bits) written in hex format.
so every instruction is represented as four hex digits: `XXXX`

| Symbol | Meaning |
| --- | --- |
| X | A single 4-bit register index (0–F) |
| Y | Another 4-bit register index |
| N | A 4-bit value (0–F) |
| KK | An 8-bit constant (0–255) |
| NNN | A 12-bit address (0–4095) |