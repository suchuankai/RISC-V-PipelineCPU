module MEM(
	input clk, rst,
	input [31:0] pc_from_EX,

	/* control unit */
	input reg_w_from_EX,
	input wb_sel_from_EX,
	input rd_src_from_EX,
	input mem_r_from_EX,
	input mem_w_from_EX,

	output logic reg_w_from_MEM,
	output logic wb_sel_from_MEM,
	input [2:0] func3_from_EX,

	input [31:0] alu_res_comb,
	input [31:0] alu_res_from_EX,
	input [31:0] rs2_data_from_EX,
	input [4:0] rd_addr_from_EX,

	output logic [4:0] rd_addr_from_MEM,

	output logic [31:0] rd_from_pc, rd_from_mem,
	output logic [31:0] rd_from_pc_comb,

	/* data MEM */
	input [31:0] data_from_mem,
	output logic [3:0]   DM_write_en,
	output logic [13:0]  DM_addr,
	output logic [31:0]  DM_data_in,

	/* forward */
	output logic [31:0]  forward_from_MEM
);


assign rd_from_pc_comb = (rd_src_from_EX)? pc_from_EX : alu_res_from_EX;


always_ff @(posedge clk)begin
	if(rst) begin
		rd_from_pc <= 32'd0;
		reg_w_from_MEM <= 1'b0;
		wb_sel_from_MEM <= 1'b0;
		rd_addr_from_MEM <= 5'd0;
	end
	else begin
		rd_from_pc <= rd_from_pc_comb;
		reg_w_from_MEM <= reg_w_from_EX;
		wb_sel_from_MEM <= wb_sel_from_EX;
		rd_addr_from_MEM <= rd_addr_from_EX;
	end
end


/*  DM control  */
assign DM_addr = alu_res_comb[15:2];

// Load from data memory -> just only submit address, no enable signal

logic mem_r_from_EX_reg;
logic [2:0] func3_from_EX_reg;
always_ff @(posedge clk) begin
	mem_r_from_EX_reg <= mem_r_from_EX;
	func3_from_EX_reg <= func3_from_EX;
end

always_ff @(posedge clk) begin
	if(mem_r_from_EX_reg) begin
		case(func3_from_EX_reg)
			3'b000: begin /* LB */
				rd_from_mem = {{24{data_from_mem[7]}}, data_from_mem[7:0]};
			end
			3'b001: begin /* LH */
				rd_from_mem = {{16{data_from_mem[15]}}, data_from_mem[15:0]};
			end
			3'b010: begin /* LW */
				rd_from_mem = data_from_mem[31:0];
			end
			3'b100: begin /* LBU */
				rd_from_mem = {{24'd0}, data_from_mem[7:0]};
			end
			3'b101: begin /* LHU */
				rd_from_mem = {{16'd0}, data_from_mem[15:0]};
			end
			default: begin
				rd_from_mem = 32'd0;
			end
		endcase
	end
	else begin
		rd_from_mem = 32'd0;
	end
end

// Write to data memory
// Note : SRAM use word address, so it needs to handle byte shift condition here


always_comb begin
	if(mem_w_from_EX) begin
		case(func3_from_EX[1:0]) 
			2'b10: begin  /* SW  */
				DM_write_en = 4'b0000;
				DM_data_in = rs2_data_from_EX;
			end
			2'b00: begin  /* SB */
				case(alu_res_comb[1:0])
					2'b00: begin
						DM_write_en = 4'b1110;
						DM_data_in = rs2_data_from_EX;
					end
					2'b01: begin
						DM_write_en = 4'b1101;
						DM_data_in = rs2_data_from_EX << 8;
					end
					2'b10: begin
						DM_write_en = 4'b1011;
						DM_data_in = rs2_data_from_EX << 16;
					end
					2'b11: begin
						DM_write_en = 4'b0111;
						DM_data_in = rs2_data_from_EX << 24;
					end
				endcase
			end
			2'b01: begin  /* SH */
				case(alu_res_comb[1:0])
					2'b00: begin
						DM_write_en = 4'b1100;
						DM_data_in = rs2_data_from_EX;
					end
					2'b01: begin
						DM_write_en = 4'b1001;
						DM_data_in = rs2_data_from_EX << 8;
					end
					default: begin
						DM_write_en = 4'b0011;
						DM_data_in = rs2_data_from_EX << 16;
					end
				endcase
			end
			default: begin
				DM_write_en = 4'b1111;
				DM_data_in = rs2_data_from_EX;
			end
		endcase
	end
	else begin
		DM_write_en = 4'b1111;
		DM_data_in = rs2_data_from_EX;
	end
end

always_comb begin
	forward_from_MEM = (mem_r_from_EX_reg)? rd_from_mem : rd_from_pc_comb;
end





endmodule