module ID(
	input clk, rst,
	input [1:0]  hazard_ctrl, hazard_reg,
	input [31:0] pc_from_IF,
	input [31:0] IM_data_in, IM_data_buf,

	/*  Register file  */
	input reg_w_wb,           // From write back stage
	input [4:0]  rd_addr_wb,  // From write back stage
	input [31:0] reg_data_wb, // From write back stage
	output logic [31:0] rs1_data, rs2_data,

	/*  control unit  */
	output logic pc_src_from_ID,       // EX
	output logic alu_src2_from_ID,     // EX  
	output logic rd_src_from_ID,       // MEM
	output logic mem_r_from_ID,        // MEM
	output logic mem_w_from_ID,        // MEM
	output logic reg_w_from_ID,        // WB
	output logic wb_sel_from_ID,       // WB

	/* alu control */
	output logic [3:0] alu_ctrl,

	/*  immediate value  */
	output logic [31:0] immediate,

	/* forward detect and others */
	output logic [4:0] rs1_addr_from_ID,
	output logic [4:0] rs2_addr_from_ID,
	output logic [4:0] rd_addr_from_ID,

	output logic [31:0] pc_from_ID,
	output logic [6:0] opcode_from_ID,
	output logic [2:0] func3_from_ID
);



logic [6:0] opcode;
logic [4:0] rd_addr;
logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] instr;

always_comb begin
	case(hazard_reg)
		2'b00: instr = IM_data_in;   /* Normal situation */
		2'b01: instr = 32'h13;       /* Jump or branch taken -> flush instruction */
		2'b10: instr = IM_data_buf;  /* keep same instruction */
		default : instr = 32'd0;
	endcase

	opcode   = instr[6:0];
	rd_addr  = instr[11:7];
	funct3   = instr[14:12];
	rs1_addr_from_ID = instr[19:15];
	rs2_addr_from_ID = instr[24:20];
	funct7   = instr[31:25];
end

/*---------- Control unit ----------*/

/*
pc_src_from_ID
1 : PC = PC+imm
0 : PC = PC+4

reg_w_from_ID
1 : register write
0 : register don't write

wb_sel_from_ID
1 : register data from ALU
0 : register data from data memory

rd_src_from_ID
1 : rd value relate to PC
0 : rd value relate to ALU output

mem_r_from_ID
1 : read data memory
0 : don't read data memory

mem_w_from_ID
1 : write data to data memory
0 : don't write data to data memory

alu_src2_from_ID
1 : alu source2 value is imm
0 : alu source2 value is register file 

*/
    

