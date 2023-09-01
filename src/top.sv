`include "CPU.sv"
`include "SRAM_wrapper.sv"

module top(
	input clk,
	input rst
);

logic [31:0] IM_data_in, DM_data_in;
logic [13:0] IM_addr, DM_addr;
logic [31:0] DM_data_out;
logic [3 :0] DM_write_en;
logic [31:0] data_from_DM, data_to_DM;
logic DM_read_en;

// CPU design
CPU CPU(
	/*  Input  */
	.clk(clk),
	.rst(rst),
	.data_from_DM(data_from_DM),
	.mem_r_from_EX(DM_read_en),
	.IM_data_in(IM_data_in),

	/*  Output  */
	.IM_addr(IM_addr),
	.DM_addr(DM_addr),
	.data_to_DM(data_to_DM),
	.DM_write_en(DM_write_en)
);


// Instruction memory
SRAM_wrapper IM1(
	/*  Input  */
	.CK(clk),           // System clock
    .CS(1'b1),          // Chip select (active high)
    .OE(1'b1),          // Output enable (active high)
    .WEB(4'b1111),      // Write enable (active low)
    .A(IM_addr),        // Address                   -> from CPU
    .DI(32'd0),         // Data input

    /*  Output  */
    .DO(IM_data_in)     // Data output               -> to CPU
);


// Data memory
SRAM_wrapper DM1(
	/*  Input  */
	.CK(clk),
    .CS(1'b1),
    .OE(1'b1),
    .WEB(DM_write_en),  // -> from CPU
    .A(DM_addr),        // -> from CPU
    .DI(data_to_DM),   // -> from CPU

    /*  Output  */
    .DO(data_from_DM)     // -> to CPU
);





endmodule