module ARM (
    input clk, rst
);

  wire forward_enanble=0;

	wire freeze=0, hazard=0, memFreeze=0,
			rstSwitch=0;	// TODO wtf was forwardingFreeze ?
	assign freeze = hazard | memFreeze;
	assign rstSwitch = rst;
	assign outFreeze = freeze;
	assign outMemFreeze = memFreeze;
	// IF Stage to IF Stage Reg wires
	wire[31:0] PC, Instruction;

	// IF Stage Reg to ID Stage wires
	wire[31:0] IF_Reg_PC_out, IF_Reg_Ins_out;

	// ID Stage to ID Stage Reg wires
	wire imm, WB_EN, MEM_R_EN, MEM_W_EN, B, S, Two_src;
	wire[3:0] EXE_CMD, Dest, src1, src2, ID_reg_out_src1, ID_reg_out_src2;
	wire[31:0] Val_Rn, Val_Rm;
	wire[11:0] Shift_operand;
	wire[23:0] Signed_imm_24;
	wire[3:0] destAddress;
	wire[31:0] ID_Stage_PC;

	// ID Stage Reg to EXE Stage wires
	wire ID_out_WB_EN, ID_out_MEM_R_EN, ID_out_MEM_W_EN, ID_out_B, ID_out_S;
	wire[3:0] ID_out_EXE_CMD;
	wire[31:0] ID_out_Val_Rm, ID_out_Val_Rn, EXE_out_Val_Rm;
	wire ID_out_imm;
	wire[11:0] ID_out_Shift_operand;
	wire[23:0] ID_out_Signed_imm_24;
	wire[3:0] ID_out_Dest;
	wire[31:0] ID_out_PC;

	// EXE Stage to EXE Stage Reg wires
	wire[31:0] ALU_result, Br_addr;
  
	// EXE Stage to SR wires
	wire[3:0] status;

	// EXE Stage Reg out wires
	wire EXE_Reg_out_WB_EN, EXE_Reg_out_MEM_R_EN, EXE_Reg_out_MEM_W_EN;
	wire[31:0] EXE_Reg_out_ALU_result, EXE_Reg_out_ST_val;
	wire[3:0] EXE_Reg_out_Dest;

	// MEM Stage to MEM Stage Reg wires
	wire[31:0] MEM_Stage_out_MEM_result;

	// MEM Stage Reg out wires
	wire[31:0] MEM_Stage_Reg_out_ALU_result, MEM_Stage_Reg_out_MEM_read_value;
	wire[3:0] MEM_Stage_Reg_out_Dest;
	wire MEM_Stage_out_WB_EN, MEM_Stage_out_MEM_R_EN;

	// SR out wires
	wire[3:0] SR;

	// WB out wires
	wire[31:0] Result_WB;
