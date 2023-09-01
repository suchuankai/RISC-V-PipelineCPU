module Forward_Hazard(
	input clk, rst,
	input [4:0] rs1_addr_from_ID, rs2_addr_from_ID,  // comb !!!
	
	/* forward */
	input [4:0] rd_addr_from_ID, rd_addr_from_EX,    
	input reg_w_from_ID, reg_w_from_EX,

	/* hazard */
	input [1:0] branch_ctrl,
	input mem_r_from_ID,

	output logic [1:0] rs1_sel_forward, rs2_sel_forward,
	output logic [1:0] hazard_ctrl, hazard_reg
);


/* Forward */
always_ff @(posedge clk)begin
	if(rst) begin
		rs1_sel_forward <= 0;
	end
	else begin
		if( reg_w_from_ID && (rs1_addr_from_ID==rd_addr_from_ID) && rs1_addr_from_ID!=0 ) begin
			rs1_sel_forward <= 1;   /* Forward from ALU/MEM　register */
		end
		else if(reg_w_from_EX && (rs1_addr_from_ID==rd_addr_from_EX) && rs1_addr_from_ID!=0 ) begin
			rs1_sel_forward <= 2;
		end
		else rs1_sel_forward <= 0;
	end
end

always_ff @(posedge clk)begin
	if(rst) begin
		rs2_sel_forward <= 0;
	end
	else begin
		if( reg_w_from_ID && (rs2_addr_from_ID==rd_addr_from_ID) && rs2_addr_from_ID!=0 ) begin
			rs2_sel_forward <= 1;   /* Forward from ALU/MEM register */
		end
		else if(reg_w_from_EX && (rs2_addr_from_ID==rd_addr_from_EX) && rs2_addr_from_ID!=0 ) begin
			rs2_sel_forward <= 2;
		end
		else rs2_sel_forward <= 0;
	end
end


/* Hazard (stall and flush) */
always_comb begin
	if(rst) begin
		hazard_ctrl = 2'd0;
	end
	else begin
		if( branch_ctrl != 2'b00 )begin   /* jump or branch taken -> PC select caculate address, Instruction flush, control signal flush */
			hazard_ctrl = 2'd1;
		end    
		else if(mem_r_from_ID && ( (rs2_addr_from_ID==rd_addr_from_ID) || (rs1_addr_from_ID==rd_addr_from_ID) ) )  begin  /* Load use hazard -> PC = PC, Instruction = Instruction, control signal flush */
			hazard_ctrl = 2'd2;
		end
		else hazard_ctrl = 2'd0;
	end
end

// Hazard delay one more cycle for instruction select
always_ff @(posedge clk) begin
	if(rst) begin
		hazard_reg <= 2'd1;
	end
	else begin
		hazard_reg <= hazard_ctrl;
	end
end


endmodule