`timescale 1ns / 100ps

module RF (
	// You may also change the input and output ports (maybe changing reg to wire)
		input clk,
		input rst,
		// Read-related ports
		input [4:0] rd_addr1,
		input [4:0] rd_addr2,
		output reg [31:0] rd_data1,
		output reg [31:0] rd_data2,
		// Write-related ports
		input RegWrite,
		input [4:0] wr_addr,
		input [31:0] wr_data
	);

    reg [31:0] register_file [0:31];

	
	// Fill in the asynchronous functions - read
	// 내부 포워딩 활성화 : 같은 cycle WB write 와 ID read 가 겹칠 때 새 값 반환
	// 파이프라인에서 MEM/WB -> ID hazard 해결에 필요  // troubleshooting
	// 예전에 주석처리 해뒀었음.
	always @(*) begin
		if(RegWrite && rd_addr1 == wr_addr && wr_addr != 5'd0)	// troubleshooting
			rd_data1 = wr_data;
		else
			rd_data1 = register_file[rd_addr1];


		if(RegWrite && rd_addr2 == wr_addr && wr_addr != 5'd0)	// troubleshooting
			rd_data2 = wr_data;
		else
			rd_data2 = register_file[rd_addr2];

	end
	// assign ??

	//synchronous - write
	// $0 은 항상 0 -> wr_addr=0 일 땐 write skip  // troubleshooting
	always @(posedge clk) begin
		if (rst) begin
			$readmemh("initial_reg.mem", register_file); //제출 전 삭제
		end

		// FILL what happens synchronously
		else if(RegWrite && wr_addr != 5'd0) register_file[wr_addr] <= wr_data;	// troubleshooting
	end

endmodule
