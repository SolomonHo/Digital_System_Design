# Digital_System_Design
Assignments for the 113-2 DSD course, focusing on Verilog programming and hardware implementation.

## Exercise Project
This exercise is based on a previous IC contest problem. The goal is to solve the matrix equation **AX = B** for **X**.  
Instead of using the conventional inverse matrix method, this design applies the **Gauss-Seidel Iterative Method (GSIM)**, performing repeated iterations until convergence.

### Key Design Points
1. **Matrix Structure Analysis** :
   Since matrix **A** has a special form, the main focus is to identify its pattern and incorporate it into the coefficient design, reducing computational complexity.

2. **Division Optimization**  :
   By applying a binary quantization resolution formula, division operations can be executed with significantly fewer cycles while maintaining high precision.

3. **Convergence Check**  :
   Convergence is determined by comparing the result of the current cycle with the previous one, rather than forcing every coefficient to iterate up to a large fixed number. This effectively reduces the number of iterations.

<br><br>
# HW1 - ALU & 8x8 Register File

1. ALU :
ALU implemented using `assign` and `always` styles.  
Tested basic arithmetic, logic, shifts, equality, overflow, and carry handling. Unspecified controls output 0.

2. 8x8 Register File :
8x8 register file without reset.  
Tested r0 stays 0, read-only mode, correct write/read, and overwriting values.

<br><br>
## HW2 - Single-Cycle RISC-V CPU
Implementation of a single-cycle CPU in RISC-V, covering instruction execution, ALU operations
<br>
## HW3 - Cache Design
Design and implementation of two cache types:

1. **Direct-Mapped Cache**  
   - Size: 32 words, 8 blocks × 4 words  
   - Placement: Direct-mapped  
   - Read/Write Policy: Read allocate, write-back + write-allocate  
   - FSM: IDLE → CHECK → WRITE → READ → UPDATE

2. **Two-Way Set Associative Cache**  
   - Size: 32 words, 4 sets × 2 ways × 4 words  
   - Placement: 2-way set associative  
   - Read/Write Policy: Read allocate, write-back + write-allocate  
   - Replacement: LRU  
   - FSM similar to dm_cache

<br><br>
## Final Project

The final project integrates all previous assignments, implementing a pipelined CPU with cache to accelerate data access and improve instruction execution efficiency.
It also includes two multi-cycle multipliers—Dadda and Shift-Add—to reduce the required cycle time for multiplication operations.
