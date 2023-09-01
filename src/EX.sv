module EX(
	input clk, rst,
	input [31:0] pc_from_ID,
	input [31:0] immediate,

	/* control unit */
	input pc_src_from_ID,       // EX
	input alu_src2_from_ID,     // EX  
	input rd_src_from_ID,       // MEM
	input mem_r_from_ID,        // MEM
	input mem_w_from_ID,        // MEM
	input reg_w_from_ID,        // WB
	input wb_sel_from_ID,       // WB

	output logic rd_src_from_EX,       
	output logic mem_r_from_EX,        
	output logic mem_w_from_EX,        
	output logic reg_w_from_EX,        
	output logic wb_sel_from_EX,       

	/* Branch */
	input [6:0] opcode_from_ID,
	input [2:0] func3_from_ID,
	output logic [1:0] branch_ctrl,         // For pc select control
	output logic [31:0] pc_from_EX,
	output logic [31:0] pc_branch_from_EX,  // For pc select

	/* ALU */
	input [3:0] alu_ctrl,
	input [31:0] rs1_data_from_ID,
	input [31:0] rs2_data_from_ID,

	input [4:0] rd_addr_from_ID,

	output logic [31:0] alu_res_comb,
	output logic [31:0] alu_res_from_EX,  

	/* forward (from latter stage)*/
	input [1:0] rs1_sel_forward, rs2_sel_forward,
	input [31:0] forward_from_MEM,
	input [31:0] forward_from_WB,

	/* others */
	output logic [2:0] func3_from_EX,
	output logic [31:0] rs2_data_from_EX,
	output logic [4:0] rd_addr_from_EX
);



/*------- control unit -------*/

assign mem_r_from_EX = mem_r_from_ID;
assign mem_w_from_EX = mem_w_from_ID;

always_ff @(posedge clk) begin
	if(rst) begin
		rd_src_from_EX <= 1'b0;
		reg_w_from_EX <= 1'b0;
		wb_sel_from_EX <= 1'b0;
	end
	else begin
		rd_src_from_EX <= rd_src_from_ID;
		reg_w_from_EX <= reg_w_from_ID;
		wb_sel_from_EX <= wb_sel_from_ID;
	end
end



/*-------  Forward  -------*/

logic [31:0] rs2_temp;
logic [31:0] alu_in1, alu_in2;

// rs1 forward
always_comb begin
	case(rs1_sel_forward)
		2'b00: alu_in1 = rs1_data_from_ID;
		2'b01: alu_in1 = forward_from_MEM;
		2'b10: alu_in1 = forward_from_WB;
		default: alu_in1 = 32'd0;
	endcase
end

// rs2 forward
always_comb begin
	case(rs2_sel_forward)
		2'b00: rs2_temp = rs2_data_from_ID;
		2'b01: rs2_temp = forward_from_MEM;
		2'b10: rs2_temp = forward_from_WB;
		default: rs2_temp = 32'd0;
	endcase
	alu_in2 = (alu_src2_from_ID)? immediate : rs2_temp;
end


/*-------  ALU  -------*/

logic br_cond_tmp;

// branch condition from ALU
always_comb begin
  case (func3_from_ID[2:1])
    2'b00:  /* BEQ、 BNE */
      br_cond_tmp = (alu_in1 == alu_in2) ^ func3_from_ID[0] ;
    2'b10:  /* BLT、 BGE */
      br_cond_tmp = ($signed(alu_in1) < $signed(alu_in2)) ^ func3_from_ID[0];
    2'b11:  /* BLTU、 BGEU */
      br_cond_tmp = ($unsigned(alu_in1) < $unsigned(alu_in2)) ^ func3_from_ID[0];
    default:
      br_cond_tmp = 1'b0;
  endcase
end



always_comb begin
  case (alu_ctrl)
    4'b0000:   /* ADD */ 
      alu_res_comb = alu_in1 + alu_in2;
    4'b1000:   /* SUB */ 
      alu_res_comb = alu_in1 - alu_in2;
    4'b0001:   /* SLL */
      alu_res_comb = alu_in1 << (alu_in2[4:0]);
    4'b0101:   /* SRL */
      alu_res_comb = alu_in1 >> (alu_in2[4:0]);
    4'b0010:   /* SLT */
      alu_res_comb = $signed(alu_in1) < $signed(alu_in2);
    4'b0011:   /* SLTU */
      alu_res_comb = $unsigned(alu_in1) < $unsigned(alu_in2);
    4'b0100:   /* XOR */
      alu_res_comb = alu_in1 ^ alu_in2;    
    4'b0110:   /* OR */
      alu_res_comb = alu_in1 | alu_in2;
    4'b0111:   /* AND */
      alu_res_comb = alu_in1 & alu_in2;    
    4'b1101:   /* SRA */
      alu_res_comb = $signed(alu_in1) >>> (alu_in2[4:0]);
    4'b1001:   /* LUI  (special case) */
      alu_res_comb = alu_in2;
    default:
      alu_res_comb = 32'd0;
  endcase
end

always_ff @(posedge clk) begin
	if(rst) begin
		alu_res_from_EX <= 32'd0;
	end
	else begin
		alu_res_from_EX <= alu_res_comb;
	end
end


/*------- Branch -------*/
logic [31:0] pc_add_4;
assign pc_add_4 = pc_from_ID + 4;
assign pc_branch_from_EX = pc_from_ID + immediate;

always_ff @(posedge clk) begin
	if(rst) begin
		pc_from_EX <= 32'd0;
	end
	else begin
		pc_from_EX <= (pc_src_from_ID)? pc_branch_from_EX : pc_add_4;
	end
end


always_comb begin
	if(opcode_from_ID[6:5]==2'b11) begin // six branch instruction and JAL、JALR
		case(opcode_from_ID[3:2])
			2'b00: begin /* B type */
				branch_ctrl =  (br_cond_tmp)?  2'b10 : 2'b00;   // taken or not
			end
			2'b01: begin /* JALR */
				branch_ctrl = 2'b01;
			end
			2'b11: begin /* JAL */
				branch_ctrl = 2'b10;
			end
			default: branch_ctrl = 2'b00;
		endcase
	end
	else branch_ctrl = 2'b00;
end

/*------- others -------*/
assign rs2_data_from_EX = rs2_temp;
assign func3_from_EX = func3_from_ID;
always_ff @(posedge clk) begin
	if(rst) begin

		rd_addr_from_EX <= 5'd0;
	end
	else begin
		
		rd_addr_from_EX <= rd_addr_from_ID;
	end
end


endmodule