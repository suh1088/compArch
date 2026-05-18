`timescale 1ns / 1ps
`include "GLOBAL.v"

// 파이프라인 해저드 처리
// - 데이터 해저드 : 포워딩 + load-use 스톨
// - 제어 해저드  : 분기/점프 플러시

module HAZARD(
		// IF/ID
		input [4:0]		ifid_rs,
		input [4:0]		ifid_rt,

		// ID/EX (load-use 검사용)
		input [4:0]		idex_rt,
		input			idex_MemRead,
		input			idex_RegWrite,
		input [4:0]		idex_wr_addr,

		// EX/MEM
		input			exmem_RegWrite,
		input [4:0]		exmem_wr_addr,

		// MEM/WB
		input			memwb_RegWrite,
		input [4:0]		memwb_wr_addr,

		// 분기/점프 taken
		input			branch_taken,
		input			jump_taken,

		// 포워딩 mux 신호
		// 00 : ID/EX 그대로
		// 01 : MEM/WB 에서
		// 10 : EX/MEM 에서
		output reg [1:0]	ForwardA,
		output reg [1:0]	ForwardB,

		// 스톨
		output reg		PCWrite,
		output reg		IFIDWrite,
		output reg		IDEX_bubble,

		// 플러시
		output reg		IFID_flush
	);

	// 포워딩
	always @(*) begin
		ForwardA = 2'b00;
		ForwardB = 2'b00;

		// EX/MEM -> EX

		// MEM/WB -> EX (EX/MEM 우선)
	end

	// load-use 스톨
	always @(*) begin
		PCWrite     = 1'b1;
		IFIDWrite   = 1'b1;
		IDEX_bubble = 1'b0;

		// idex_MemRead 이고 rt 가 다음 명령의 rs/rt 랑 같으면 한 사이클 스톨
	end

	// 분기/점프 플러시
	always @(*) begin
		IFID_flush = 1'b0;

		// branch_taken | jump_taken
	end

endmodule
