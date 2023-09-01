`include "IF.sv"
`include "ID.sv"
`include "EX.sv"
`include "MEM.sv"
`include "WB.sv"
`include "Forward_Hazard.sv"

module CPU(
	input clk, rst,
	input  [31:0] data_from_DM, IM_data_in,
	output [13:0] IM_addr, DM_addr,
	output [31:0] data_to_DM, 
	output mem_r_from_EX,
	output [3:0]  DM_write_en
);

/* Stage IF wire */
logic [31:0] pc_from_IF;
logic [31:0] IM_data_buf;


/* Stage ID wire */
logic reg_w_wb;
logic [4:0] rd_addr_wb;
logic [31:0] reg_data_wb;
logic [31:0] rs1_data;
logic [31:0] rs2_data;

// control unit
logic pc_src_from_ID;
logic alu_src2_from_ID;
logic rd_src_from_ID;
logic mem_r_from_ID;
logic mem_w_from_ID;
logic reg_w_from_ID;
logic wb_sel_from_ID;
logic [3:0] alu_ctrl;

logic [31:0] immediate;
logic [4:0] rs1_addr_from_ID;
logic [4:0] rs2_addr_from_ID;
logic [4:0] rd_addr_from_ID;
logic [31:0] pc_from_ID;
logic [6:0] opcode_from_ID;
logic [2:0] func3_from_ID;


/* Stage EX wire */
logic [1:0] branch_ctrl;
logic [31:0] alu_res_from_EX;
logic [31:0] pc_branch_from_EX;
logic rd_src_from_EX;
logic mem_w_from_EX;
logic reg_w_from_EX;
logic wb_sel_from_EX;
logic [31:0] pc_from_EX;
logic [31:0] alu_res_comb;
logic [31:0] forward_from_MEM;
logic [31:0] forward_from_WB;

logic [2:0] func3_from_EX;
logic [31:0] rs2_data_from_EX;
logic [4:0] rd_addr_from_EX;


/* Stage MEM wire */
logic reg_w_from_MEM;
logic wb_sel_from_MEM;
logic [4:0] rd_addr_from_MEM;
logic [31:0] rd_from_pc;
logic [31:0] rd_from_mem;


/* forward and hazard wire */
logic [1:0] hazard_ctrl;
logic [1:0] hazard_reg;
logic [1:0] rs1_sel_forward;
logic [1:0] rs2_sel_forward;



/* Stage IF */
IF IF(
	.clk(clk), 
	.rst(rst),
	.hazard_ctrl(hazard_ctrl),              
	.pc_sel(branch_ctrl),                   
	.pc_jump(alu_res_comb), 
	.pc_branch_taken(pc_branch_from_EX), 
	.IM_data_in(IM_data_in),     // From instruction memory              

	.pc_from_IF(pc_from_IF),            
	.instr_addr(IM_addr),              
	.IM_data_buf(IM_data_buf)
);


/* Stage ID */
ID ID(
	.clk(clk), 
	.rst(rst),
	.hazard_ctrl(hazard_ctrl), 
	.hazard_reg(hazard_reg),
	.pc_from_IF(pc_from_IF),
	.IM_data_in(IM_data_in), 
	.IM_data_buf(IM_data_buf),

	/*  Register file  */
	.reg_w_wb(reg_w_wb),           
	.rd_addr_wb(rd_addr_wb),  
	.reg_data_wb(reg_data_wb), 
	.rs1_data(rs1_data), 
	.rs2_data(rs2_data),

	/*  control unit  */
	.pc_src_from_ID(pc_src_from_ID),       // EX
	.alu_src2_from_ID(alu_src2_from_ID),   // EX  
	.rd_src_from_ID(rd_src_from_ID),       // MEM
	.mem_r_from_ID(mem_r_from_ID),         // MEM
	.mem_w_from_ID(mem_w_from_ID),         // MEM
	.reg_w_from_ID(reg_w_from_ID),         // WB
	.wb_sel_from_ID(wb_sel_from_ID),       // WB

	/* alu control */
	.alu_ctrl(alu_ctrl),

	/*  immediate value  */
	.immediate(immediate),

	/* forward detect and others */
	.rs1_addr_from_ID(rs1_addr_from_ID),
	.rs2_addr_from_ID(rs2_addr_from_ID),
	.rd_addr_from_ID(rd_addr_from_ID),

	.pc_from_ID(pc_from_ID),
	.opcode_from_ID(opcode_from_ID),
	.func3_from_ID(func3_from_ID)
);


