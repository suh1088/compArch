`timescale 1ns / 1ps
`include "GLOBAL.v"

//사이클 IF ID EX MEM WB

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	//삭제됨 (멀티사이클 FSM 제거 -> 파이프라인은 조합논리 디코더)
	// input [2:0] state,
	// output reg [2:0] state_next,

	// output various ports
	//변경됨 (스테이지별 신호로 사용, 외부 파이프라인 레지스터에서 단계별로 전달)
	output reg MemRead,
	output reg MemtoReg,
	output reg MemWrite,
	output reg SignExtend,	// signext? or unsigned
	output reg RegWrite,
	output reg [3:0] ALUOp,
	output reg JR,		// JR 명령어인 경우를 위한 MUX 컨트롤
	output reg SavePC,	// 현재 PC값(PC+4) 저장! JAL 명령어를 위한 출력

	output reg RegDst,	// inst[20-16] , inst[15-0]

	// 추가됨!
	output reg ALUSrc,	// 0 : rd_data2(B) , 1 : signEx
	// 추가됨!
	output reg Branch	// BEQ/BNE 인 경우 1

	//삭제됨 (멀티사이클 전용)
	// output reg ALUSrcA,
	// output reg [1:0]ALUSrcB,
	// output reg [1:0]PCSource,
	// output reg IRWrite,
	// output reg IorD,
	// output reg PCWrite,
	// output reg PCWriteCond

    );

	always @(*) begin
		// 기본값 초기화
		MemRead = 0;
		MemtoReg = 0;
		MemWrite = 0;
		SignExtend = 0;
		RegWrite = 0;
		ALUOp = 0;
		JR = 0;
		SavePC = 0;
		RegDst = 0;
		ALUSrc = 0;	// 추가됨!
		Branch = 0;	// 추가됨!

		// 변경됨 : state 기반 FSM 대신 opcode 디코딩
		case(opcode)
			// R-type
			`OP_RTYPE: begin
				if(funct == `FUNCT_JR) begin
					// JR : PC <- rs , RegWrite 없음
					JR = 1;
				end
				else begin
					RegDst  = 1;
					RegWrite = 1;
					ALUSrc  = 0;	// 추가됨!
					case (funct)
						`FUNCT_SLL:  ALUOp = `ALU_SLL;
						`FUNCT_SRL:  ALUOp = `ALU_SRL;
						`FUNCT_SRA:  ALUOp = `ALU_SRA;
						`FUNCT_ADDU: ALUOp = `ALU_ADDU;
						`FUNCT_SUBU: ALUOp = `ALU_SUBU;
						`FUNCT_AND:  ALUOp = `ALU_AND;
						`FUNCT_OR:   ALUOp = `ALU_OR;
						`FUNCT_XOR:  ALUOp = `ALU_XOR;
						`FUNCT_NOR:  ALUOp = `ALU_NOR;
						`FUNCT_SLT:  ALUOp = `ALU_SLT;
						`FUNCT_SLTU: ALUOp = `ALU_SLTU;
					endcase
				end
			end

			// J : PC만 변경 (외부에서 처리)
			`OP_J: begin
			end

			// JAL : PC 저장 후 점프 (PC 변경은 외부)
			`OP_JAL: begin
				SavePC  = 1;
				RegWrite = 1;
			end

			// Branch
			`OP_BEQ: begin
				Branch = 1;	// 추가됨!
				ALUOp  = `ALU_EQ;
				SignExtend = 1;
			end
			`OP_BNE: begin
				Branch = 1;	// 추가됨!
				ALUOp  = `ALU_NEQ;
				SignExtend = 1;
			end

			// I-type ALU
			`OP_ADDIU: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_ADDU; SignExtend = 1;
			end
			`OP_SLTI: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_SLT;  SignExtend = 1;
			end
			`OP_SLTIU: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_SLTU; SignExtend = 1;
			end
			`OP_ANDI: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_AND;  SignExtend = 0;
			end
			`OP_ORI: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_OR;   SignExtend = 0;
			end
			`OP_XORI: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_XOR;  SignExtend = 0;
			end
			`OP_LUI: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_LUI;  SignExtend = 1;
			end

			// Load / Store
			`OP_LW: begin
				RegWrite = 1; ALUSrc = 1; ALUOp = `ALU_ADDU; SignExtend = 1;
				MemRead  = 1; MemtoReg = 1;
			end
			`OP_SW: begin
				ALUSrc   = 1; ALUOp = `ALU_ADDU; SignExtend = 1;
				MemWrite = 1;
			end
		endcase
	end

	// 완!
endmodule