always_ff @(posedge clk) begin
	if(rst) begin
		pc_src_from_ID <= 1'b0;
		rd_src_from_ID <= 1'b0;
		mem_r_from_ID  <= 1'b0;
		reg_w_from_ID  <= 1'b0;
		mem_w_from_ID  <= 1'b0;
		wb_sel_from_ID <= 1'b0;
		alu_src2_from_ID <= 1'b0;
	end
	else begin
		case(opcode)
			7'b0110011:begin   /* R type */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b0;
			end
			7'b0010011: begin  /* I type (without shift、 JALR) */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b1;
			end
			7'b1100111: begin  /* JAL */
				pc_src_from_ID <= 1'b0;  // rd = pc + 4
				rd_src_from_ID <= 1'b1;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b1;
			end
			7'b1101111:begin   /* JALR */
				pc_src_from_ID <= 1'b0;  // rd = pc + 4
				rd_src_from_ID <= 1'b1;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b1;
			end
			7'b0000011:begin   /* I type (load instr) */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // For load use hazard, prevent the proccess stall over one cycle
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b0;
				alu_src2_from_ID <= 1'b1;
			end
			7'b0100011: begin  /* S-type */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				reg_w_from_ID  <= 1'b0;
				wb_sel_from_ID <= 1'b0;
				alu_src2_from_ID <= 1'b1;
			end
			7'b1100011: begin  /* B-type */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= 1'b0;
				wb_sel_from_ID <= 1'b0;
				alu_src2_from_ID <= 1'b0; 
			end
			7'b0010111: begin  /* U-type(AUIPC) */
				pc_src_from_ID <= 1'b1;
				rd_src_from_ID <= 1'b1;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b0;
			end
			7'b0110111: begin  /* U-type(LUI) */
				pc_src_from_ID <= 1'b0;
				rd_src_from_ID <= 1'b0;
				mem_r_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
				reg_w_from_ID  <= (hazard_ctrl==2'd0)? 1'b1 : 1'b0;  // If hazard happen, flush write signal
				wb_sel_from_ID <= 1'b1;
				alu_src2_from_ID <= 1'b1;
			end
			default:begin
				reg_w_from_ID  <= 1'b0;
				mem_w_from_ID  <= 1'b0;
			end
		endcase
	end
end




/*---------- Immediate generator ----------*/

always_ff @(posedge clk) begin
	if(rst) begin
		immediate <= 32'd0;
	end
	else begin
		case(opcode)
			7'b0000011, 7'b1100111: begin  // I type without shift + JALR
				immediate <= { {20{instr[31]} }, instr[31:20]};
			end
			7'b0010011: begin              // I type shift instr
				if( funct3==3'b001 || funct3==3'b101 ) immediate <= { {27{instr[24]} }, instr[24:20]};
				else immediate <= { {20{instr[31]} }, instr[31:20]};
			end
			7'b0100011: begin              // S type
 				immediate <= { {20{instr[31]} }, instr[31:25], instr[11:7]};
			end
			7'b1100011: begin              // B type
				immediate <= { {20{instr[31]} }, instr[7], instr[30:25], instr[11:8], 1'b0};
			end
			7'b0010111, 7'b0110111: begin  // U type
				immediate <= { instr[31:12], 12'd0};
			end
			7'b1101111:begin               // J type 
				immediate <= { {12{instr[31]} }, instr[19:12], instr[20], instr[30:21], 1'b0};
			end
			default: immediate <= immediate;
		endcase
	end
end



/*---------- ALU control ----------*/

always_ff @(posedge clk) begin
	if(rst) begin
		alu_ctrl <= 4'b0000;
	end
	else begin
		case(opcode)
			7'b0110011: begin  /* R type */
				alu_ctrl <= {funct7[5], funct3};
			end
			7'b0010011: begin  /* I type */
				if(funct3==3'b001 || funct3==3'b101) alu_ctrl <= {funct7[5], funct3};  /* sign / unsign */
				else alu_ctrl <= {1'b0, funct3};
			end
			7'b0000011, 7'b1100111, 7'b0100011, 7'b1100011, 7'b0010111, 7'b1101111: begin  /* Load、 JALR、 Stype、 Btype、 AUIPC、 JAL */
				alu_ctrl <= 4'b0000;   // ADD 
			end
			7'b0110111: begin /* LUI (special case) */
				alu_ctrl <= 4'b1001;
			end
			default: begin
				alu_ctrl <= alu_ctrl;
			end
		endcase
	end
end 



/*----------  Register file  ----------*/

logic [31:0] register [31:0];

always_ff @(posedge clk) begin 
	if(rst) begin
		for(int i = 0; i < 32; i++)begin
			register[i] <= 32'd0;
		end		 
		rs1_data <= 32'd0;
		rs2_data <= 32'd0;
		rd_addr_from_ID <= 5'd0;
	end 
	else begin
		if(reg_w_wb && rd_addr_wb!=0)begin  /*  Write back (Can't write to zero register) */
			register[rd_addr_wb] <= reg_data_wb; 
		end

		if(rs1_addr_from_ID == rd_addr_wb && rd_addr_wb!=0 && reg_w_wb) begin  /* forward */
			rs1_data <= reg_data_wb;
		end
		else rs1_data <= register[rs1_addr_from_ID];

		if(rs2_addr_from_ID == rd_addr_wb && rd_addr_wb!=0 && reg_w_wb) begin  /* forward */
			rs2_data <= reg_data_wb;
		end
		else rs2_data <= register[rs2_addr_from_ID];
		
		rd_addr_from_ID  <= rd_addr;
	end
end


/*----------  Others  ----------*/
always_ff @(posedge clk) begin
	if(rst) begin
		pc_from_ID <= 32'd0;
		opcode_from_ID <= 7'd0;
		func3_from_ID <= 3'd0;
	end
	else begin
		pc_from_ID <= pc_from_IF;
		opcode_from_ID <= (hazard_ctrl==2'd0)? opcode : 7'd0;
		func3_from_ID <= funct3;
	end
end



endmodule