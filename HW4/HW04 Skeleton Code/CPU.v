`timescale 1ns / 1ps
`include "GLOBAL.v"


module CPU(
	input		clk,
	input		rst,
	output 		halt
	);
	
	// Split the instructions
	// Instruction-related wires
	wire [31:0]		inst;
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
	wire			Jump;
	wire 			Branch;
	wire 			JR;
	wire			MemRead;
	wire			MemtoReg;
	wire 			MemWrite;
	wire			ALUSrc;
	wire			SignExtend;
	wire			RegWrite;
	wire [3:0]		ALUOp;
	wire			SavePC;

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

	// ALU-related wires
	wire [31:0]		operand1;
	wire [31:0]		operand2;
	wire [31:0]		alu_result;

	// Define PC
	reg [31:0]	PC;
	reg [31:0]	PC_next;

	// Define the wires

	assign halt				= (inst == 32'b0);



   // 할당 시작

	// inst;
	assign opcode = inst[31:26];
	assign rs = inst[25:21];
	assign rt = inst[20:16];
	assign rd = inst[15:11];
	assign shamt = inst[10:6];
	assign funct = inst[5:0];
	assign immi = inst[15:0];
	assign immj = inst[25:0];

	// Sign extend the immediate 
	// trouble shooting
	assign ext_imm = SignExtend ? {{16{immi[15]}}, immi} : {16'b0, immi};

	// RF-related wires4
	assign rd_addr1 = rs;
	assign rd_addr2 = rt;

	// MEM-related wires
	assign mem_addr = alu_result;
	assign mem_write_data = rd_data2;

	// ALU-related wires
	assign operand1 = rd_data1;
	assign operand2 = ALUSrc ? ext_imm : rd_data2;



	always @(*) begin
		wr_addr = SavePC ? 5'b11111 : (RegDst ? rd : rt);
		wr_data = SavePC ? PC+4 : (MemtoReg ? mem_read_data : alu_result);

		// Define PC
		// PC;
		// PC_next;
		
		if(Jump)begin
			if(JR) begin //trouble shooting
			PC_next = rd_data1;
			end
			else begin
				PC_next = {(PC[31:28]), immj, 2'b00};
			end
		end
		else begin
			if(Branch && alu_result) begin // 이 부분 확인 필요
				PC_next = PC + 4 + (ext_imm << 2); 
			end
			else begin
				PC_next = PC + 4;
			end
		end

	end


	// Update the Clock
	always @(posedge clk) begin
		if (rst)	PC <= 0;
		else begin
			PC <= PC_next;
		end
	end
	

	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		.RegDst(RegDst),
		.Jump(Jump),
		.Branch(Branch),
		.JR(JR),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.ALUSrc(ALUSrc),
		.SignExtend(SignExtend),
		.RegWrite(RegWrite),
		.ALUOp(ALUOp),
		.SavePC(SavePC)
	);

	RF rf (
		.clk(clk),
		.rst(rst),
		.rd_addr1(rd_addr1),
		.rd_addr2(rd_addr2),
		.rd_data1(rd_data1),
		.rd_data2(rd_data2),
		.RegWrite(RegWrite),
		.wr_addr(wr_addr),
		.wr_data(wr_data)
	);

	MEM mem (
		.clk(clk),
		.rst(rst),
		.inst_addr(PC),
		.inst(inst),
		.mem_addr(mem_addr),
		.MemWrite(MemWrite),
		.mem_write_data(mem_write_data),
		.mem_read_data(mem_read_data)
	);

	ALU alu (
		.operand1(operand1),
		.operand2(operand2),
		.shamt(shamt),
		.funct(ALUOp),
		.alu_result(alu_result)
	);
	
endmodule
