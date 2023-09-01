module WB(
	input clk, rst,
	input reg_w_from_MEM, wb_sel_from_MEM,

	input [31:0] rd_from_pc, rd_from_mem,
	input [4:0] rd_addr_from_MEM,

	output logic [31:0] wr_back_data,
	output logic [4:0]  wr_back_addr,
	output logic reg_w_from_wb
);


always_comb begin
	wr_back_data = (wb_sel_from_MEM)? rd_from_pc : rd_from_mem;
	wr_back_addr = rd_addr_from_MEM;
	reg_w_from_wb = reg_w_from_MEM;
end


endmodule