//   wire writeBackEn;
//   wire[3:0] Dest_WB;

	wire[1:0] Sel_src1, Sel_src2;

	IF_Stage if_stage(
		.clk(clk),
		.rst(rst),
		.freeze(freeze),
		.Branch_taken(ID_out_B),
		.BranchAddr(Br_addr),
		.PC(PC),
		.Instruction(Instruction)
	);

	IF_Stage_Reg if_stage_reg(
		.clk(clk),
		.rst(rst),
		.freeze(freeze),
		.flush(ID_out_B),
		.PC_in(PC),
		.Instruction_in(Instruction),
		.PC(IF_Reg_PC_out),
		.Instruction(IF_Reg_Ins_out)
	);
	
	ID_Stage id_stage(
		.clk(clk),
		.rst(rst),
		.Instruction(IF_Reg_Ins_out),
		.Result_WB(Result_WB),
		.writeBackEn(MEM_Stage_out_WB_EN),
		.Dest_wb(MEM_Stage_Reg_out_Dest),
		.hazard(hazard),
		.SR(SR),
		.WB_EN(WB_EN),
		.MEM_R_EN(MEM_R_EN),
		.MEM_W_EN(MEM_W_EN),
		.B(B),
		.S(S),
		.EXE_CMD(EXE_CMD),
		.Val_Rn(Val_Rn),
		.Val_Rm(Val_Rm),
		.imm(imm),
		.Shift_operand(Shift_operand),
		.Signed_imm_24(Signed_imm_24),
		.Dest(Dest),
		.src1(src1),
		.src2(src2),
		.Two_src(Two_src)
	);
	
	// TODO Flush with ID_out_B or B
	ID_Stage_Reg id_stage_reg(
		.clk(clk),
		.rst(rst),
		.flush(ID_out_B), //This should be B not ID_out_B 
		.WB_EN_IN(WB_EN),
		.MEM_R_EN_IN(MEM_R_EN),
		.MEM_W_EN_IN(MEM_W_EN),
		.B_IN(B),
		.S_IN(S),
		.EXE_CMD_IN(EXE_CMD),
		.src1(src1), 
		.src2(src2),
		.PC_in(IF_Reg_PC_out),
		.Val_Rn_IN(Val_Rn),
		.Val_Rm_IN(Val_Rm),
		.imm_IN(imm),
		.Shift_operand_IN(Shift_operand),
		.Signed_imm_24_IN(Signed_imm_24),
		.Dest_IN(Dest),
		.SR_In(SR),
		.freeze(memFreeze),
		.WB_EN(ID_out_WB_EN),
		.MEM_R_EN(ID_out_MEM_R_EN),
		.MEM_W_EN(ID_out_MEM_W_EN),
		.B(ID_out_B),
		.S(ID_out_S),
		.EXE_CMD(ID_out_EXE_CMD),
		.PC(ID_out_PC),
		.Val_Rm(ID_out_Val_Rm),
		.Val_Rn(ID_out_Val_Rn),
		.imm(ID_out_imm),
		.Shift_operand(ID_out_Shift_operand),
		.Signed_imm_24(ID_out_Signed_imm_24),
		.Dest(ID_out_Dest),
		.SR(ID_SR),
		.ID_reg_out_src1(ID_reg_out_src1),
		.ID_reg_out_src2(ID_reg_out_src2)
	);

	EXE_Stage exe_stage(
		.clk(clk),
		.EXE_CMD(ID_out_EXE_CMD),
		.MEM_R_EN(ID_out_MEM_R_EN),
		.MEM_W_EN(ID_out_MEM_W_EN),
		.PC(ID_out_PC),
		.Val_Rn(ID_out_Val_Rn),
		.Val_Rm(ID_out_Val_Rm),
		.imm(ID_out_imm),
		.Shift_operand(ID_out_Shift_operand),
		.Signed_imm_24(ID_out_Signed_imm_24),
		.SR(SR),
		.ALU_result_reg(EXE_Reg_out_ALU_result),
		.WB_WB_DEST(Result_WB),
		.sel_src1(Sel_src1),
		.sel_src2(Sel_src2),
  		.ALU_result(ALU_result),
		.Br_addr(Br_addr),
		.EXE_out_Val_Rm(EXE_out_Val_Rm),
		.status(status)
	);

	EXE_Stage_Reg exe_stage_reg(
		.clk(clk),
		.rst(rst),
		.WB_EN_in(ID_out_WB_EN),
		.MEM_R_EN_in(ID_out_MEM_R_EN),
		.MEM_W_EN_in(ID_out_MEM_W_EN),
		.ALU_result_in(ALU_result),
		.ST_val_in(EXE_out_Val_Rm),
		.Dest_in(ID_out_Dest),
		.freeze(memFreeze),
		.WB_EN(EXE_Reg_out_WB_EN),
		.MEM_R_EN(EXE_Reg_out_MEM_R_EN),
		.MEM_W_EN(EXE_Reg_out_MEM_W_EN),
		.ALU_result(EXE_Reg_out_ALU_result),
		.ST_val(EXE_Reg_out_ST_val),
		.Dest(EXE_Reg_out_Dest)
	);

	MEM_Stage mem_stage(
		.clk(clk),
		.rst(rst),
		.freeze(memFreeze),
		.MEM_R_EN(EXE_Reg_out_MEM_R_EN),
		.MEM_W_EN(EXE_Reg_out_MEM_W_EN),
		.ALU_Res(EXE_Reg_out_ALU_result),
		.VAL_Rm(EXE_Reg_out_ST_val),
		.MEM_Res(MEM_Stage_out_MEM_result)
	);

	MEM_Stage_Reg mem_stage_reg(
		.clk(clk),
		.rst(rst),
		.WB_en_in(EXE_Reg_out_WB_EN),
		.MEM_R_en_in(EXE_Reg_out_MEM_R_EN),
		.ALU_result_in(EXE_Reg_out_ALU_result),
		.Mem_read_value_in(MEM_Stage_out_MEM_result),
		.Dest_in(EXE_Reg_out_Dest),
		.freeze(memFreeze),
		.WB_en(MEM_Stage_out_WB_EN),
		.MEM_R_en(MEM_Stage_out_MEM_R_EN), 
		.ALU_result(MEM_Stage_Reg_out_ALU_result),
		.Mem_read_value(MEM_Stage_Reg_out_MEM_read_value),
    .Dest(MEM_Stage_Reg_out_Dest)
	);

	WB_Stage wb_stage(
		.ALU_Res(MEM_Stage_Reg_out_ALU_result),
		.MEM_Res(MEM_Stage_Reg_out_MEM_read_value),
		.MEM_R_EN(MEM_Stage_out_MEM_R_EN),
		.out(Result_WB)
	);

	Hazard_Detection_Unit hazard_detection_unit(
		.src1(src1),
		.src2(src2),
		.Exe_Dest(ID_out_Dest),
		.Exe_WB_EN(ID_out_WB_EN),
		.Two_src(Two_src),
		.Mem_Dest(EXE_Reg_out_Dest),
		.Mem_WB_EN(EXE_Reg_out_WB_EN),
		.forward_en(forward_enanble),
		.is_branch(B),
		.MEM_R_EN(ID_out_MEM_R_EN),
		.hazard_detected(hazard)
	);
	
	Forwarding_Unit forwarding_unit(
		.en(forward_enanble),
		.src1(ID_reg_out_src1),
		.src2(ID_reg_out_src2),
		.WB_Dest(MEM_Stage_Reg_out_Dest),
		.MEM_Dest(EXE_Reg_out_Dest),
		.WB_WB_en(MEM_Stage_out_WB_EN),
		.MEM_WB_en(EXE_Reg_out_WB_EN),
		.Sel_src1(Sel_src1),
		.Sel_src2(Sel_src2)
	);

	StatusRegister status_reg(
		.clk(clk),
		.rst(rst),
		.S(ID_out_S),
		.Status_Bits(status),
		.Status_Reg(SR)
	);

endmodule