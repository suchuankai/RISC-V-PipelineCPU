module IF(
	input clk, rst,
	input [1:0]  hazard_ctrl,              // PC stall or not
	input [1:0]  pc_sel,                   // select next pc address(from branch control)
	input [31:0] pc_jump, pc_branch_taken, // jump & branch address
	input [31:0] IM_data_in,               // Instruction temp (for waiting use)

	output logic [31:0] pc_from_IF,        // PC reg
	output logic [13:0] instr_addr,        // address to IM
	output logic [31:0] IM_data_buf
);


logic [31:0] pc;
logic [31:0] pc_add_4;

assign pc_add_4 = pc + 4;

assign instr_addr = pc[15:2];


// PC control
always_ff @(posedge clk) begin
	if(rst)begin
		pc <= 32'd0;
		pc_from_IF <= 32'd0;
	end
	else begin
		if(hazard_ctrl == 2'd2)begin     // PC needs to stall one cycle (Load use hazard)
			pc <= pc;
			pc_from_IF <= pc_from_IF;
		end
		else begin
			case(pc_sel)
				2'b00: pc <= pc_add_4;   // Normal condition
				2'b01: pc <= pc_jump;
				2'b10: pc <= pc_branch_taken;
				default: pc <= pc;
			endcase
			pc_from_IF <= pc;
		end
	end
end

// Store last instruction

always_ff @(posedge clk) begin
	if(rst)
		IM_data_buf <= 32'd0;
	else 
		IM_data_buf <= IM_data_in;
end

endmodule