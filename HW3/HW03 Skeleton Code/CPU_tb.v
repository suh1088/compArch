`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU_tb;
	integer i;
	integer FAILED;
	reg [8*8-1:0] inst_name;

    reg clk;
    reg rst;
    
	wire halt;

	// Have the reference register & mem
    reg [31:0] register_file [0:31];
	reg [31:0] memory [0:8191];

    CPU cpu (.clk(clk), .rst(rst), .halt(halt));

	initial begin : REF_INIT
		$readmemh("reference_mem.mem", memory);
		$readmemh("reference_reg.mem", register_file);
	end
    

    initial begin : CLOCK_GENERATOR
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    initial begin : Settings
		FAILED = 0;
        rst = 1;
        #15
        rst = 0;
		@(posedge halt);
		$display("Program Terminate\n");

		for (i = 0; i < 32; i = i + 1) begin
			if (cpu.rf.register_file[i] != register_file[i]) begin
				FAILED = 1;
			end
		end
		for (i = 0; i < 8192; i = i + 1) begin
			if (cpu.mem.memory[i] != memory[i]) begin
				FAILED = 1;
			end
		end

		if (FAILED) begin
			$display("Simulation failed.");
			for (i = 0; i < 32; i = i + 1) begin
				$display("index: %d, dat: %h, %h", i, cpu.rf.register_file[i], register_file[i]);
			end
		end
		else
			$display("Simulation success!!!");
		$finish();
    end

	// Print instruction name and registers on each clock
	always @(posedge clk) begin
		if (!rst && !halt) begin
			// Decode instruction name
			case (cpu.opcode)
				`OP_RTYPE: begin
					case (cpu.funct)
						`FUNCT_ADDU: inst_name = "ADDU    ";
						`FUNCT_SUBU: inst_name = "SUBU    ";
						`FUNCT_AND:  inst_name = "AND     ";
						`FUNCT_OR:   inst_name = "OR      ";
						`FUNCT_XOR:  inst_name = "XOR     ";
						`FUNCT_NOR:  inst_name = "NOR     ";
						`FUNCT_SLT:  inst_name = "SLT     ";
						`FUNCT_SLTU: inst_name = "SLTU    ";
						`FUNCT_SLL:  inst_name = "SLL     ";
						`FUNCT_SRL:  inst_name = "SRL     ";
						`FUNCT_SRA:  inst_name = "SRA     ";
						`FUNCT_JR:   inst_name = "JR      ";
						default:     inst_name = "R-UNKNWN";
					endcase
				end
				`OP_J:     inst_name = "J       ";
				`OP_JAL:   inst_name = "JAL     ";
				`OP_BEQ:   inst_name = "BEQ     ";
				`OP_BNE:   inst_name = "BNE     ";
				`OP_ADDIU: inst_name = "ADDIU   ";
				`OP_SLTI:  inst_name = "SLTI    ";
				`OP_SLTIU: inst_name = "SLTIU   ";
				`OP_ANDI:  inst_name = "ANDI    ";
				`OP_ORI:   inst_name = "ORI     ";
				`OP_XORI:  inst_name = "XORI    ";
				`OP_LUI:   inst_name = "LUI     ";
				`OP_LW:    inst_name = "LW      ";
				`OP_SW:    inst_name = "SW      ";
				default:   inst_name = "UNKNOWN ";
			endcase

			$display("=== PC=%08h  INST=%08h  [%s] ===", cpu.PC, cpu.inst, inst_name);
			$display("  rs=$%0d=%08h  rt=$%0d=%08h  rd=$%0d", cpu.rs, cpu.rd_data1, cpu.rt, cpu.rd_data2, cpu.rd);
			$display("  Registers:");
			for (i = 0; i < 32; i = i + 1) begin
				$display("    $%02d = %08h", i, cpu.rf.register_file[i]);
			end
		end
	end

endmodule
