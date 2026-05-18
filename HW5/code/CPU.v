`timescale 1ns / 1ps
`include "GLOBAL.v"


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);

	// Split the instructions
	// Instruction-related wires
	wire [5:0]		opcode;
	wire [4:0]		rs;
	wire [4:0]		rt;
	wire [4:0]		rd;
	wire [4:0]		shamt;
	wire [5:0]		funct;
	wire [15:0]		immi;
	wire [25:0]		immj;

	// Control-related wires
	wire			RegDst;
	wire 			JR;
	wire			MemRead;
	wire			MemtoReg;
	wire 			MemWrite;
	wire			SignExtend;
	wire			RegWrite;
	wire [3:0]		ALUOp;
	wire			SavePC;
	// 삭제됨 (멀티사이클 전용)
	// wire			ALUSrcA;
	// wire [1:0]		ALUSrcB;
	// wire [1:0]		PCSource;
	// wire			IRWrite;
	// wire			IorD;
	// wire			PCWrite;
	// wire			PCWriteCond;
	wire			ALUSrc;		// 추가됨!
	wire			Branch;		// 추가됨!

	// Sign extend the immediate
	wire [31:0]		ext_imm;

	// RF-related wires
	wire [4:0]		rd_addr1;
	wire [4:0]		rd_addr2;
	wire [31:0]		rd_data1;
	wire [31:0]		rd_data2;
	reg [4:0]		wr_addr;
	reg [31:0]		wr_data;

	// MEM-related wires
	wire [31:0]		mem_addr;
	wire [31:0]		mem_write_data;
	wire [31:0]		mem_read_data;

	// IF 단계 inst memory 포트  추가됨!
	wire [31:0]		if_inst_addr;
	wire [31:0]		if_inst;

	// ALU-related wires
	wire [31:0]		operand1;
	wire [31:0]		operand2;
	wire [31:0]		alu_result;

	// Define PC
	reg [31:0]	PC;
	reg [31:0]	PC_next;

	// IF 단계 PC+4  추가됨!
	wire [31:0]	if_pc_plus4;

	// 삭제됨 (멀티사이클 FSM)
	// state 추가!!!!
	// reg [2:0] state;
	// wire [2:0] state_next;  // (reg -> wire 변경) 이부분 다시한번 확인

	// 삭제됨 (멀티사이클 중간 래치 - 파이프라인 레지스터로 대체)
	// 멀티사이클을 위한 중간 래지스터
	// reg [31:0]		inst;
	// reg [31:0]		mem_data_reg;
	// reg [31:0]		A;
	// reg [31:0]		B;
	// reg [31:0]		ALUOut;

	// ===================== 파이프라인 레지스터  추가됨! =====================
	// IF/ID
	reg [31:0]	ifid_pc_plus4;
	reg [31:0]	ifid_inst;

	// ID/EX
	reg			idex_RegWrite;
	reg			idex_MemtoReg;
	reg			idex_SavePC;
	reg			idex_MemRead;
	reg			idex_MemWrite;
	reg			idex_Branch;
	reg			idex_RegDst;
	reg [3:0]	idex_ALUOp;
	reg			idex_ALUSrc;
	reg [31:0]	idex_pc_plus4;
	reg [31:0]	idex_rd_data1;
	reg [31:0]	idex_rd_data2;
	reg [31:0]	idex_ext_imm;
	reg [4:0]	idex_shamt;
	reg [4:0]	idex_rs;
	reg [4:0]	idex_rt;
	reg [4:0]	idex_rd;

	// EX/MEM
	reg			exmem_RegWrite;
	reg			exmem_MemtoReg;
	reg			exmem_SavePC;
	reg			exmem_MemRead;
	reg			exmem_MemWrite;
	reg			exmem_Branch;
	reg [31:0]	exmem_pc_plus4;
	reg [31:0]	exmem_branch_target;
	reg [31:0]	exmem_alu_result;
	reg [31:0]	exmem_rd_data2;
	reg [4:0]	exmem_wr_addr;

	// MEM/WB
	reg			memwb_RegWrite;
	reg			memwb_MemtoReg;
	reg			memwb_SavePC;
	reg [31:0]	memwb_pc_plus4;
	reg [31:0]	memwb_mem_read_data;
	reg [31:0]	memwb_alu_result;
	reg [4:0]	memwb_wr_addr;

	// ===================== HAZARD 신호  추가됨! =====================
	wire		PCWrite;
	wire		IFIDWrite;
	wire		IDEX_bubble;
	wire		IFID_flush;
	wire [1:0]	ForwardA;	// HW5 기본 : 미사용
	wire [1:0]	ForwardB;	// HW5 기본 : 미사용

	//추가됨
	// wire ALUSrcA
	// wire [1:0] ALUSrcB
	// wire [1:0] PCSource
	// wire IRWrite
	// wire IorD
	// wire PCWrite
	// wire PCWriteCond

	//변경됨
	// reg [2:0] state_next -> wire [2:0] state_next
	// reg [31:0]		inst;
	// reg [31:0]		mem_read_data;
	// reg [31:0]		operand1;
	// reg [31:0]		operand2;
	// reg [31:0]		ALUOut;

	//삭제됨
	// wire Jump             - PCSource로 통합
	// wire Branch           - PCSource로 통합
	// wire ALUSrc           - ALUSrcA / ALUSrcB로 분리

	// HW5 변경/추가/삭제 요약  추가됨!
	// 추가됨 :
	//   - 파이프라인 레지스터 ifid_*, idex_*, exmem_*, memwb_*
	//   - CTRL 신호 ALUSrc, Branch
	//   - IF 포트 if_inst_addr, if_inst, if_pc_plus4
	//   - HAZARD 신호 PCWrite, IFIDWrite, IDEX_bubble, IFID_flush, ForwardA/B
	// 변경됨 :
	//   - 모든 stage 의 입력이 파이프라인 레지스터 기준으로 변경
	//   - CTRL 인스턴스 인터페이스 (state, ALUSrcA/B, PCSource ... 제거 / ALUSrc, Branch 추가)
	//   - MEM 인스턴스에 IF 포트 연결
	// 삭제됨 :
	//   - state, state_next                (멀티사이클 FSM)
	//   - inst, mem_data_reg, A, B, ALUOut (멀티사이클 IR/래치)
	//   - ALUSrcA, ALUSrcB, PCSource, IRWrite, IorD, PCWrite(CTRL의), PCWriteCond

	// Define the wires

	// 변경됨 (halt 조건은 IF/ID 단계의 inst 기준)
	// assign halt				= (inst == 32'b0);
	assign halt				= (ifid_inst == 32'b0);

   	// 멀티 사이클!! 할당 시작  -> 파이프라인 stage 별로 재배치

	// ====================== IF stage ======================
	assign if_pc_plus4  = PC + 4;	// 추가됨!
	assign if_inst_addr = PC;		// 추가됨!

	// ====================== ID stage ======================
	// inst 변경  변경됨 (inst -> ifid_inst)
	// assign opcode = inst[31:26];
	// assign rs = inst[25:21];
	// assign rt = inst[20:16];
	// assign rd = inst[15:11];
	// assign shamt = inst[10:6];
	// assign funct = inst[5:0];
	// assign immi = inst[15:0];
	// assign immj = inst[25:0];
	assign opcode = ifid_inst[31:26];
	assign rs     = ifid_inst[25:21];
	assign rt     = ifid_inst[20:16];
	assign rd     = ifid_inst[15:11];
	assign shamt  = ifid_inst[10:6];
	assign funct  = ifid_inst[5:0];
	assign immi   = ifid_inst[15:0];
	assign immj   = ifid_inst[25:0];

	// Sign extend the immediate
	// trouble shooting
	assign ext_imm = SignExtend ? {{16{immi[15]}}, immi} : {16'b0, immi};

	// RF-related wires
	assign rd_addr1 = rs;
	assign rd_addr2 = rt;

	// J / JAL / JR 점프 (ID 에서 조기 결정)  추가됨!
	wire		id_is_j   = (opcode == `OP_J);
	wire		id_is_jal = (opcode == `OP_JAL);
	wire		id_is_jr  = JR;
	wire		id_jump_taken = id_is_j | id_is_jal | id_is_jr;
	wire [31:0]	id_jump_addr  = id_is_jr ? rd_data1
	                          : {ifid_pc_plus4[31:28], immj, 2'b00};

	// ====================== EX stage ======================
	// 변경됨 (ALUSrcA/ALUSrcB -> ALUSrc, 입력은 ID/EX 의 값)
	// MEM-related wires
	// assign mem_addr = IorD ? ALUOut : PC;
	// assign mem_write_data = B;
	// ALU-related wires
	// assign operand1 = ALUSrcA ? A : PC;
	// assign operand2 = (ALUSrcB <= 2'b01) ? (ALUSrcB == 2'b00 ? B : 4) : (ALUSrcB == 2'b10 ? ext_imm : ext_imm << 2);
	assign operand1 = idex_rd_data1;
	assign operand2 = idex_ALUSrc ? idex_ext_imm : idex_rd_data2;

	// 분기 주소  추가됨!
	wire [31:0]	ex_branch_target = idex_pc_plus4 + (idex_ext_imm << 2);

	// 쓰기 레지스터 주소 (RegDst / SavePC mux)  추가됨!
	wire [4:0]	ex_wr_addr = idex_SavePC ? 5'd31
	                       : (idex_RegDst ? idex_rd : idex_rt);

	// ====================== MEM stage ======================
	// 변경됨 (EX/MEM 의 값 사용)
	assign mem_addr       = exmem_alu_result;
	assign mem_write_data = exmem_rd_data2;

	// 분기 taken 판정 : Branch & ALU 결과(EQ/NEQ 는 0/1)  추가됨!
	wire		mem_branch_taken = exmem_Branch & exmem_alu_result[0];

	// ====================== WB stage ======================
	always @(*) begin
		// 변경됨 (MEM/WB 의 값으로 결정 - wr_addr 은 EX 에서 이미 계산되어 전달)
		// wr_addr = SavePC ? 5'b11111 : (RegDst ? rd : rt);
		// ALU 공유!!
		// wr_data = SavePC ? PC : (MemtoReg ? mem_data_reg : ALUOut);
		wr_addr = memwb_wr_addr;
		wr_data = memwb_SavePC ? memwb_pc_plus4
		        : (memwb_MemtoReg ? memwb_mem_read_data : memwb_alu_result);

		// 삭제됨 (PC 갱신 로직은 별도 always 로 분리)
		// PC_next = PC;// 이부분이 문제 traoubleshoot
		// if(PCWrite || (PCWriteCond && alu_result)) begin
		// 	case(PCSource)
		// 		0: PC_next = alu_result;
		// 		1: PC_next = ALUOut;
		// 		2: PC_next = JR ? rd_data1 : {(PC[31:28]), immj, 2'b00};// 이부분??
		// 	endcase
		// end
	end

	// ====================== PC update  추가됨! ======================
	always @(*) begin
		// branch taken > jump taken > PC+4
		if (mem_branch_taken)      PC_next = exmem_branch_target;
		else if (id_jump_taken)    PC_next = id_jump_addr;
		else                       PC_next = if_pc_plus4;
	end

	// 플러시 신호  추가됨!
	wire mem_flush_all = mem_branch_taken;	// 분기 taken : IF/ID, ID/EX, EX/MEM NOP
	wire id_flush_if   = id_jump_taken;		// 점프 taken : IF/ID NOP


	// Update the Clock
	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
			// 삭제됨 (state 제거)
			// state <= 0;

			// 파이프라인 레지스터 초기화  추가됨!
			ifid_pc_plus4 <= 0;
			ifid_inst     <= 0;

			idex_RegWrite <= 0; idex_MemtoReg <= 0; idex_SavePC <= 0;
			idex_MemRead  <= 0; idex_MemWrite <= 0; idex_Branch <= 0;
			idex_RegDst   <= 0; idex_ALUOp    <= 0; idex_ALUSrc <= 0;
			idex_pc_plus4 <= 0; idex_rd_data1 <= 0; idex_rd_data2 <= 0;
			idex_ext_imm  <= 0; idex_shamt    <= 0;
			idex_rs <= 0; idex_rt <= 0; idex_rd <= 0;

			exmem_RegWrite <= 0; exmem_MemtoReg <= 0; exmem_SavePC <= 0;
			exmem_MemRead  <= 0; exmem_MemWrite <= 0; exmem_Branch <= 0;
			exmem_pc_plus4 <= 0; exmem_branch_target <= 0;
			exmem_alu_result <= 0; exmem_rd_data2 <= 0; exmem_wr_addr <= 0;

			memwb_RegWrite <= 0; memwb_MemtoReg <= 0; memwb_SavePC <= 0;
			memwb_pc_plus4 <= 0; memwb_mem_read_data <= 0;
			memwb_alu_result <= 0; memwb_wr_addr <= 0;
		end
		else begin
			// 삭제됨 (멀티사이클 갱신)
			// state <= state_next;
			// PC <= PC_next;
			// if(IRWrite) inst <= mem_read_data;
			// mem_data_reg <= mem_read_data;
			// A <= rd_data1;
			// B <= rd_data2;
			// ALUOut <= alu_result;

			// PC  추가됨!
			if (PCWrite) PC <= PC_next;

			// IF/ID  추가됨!
			if (mem_flush_all | id_flush_if | IFID_flush) begin
				ifid_pc_plus4 <= 0;
				ifid_inst     <= 0;
			end
			else if (IFIDWrite) begin
				ifid_pc_plus4 <= if_pc_plus4;
				ifid_inst     <= if_inst;
			end

			// ID/EX  추가됨!
			if (mem_flush_all | IDEX_bubble) begin
				// bubble : 모든 제어신호 0
				idex_RegWrite <= 0; idex_MemtoReg <= 0; idex_SavePC <= 0;
				idex_MemRead  <= 0; idex_MemWrite <= 0; idex_Branch <= 0;
				idex_RegDst   <= 0; idex_ALUOp    <= 0; idex_ALUSrc <= 0;
				idex_pc_plus4 <= 0; idex_rd_data1 <= 0; idex_rd_data2 <= 0;
				idex_ext_imm  <= 0; idex_shamt    <= 0;
				idex_rs <= 0; idex_rt <= 0; idex_rd <= 0;
			end
			else begin
				idex_RegWrite <= RegWrite;  idex_MemtoReg <= MemtoReg; idex_SavePC <= SavePC;
				idex_MemRead  <= MemRead;   idex_MemWrite <= MemWrite; idex_Branch <= Branch;
				idex_RegDst   <= RegDst;    idex_ALUOp    <= ALUOp;    idex_ALUSrc <= ALUSrc;
				idex_pc_plus4 <= ifid_pc_plus4;
				idex_rd_data1 <= rd_data1;
				idex_rd_data2 <= rd_data2;
				idex_ext_imm  <= ext_imm;
				idex_shamt    <= shamt;
				idex_rs <= rs; idex_rt <= rt; idex_rd <= rd;
			end

			// EX/MEM  추가됨!
			if (mem_flush_all) begin
				exmem_RegWrite <= 0; exmem_MemtoReg <= 0; exmem_SavePC <= 0;
				exmem_MemRead  <= 0; exmem_MemWrite <= 0; exmem_Branch <= 0;
				exmem_pc_plus4 <= 0; exmem_branch_target <= 0;
				exmem_alu_result <= 0; exmem_rd_data2 <= 0; exmem_wr_addr <= 0;
			end
			else begin
				exmem_RegWrite      <= idex_RegWrite;
				exmem_MemtoReg      <= idex_MemtoReg;
				exmem_SavePC        <= idex_SavePC;
				exmem_MemRead       <= idex_MemRead;
				exmem_MemWrite      <= idex_MemWrite;
				exmem_Branch        <= idex_Branch;
				exmem_pc_plus4      <= idex_pc_plus4;
				exmem_branch_target <= ex_branch_target;
				exmem_alu_result    <= alu_result;
				exmem_rd_data2      <= idex_rd_data2;
				exmem_wr_addr       <= ex_wr_addr;
			end

			// MEM/WB  추가됨!
			memwb_RegWrite      <= exmem_RegWrite;
			memwb_MemtoReg      <= exmem_MemtoReg;
			memwb_SavePC        <= exmem_SavePC;
			memwb_pc_plus4      <= exmem_pc_plus4;
			memwb_mem_read_data <= mem_read_data;
			memwb_alu_result    <= exmem_alu_result;
			memwb_wr_addr       <= exmem_wr_addr;
		end
	end



	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		// 삭제됨 (멀티사이클 FSM)
		// .state(state),
		// .state_next(state_next),
		.RegDst(RegDst),
		.JR(JR),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.SignExtend(SignExtend),
		.RegWrite(RegWrite),
		.ALUOp(ALUOp),
		.SavePC(SavePC),
		// 삭제됨 (멀티사이클 전용)
		// .ALUSrcA(ALUSrcA),
		// .ALUSrcB(ALUSrcB),
		// .PCSource(PCSource),
		// .IRWrite(IRWrite),
		// .IorD(IorD),
		// .PCWrite(PCWrite),
		// .PCWriteCond(PCWriteCond)
		.ALUSrc(ALUSrc),	// 추가됨!
		.Branch(Branch)		// 추가됨!
	);

	RF rf (
		.clk(clk),
		.rst(rst),
		.rd_addr1(rd_addr1),
		.rd_addr2(rd_addr2),
		.rd_data1(rd_data1),
		.rd_data2(rd_data2),
		// 변경됨 (RegWrite -> memwb_RegWrite, WB 단계 신호)
		// .RegWrite(RegWrite),
		.RegWrite(memwb_RegWrite),
		.wr_addr(wr_addr),
		.wr_data(wr_data)
	);

	MEM mem (
		.clk(clk),
		.rst(rst),
		// IF 단계 inst 포트  추가됨!
		.inst_addr(if_inst_addr),
		.inst(if_inst),
		// 변경됨 (MemWrite -> exmem_MemWrite, MEM 단계 신호)
		.mem_addr(mem_addr),
		// .MemWrite(MemWrite),
		.MemWrite(exmem_MemWrite),
		.mem_write_data(mem_write_data),
		.mem_read_data(mem_read_data)
	);

	ALU alu (
		.operand1(operand1),
		.operand2(operand2),
		// 변경됨 (shamt/ALUOp -> ID/EX 의 값)
		// .shamt(shamt),
		// .funct(ALUOp),
		.shamt(idex_shamt),
		.funct(idex_ALUOp),
		.alu_result(alu_result)
	);

	// HAZARD : data hazard 감지 및 스톨 / 플러시  추가됨!
	HAZARD hazard (
		.ifid_rs(rs),
		.ifid_rt(rt),
		.idex_rt(idex_rt),
		.idex_MemRead(idex_MemRead),
		.idex_RegWrite(idex_RegWrite),
		.idex_wr_addr(ex_wr_addr),
		.exmem_RegWrite(exmem_RegWrite),
		.exmem_wr_addr(exmem_wr_addr),
		.memwb_RegWrite(memwb_RegWrite),
		.memwb_wr_addr(memwb_wr_addr),
		.branch_taken(mem_branch_taken),
		.jump_taken(id_jump_taken),
		.ForwardA(ForwardA),
		.ForwardB(ForwardB),
		.PCWrite(PCWrite),
		.IFIDWrite(IFIDWrite),
		.IDEX_bubble(IDEX_bubble),
		.IFID_flush(IFID_flush)
	);



endmodule
