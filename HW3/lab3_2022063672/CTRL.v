`timescale 1ns / 1ps
`include "GLOBAL.v"

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	// output various ports
	output reg RegDst,	// 레지스터 입력 주소
	output reg Jump, 	
	output reg Branch,	
	output reg JR,		// JR 명령어인 경우를 위한 MUX 컨트롤
	output reg MemRead,	
	output reg MemtoReg,
	output reg MemWrite,
	output reg ALUSrc,	// ALU의 2번째 피연산자를 레지스터 값으로 할지, 아니면 명령어의 상수 값으로 할지
	output reg SignExtend,	//뭔지 모르겠음. 어디에 사용하길 의도한 것인지?
	output reg RegWrite,	
	output reg [3:0] ALUOp,
	output reg SavePC	// 현재 PC값(PC+4) 저장! JAL 명령어를 위한 출력

	// HW3 를 위한 추가
	// JR 명령어를 위한 출력
	//output reg JAL,

	// JAL 명령어를 위한 출력
	// output reg JR
    );

	always @(*) begin
		// FIXME
		// 강의자료 04 - 38p
		RegDst = opcode == 0;
		ALUSrc = (opcode != 0) && (opcode != `OP_BEQ) && (opcode != `OP_BNE);
		MemtoReg = opcode == `OP_LW;
		RegWrite = (opcode != `OP_SW) && (opcode != `OP_BEQ) && (opcode != `OP_BNE) && (opcode != `OP_J) && !((opcode == 0) && (funct == `FUNCT_JR));
		MemRead  = (opcode == `OP_LW);
		MemWrite = (opcode == `OP_SW);
		Jump     = (opcode == `OP_J) || (opcode == `OP_JAL) || (opcode == 0 && funct == `FUNCT_JR);
		Branch   = (opcode == `OP_BEQ) || (opcode == `OP_BNE); // branch 컨디션 확인은 다른 코드에서?

		JR = opcode == 00 && funct == `FUNCT_JR;
		// troubleshooting
		SignExtend = (opcode != `OP_ANDI) && (opcode != `OP_ORI) && (opcode != `OP_XORI);
		// SignExtend = 1;
		SavePC = opcode == `OP_JAL;

		// ALUOp 
		if(opcode == 0) begin
			case (funct)
				`FUNCT_SLL:  ALUOp = `ALU_SLL;
				`FUNCT_SRL:  ALUOp = `ALU_SRL;
				`FUNCT_SRA:  ALUOp = `ALU_SRA;
				// `FUNCT_JR:   ALUOp = ;
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
		else begin
			case (opcode)
				// `OP_J:    ALUOp = ;
				// `OP_JAL:  ALUOp = ;
				`OP_BEQ:  ALUOp = `ALU_EQ;
				`OP_BNE:  ALUOp = `ALU_NEQ;
				`OP_ADDIU: ALUOp = `ALU_ADDU;
				`OP_SLTI:  ALUOp = `ALU_SLT;
				`OP_SLTIU: ALUOp = `ALU_SLTU;
				`OP_ANDI:  ALUOp = `ALU_AND;
				`OP_ORI:   ALUOp = `ALU_OR;
				`OP_XORI:  ALUOp = `ALU_XOR;
				`OP_LUI:   ALUOp = `ALU_LUI;
				`OP_LW:    ALUOp = `ALU_ADDU;
				`OP_SW:    ALUOp = `ALU_ADDU;
			endcase
		end
	end
endmodule
