`timescale 1ns / 1ps
`include "GLOBAL.v"

// 파이프라인 CPU : state 제거, opcode/funct -> 제어신호 1회 생성

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg RegDst,	// 레지스터 쓰기 주소 - inst[20-16] vs inst[15-11]
	output reg Branch,	// 추가됨!  BEQ/BNE 인 경우 1, MEM 단계에서 PCSrc 만들 때 사용
	output reg JR,		// JR 명령어인 경우를 위한 MUX 컨트롤
	output reg MemRead,
	output reg MemtoReg,
	output reg MemWrite,
	output reg ALUSrc,	// 추가됨!  ALU 의 2번째 피연산자 - rd_data2(B) vs signEx
	output reg SignExtend,	// signed 면 1, ANDI/ORI/XORI 만 zero-ext
	output reg RegWrite,
	output reg [3:0] ALUOp,
	output reg SavePC	// 현재 PC값(PC+4) 저장! JAL 명령어를 위한 출력

	// 삭제됨 (멀티사이클 전용)
	// output reg Jump, ALUSrcA, ALUSrcB, PCSource, IRWrite, IorD, PCWrite, PCWriteCond
    );

	always @(*) begin
		// 강의자료 04 - 38p 참고
		RegDst = opcode == 0;
		ALUSrc = (opcode != 0) && (opcode != `OP_BEQ) && (opcode != `OP_BNE);
		MemtoReg = opcode == `OP_LW;
		RegWrite = (opcode != `OP_SW) && (opcode != `OP_BEQ) && (opcode != `OP_BNE) && (opcode != `OP_J) && !((opcode == 0) && (funct == `FUNCT_JR));
		MemRead = (opcode == `OP_LW);
		MemWrite = (opcode == `OP_SW);
		Branch = (opcode == `OP_BEQ) || (opcode == `OP_BNE);

		JR = (opcode == 0) && (funct == `FUNCT_JR);
		// troubleshooting - ANDI/ORI/XORI 만 zero-ext, 나머지는 sign-ext
		SignExtend = (opcode != `OP_ANDI) && (opcode != `OP_ORI) && (opcode != `OP_XORI);
		SavePC = opcode == `OP_JAL;

		// ALUOp
		ALUOp = 0;
		if(opcode == 0) begin
			case (funct)
				`FUNCT_SLL: ALUOp = `ALU_SLL;
				`FUNCT_SRL: ALUOp = `ALU_SRL;
				`FUNCT_SRA: ALUOp = `ALU_SRA;
				// `FUNCT_JR: ALUOp = ;
				`FUNCT_ADDU: ALUOp = `ALU_ADDU;
				`FUNCT_SUBU: ALUOp = `ALU_SUBU;
				`FUNCT_AND: ALUOp = `ALU_AND;
				`FUNCT_OR: ALUOp = `ALU_OR;
				`FUNCT_XOR: ALUOp = `ALU_XOR;
				`FUNCT_NOR: ALUOp = `ALU_NOR;
				`FUNCT_SLT: ALUOp = `ALU_SLT;
				`FUNCT_SLTU: ALUOp = `ALU_SLTU;
			endcase
		end
		else begin
			case (opcode)
				// `OP_J: ALUOp = ;
				// `OP_JAL: ALUOp = ;
				`OP_BEQ: ALUOp = `ALU_EQ;
				`OP_BNE: ALUOp = `ALU_NEQ;
				`OP_ADDIU: ALUOp = `ALU_ADDU;
				`OP_SLTI: ALUOp = `ALU_SLT;
				`OP_SLTIU: ALUOp = `ALU_SLTU;
				`OP_ANDI: ALUOp = `ALU_AND;
				`OP_ORI: ALUOp = `ALU_OR;
				`OP_XORI: ALUOp = `ALU_XOR;
				`OP_LUI: ALUOp = `ALU_LUI;
				`OP_LW: ALUOp = `ALU_ADDU;
				`OP_SW: ALUOp = `ALU_ADDU;
			endcase
		end
	end
endmodule
