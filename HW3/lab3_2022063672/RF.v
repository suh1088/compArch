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
	always @(*) begin
		// if(RegWrite && rd_addr1 == wr_addr)
		// 	rd_data1 = wr_data;
		// else
		rd_data1 = register_file[rd_addr1];
		

		// if(RegWrite && rd_addr2 == wr_addr)
		// 	rd_data2 = wr_data;
		// else
		rd_data2 = register_file[rd_addr2];
		
	end
	// assign ??
    
	//synchronous - write
	always @(posedge clk) begin
		if (rst) begin
			$readmemh("initial_reg.mem", register_file); //제출 전 삭제
		end

		// FILL what happens synchronously
		else if(RegWrite) register_file[wr_addr] <= wr_data;
	end

endmodule
