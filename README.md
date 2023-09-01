# RISC-V-PipelineCPU
## Description
This project has implemented a **5-stage pipelined CPU** using Verilog. The data width is 32-bit, and the instruction set is based on the RISC-V instruction set architecture.
There are total of 37 instructions. After being synthesized using UMC's 0.18μm process technology, the operational frequency can reach up to 110MHz.
## Architecture
![cpu](https://github.com/suchuankai/RISC-V-PipelineCPU/assets/69788052/09f3e90f-ea4b-45f5-bbf5-25aa84c3c45c)
## All Instruction
- **R type**  
ADD、SUB、SLL、SLT、SLTU、XOR、SRL、SRA、OR、AND
- **I type**  
LW、ADDI、SLTI、SLTIU、XORI、ORI、ANDI、LB、SLLI、SRLI、SRAI、JALR、LH、LHU、LBU
- **S type**  
SW、SB、SH
- **B type**  
BEQ、BNE、BLT、BGE、BLTU、BGEU
- **U type**   
AUIPC、LUI
- **J type**  
JAL
## Tips
- In the Arithmetic Logic Unit (ALU) stage, the determination of forwarding is advanced by one cycle, and it is stored in a register for reference.
- In order to avoid an excessively long critical path from reading data from the Data Memory and sending it to ALU for computation, the address for ALU computation is sent to the Data Memory one cycle earlier. This successfully reduces the critical path from 11 ns to 8.5 ns.
## PPA
- Power : 153.7114 mW
- Performance : 110 MHz
- Area : 5571595.590 um^2



