`timescale 1ns / 1ps
`include "GLOBAL.v"

//사이클 IF ID EX MEM WB

module CTRL(
	// input opcode and funct
	input [5:0] opcode,
	input [5:0] funct,

	//추가
	input [2:0] state,

	output reg [2:0] state_next,

	// output various ports
	//멀티사이클
	output reg MemRead,	
	output reg MemtoReg,
	output reg MemWrite,
	output reg SignExtend,	// signext? or unsigned
	output reg RegWrite,	
	output reg [3:0] ALUOp,
	output reg JR,		// JR 명령어인 경우를 위한 MUX 컨트롤
	output reg SavePC,	// 현재 PC값(PC+4) 저장! JAL 명령어를 위한 출력

	// 변경됨
	output reg RegDst,	// inst[20-16] , inst[15-0]
	
	//추가됨
	output reg ALUSrcA,	//  PC , A
	output reg [1:0]ALUSrcB, // B , 4 , signEx , signEx << 2
	output reg [1:0]PCSource, // ALU , ALUOut , imm
	output reg IRWrite,
	output reg IorD,
	output reg PCWrite,
	output reg PCWriteCond

	//삭제됨
	// output reg ALUSrc

	// PCSource로 통합
	// output reg Jump, 	
	// output reg Branch,
	
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
		ALUSrcA = 0;
		ALUSrcB = 0;
		PCSource = 0;
		IRWrite = 0;
		IorD = 0;
		PCWrite = 0;
		PCWriteCond = 0;

		// state_next
		case(state)
			`ST_IF: begin
				state_next <= `ST_ID;

				// 명령어 불러오기 & PC+4
				IorD = 0;
				MemRead = 1;
				IRWrite = 1;
				PCWrite = 1;
				ALUOp = `ALU_ADDU;
				ALUSrcA = 0;
				ALUSrcB = 1;
				PCSource = 0;
			end

			`ST_ID: begin 
				if(opcode == `OP_J || (opcode == 0 && funct == `FUNCT_JR)) state_next <= `ST_IF;
				else if(opcode == `OP_JAL) state_next <= `ST_WB;
				else state_next <= `ST_EX;

				// JAL
				// 현재 PC값 저장
				if(opcode == `OP_JAL) begin
					SavePC = 1;
					RegWrite = 1;
				end
				// J JR
				// PC값 변경
				else if(opcode == `OP_J || (opcode == 0 && funct == `FUNCT_JR)) begin
					PCWrite = 1;
					PCSource = 2;
					JR = opcode == 0 && funct == `FUNCT_JR;
				end
				else if(opcode == `OP_BEQ || opcode == `OP_BNE) begin
					ALUSrcA = 0;
					ALUSrcB = 3;
					ALUOp = `ALU_ADDU;
					SignExtend = 1; // 수정됨
				end
				// 일반적인 ID
				// RF에서 읽어오기 -> 자동?
				
			end

			`ST_EX:  begin
				if(opcode == `OP_LW || opcode == `OP_SW) state_next <= `ST_MEM;
				else if(opcode == `OP_BEQ || opcode == `OP_BNE) state_next <= `ST_IF;
				else state_next <= `ST_WB;

				//branch
				if(opcode == `OP_BEQ || opcode == `OP_BNE) begin
					ALUSrcA = 1;
					ALUSrcB = 0;
					if(opcode == `OP_BEQ) ALUOp = `ALU_EQ;
					else ALUOp = `ALU_NEQ;
					PCWriteCond = 1;
					PCSource = 1;
				end

				// 일반적인 EX
				else begin
					ALUSrcA = 1;
					if(opcode != 0) ALUSrcB = 2;
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

					// 여기서 더 추가?
					SignExtend = (opcode != `OP_ANDI) && (opcode != `OP_ORI) && (opcode != `OP_XORI);
				end
			end

			`ST_MEM: begin
				if(opcode == `OP_LW) state_next <= `ST_WB;
				else state_next <= `ST_IF;

				IorD = 1;
				MemRead  = (opcode == `OP_LW);
				MemWrite = (opcode == `OP_SW);
			end

			`ST_WB: begin
				state_next <= `ST_IF;

				if(opcode == `OP_JAL) begin
					PCWrite = 1;
					PCSource = 2;
				end
				else begin
					MemtoReg = opcode == `OP_LW;
					RegWrite = (opcode != `OP_SW) && (opcode != `OP_BEQ) && (opcode != `OP_BNE) && (opcode != `OP_J) && !((opcode == 0) && (funct == `FUNCT_JR));
					RegDst = (opcode == 0);
				end

			end
			// 혹시나?
			// Remove Before Flight BLF
			default: begin
				state_next = `ST_IF;
				$display("[CTRL ERROR] Invalid state: %0d at time %0t", state, $time);
			end
		endcase
	end

	// 완!
endmodule