/* Stage EX */
EX EX(
	.clk(clk), 
	.rst(rst),
	.pc_from_ID(pc_from_ID),
	.immediate(immediate),

	/* control unit */
	.pc_src_from_ID(pc_src_from_ID),       // EX
	.alu_src2_from_ID(alu_src2_from_ID),   // EX  
	.rd_src_from_ID(rd_src_from_ID),       // MEM
	.mem_r_from_ID(mem_r_from_ID),         // MEM
	.mem_w_from_ID(mem_w_from_ID),         // MEM
	.reg_w_from_ID(reg_w_from_ID),         // WB
	.wb_sel_from_ID(wb_sel_from_ID),       // WB

	.rd_src_from_EX(rd_src_from_EX),       
	.mem_r_from_EX(mem_r_from_EX),        
	.mem_w_from_EX(mem_w_from_EX),        
	.reg_w_from_EX(reg_w_from_EX),        
	.wb_sel_from_EX(wb_sel_from_EX),       

	/* Branch */
	.opcode_from_ID(opcode_from_ID),
	.func3_from_ID(func3_from_ID),
	.branch_ctrl(branch_ctrl),             // For pc select control
	.pc_from_EX(pc_from_EX),
	.pc_branch_from_EX(pc_branch_from_EX), // For pc select

	/* ALU */
	.alu_ctrl(alu_ctrl),
	.rs1_data_from_ID(rs1_data),
	.rs2_data_from_ID(rs2_data),

	.rd_addr_from_ID(rd_addr_from_ID),

	.alu_res_comb(alu_res_comb),
	.alu_res_from_EX(alu_res_from_EX),

	/* forward (from latter stage)*/
	.rs1_sel_forward(rs1_sel_forward), 
	.rs2_sel_forward(rs2_sel_forward),
	.forward_from_MEM(forward_from_MEM),
	.forward_from_WB(reg_data_wb),

	/* others */
	.func3_from_EX(func3_from_EX),
	.rs2_data_from_EX(rs2_data_from_EX),
	.rd_addr_from_EX(rd_addr_from_EX)
);


/* Stage MEM */
MEM MEM(
	.clk(clk), 
	.rst(rst),
	.pc_from_EX(pc_from_EX),

	/* control unit */
	.reg_w_from_EX(reg_w_from_EX),
	.wb_sel_from_EX(wb_sel_from_EX),
	.rd_src_from_EX(rd_src_from_EX),
	.mem_r_from_EX(mem_r_from_EX),
	.mem_w_from_EX(mem_w_from_EX),

	.reg_w_from_MEM(reg_w_from_MEM),
	.wb_sel_from_MEM(wb_sel_from_MEM),
	.func3_from_EX(func3_from_EX),

	.alu_res_comb(alu_res_comb),
	.alu_res_from_EX(alu_res_from_EX),
	.rs2_data_from_EX(rs2_data_from_EX),
	.rd_addr_from_EX(rd_addr_from_EX),

	.rd_addr_from_MEM(rd_addr_from_MEM),

	.rd_from_pc(rd_from_pc), 
	.rd_from_mem(rd_from_mem),

	/* data MEM */
	.data_from_mem(data_from_DM),
	.DM_write_en(DM_write_en),
	.DM_addr(DM_addr),
	.DM_data_in(data_to_DM),   // write data to DM

	/* forward */
	.forward_from_MEM(forward_from_MEM)
);


/* Stage WB */
WB WB(
	.clk(clk), 
	.rst(rst),
	.reg_w_from_MEM(reg_w_from_MEM), 
	.wb_sel_from_MEM(wb_sel_from_MEM),

	.rd_from_pc(rd_from_pc), 
	.rd_from_mem(rd_from_mem),
	.rd_addr_from_MEM(rd_addr_from_MEM),

	.wr_back_data(reg_data_wb),
	.wr_back_addr(rd_addr_wb),
	.reg_w_from_wb(reg_w_wb)
);


Forward_Hazard Forward_Hazard(
	.clk(clk), 
	.rst(rst),
	.rs1_addr_from_ID(rs1_addr_from_ID), 
	.rs2_addr_from_ID(rs2_addr_from_ID),  
	
	/* forward */
	.rd_addr_from_ID(rd_addr_from_ID), 
	.rd_addr_from_EX(rd_addr_from_EX),
	.reg_w_from_ID(reg_w_from_ID), 
	.reg_w_from_EX(reg_w_from_EX),

	/* hazard */
	.branch_ctrl(branch_ctrl),
	.mem_r_from_ID(mem_r_from_ID),

	.rs1_sel_forward(rs1_sel_forward), 
	.rs2_sel_forward(rs2_sel_forward),
	.hazard_ctrl(hazard_ctrl), 
	.hazard_reg(hazard_reg)
);




endmodule