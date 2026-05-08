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
	wire			ALUSrcA;
	wire [1:0]		ALUSrcB;
	wire [1:0]		PCSource;
	wire			IRWrite;
	wire			IorD;
	wire			PCWrite;
	wire			PCWriteCond;

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

	// state 추가!!!!
	reg [2:0] state;
	wire [2:0] state_next;  // (reg → wire 변경) 이부분 다시한번 확인

	// 멀티사이클을 위한 중간 래지스터
	reg [31:0]		inst;
	reg [31:0]		mem_data_reg;
	reg [31:0]		A;
	reg [31:0]		B;
	reg [31:0]		ALUOut;

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

	// Define the wires

	assign halt				= (inst == 32'b0);

	//멀티사이클!! 할당 시작 !!! 여기서부터 구현 시작
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


   	// 싱글 사이클!! 할당 시작

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
		// ALU 공유!!
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
			if(Branch && alu_result) begin 
				// ALU 공유!!
				PC_next = PC + 4 + (ext_imm << 2); 
			end
			else begin
				// ALU 공유!!
				PC_next = PC + 4;
			end
		end

	end


	// Update the Clock
	always @(posedge clk) begin
		if (rst) begin
			PC <= 0;
			state <= 0;
		end
		else begin
			//PC <= PC_next;
			state <= state_next;
		end
	end
	
	

	CTRL ctrl (
		.opcode(opcode),
		.funct(funct),
		.state(state),
		.state_next(state_next),
		.RegDst(RegDst),
		.JR(JR),
		.MemRead(MemRead),
		.MemtoReg(MemtoReg),
		.MemWrite(MemWrite),
		.SignExtend(SignExtend),
		.RegWrite(RegWrite),
		.ALUOp(ALUOp),
		.SavePC(SavePC),
		.ALUSrcA(ALUSrcA),
		.ALUSrcB(ALUSrcB),
		.PCSource(PCSource),
		.IRWrite(IRWrite),
		.IorD(IorD),
		.PCWrite(PCWrite),
		.PCWriteCond(PCWriteCond)
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
