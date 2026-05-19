`timescale 1ns / 1ps
`include "GLOBAL.v"

// 파이프라인 해저드 처리
// - 데이터 해저드 : 포워딩 없음 (HW5 기본) -> 의존성 있으면 그냥 stall
// - 제어 해저드  : 분기/점프 taken 시 IF/ID flush

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
	// HW5 basic 은 포워딩 미지원 -> 항상 00
	// 나중에 forwarding 추가하면 always @(*) 로 바꾸고 채우면 됨
	// initial 로 한번만 set (always @(*) 는 sensitivity 없어서 trigger 안됨)  // troubleshooting
	initial begin
		ForwardA = 2'b00;
		ForwardB = 2'b00;

		// EX/MEM -> EX
		// MEM/WB -> EX (EX/MEM 우선)
	end


	// 데이터 해저드 검출
	// 포워딩 없으니 ID/EX, EX/MEM 둘 다 의존성 있으면 stall
	// MEM/WB -> ID 는 RF 내부 포워딩 (sync write + async read) 으로 자동 처리됨

	// ID/EX 와 충돌? (직전 명령)
	wire idex_use_rs  = (idex_wr_addr == ifid_rs);
	wire idex_use_rt  = (idex_wr_addr == ifid_rt);
	wire idex_hazard  = idex_RegWrite && (idex_wr_addr != 5'd0)
	                    && (idex_use_rs || idex_use_rt);

	// EX/MEM 와 충돌? (두 cycle 전 명령)
	wire exmem_use_rs = (exmem_wr_addr == ifid_rs);
	wire exmem_use_rt = (exmem_wr_addr == ifid_rt);
	wire exmem_hazard = exmem_RegWrite && (exmem_wr_addr != 5'd0)
	                    && (exmem_use_rs || exmem_use_rt);

	wire data_hazard = idex_hazard | exmem_hazard;


	// load-use 스톨
	// 포워딩 미지원이라 load-use 도 결국 위의 data_hazard 에 잡힘
	// 따로 분리할 필요 없음 - data_hazard 면 그냥 stall
	always @(*) begin
		if (data_hazard) begin
			// PC, IF/ID 정지 + ID/EX 를 NOP 으로
			PCWrite     = 1'b0;
			IFIDWrite   = 1'b0;
			IDEX_bubble = 1'b1;
		end
		else begin
			PCWrite     = 1'b1;
			IFIDWrite   = 1'b1;
			IDEX_bubble = 1'b0;
		end
	end


	// 분기/점프 플러시
	// branch_taken | jump_taken -> IF/ID 비우기
	always @(*) begin
		IFID_flush = branch_taken | jump_taken;
	end

endmodule
