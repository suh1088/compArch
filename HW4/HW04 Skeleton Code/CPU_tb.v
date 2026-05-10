`timescale 1ns / 1ps
`include "GLOBAL.v"

module CPU_tb;
	integer i;
	integer FAILED;

    reg clk;
    reg rst;

	wire halt;

	// Final reference state
    reg [31:0] register_file [0:31];
	reg [31:0] memory [0:8191];

	// Shadow state: expected intermediate state after each instruction
	reg [31:0] shadow_rf  [0:31];
	reg [31:0] shadow_mem [0:8191];

	// Saved info from when prev instruction was fetched
	reg [31:0] saved_inst;
	reg [31:0] saved_pc;
	reg [8*8-1:0] saved_inst_name;
	reg first_inst;

	// Temp variables for shadow update
	reg [5:0]  s_op, s_fn;
	reg [4:0]  s_rs, s_rt, s_rd, s_sa;
	reg [15:0] s_imm;
	reg [31:0] s_sign_imm, s_zero_imm;
	reg [31:0] s_rs_val, s_rt_val;
	reg [31:0] s_mem_addr;
	reg [8*8-1:0] inst_name;
	integer mismatch;

    CPU cpu (.clk(clk), .rst(rst), .halt(halt));

	initial begin : REF_INIT
		$readmemh("reference_mem.mem", memory);
		$readmemh("reference_reg.mem", register_file);
		$readmemh("initial_mem.mem",   shadow_mem);
		$readmemh("initial_reg.mem",   shadow_rf);
		first_inst = 1;
		saved_inst = 0;
		saved_pc   = 0;
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
			if (cpu.rf.register_file[i] != register_file[i])
				FAILED = 1;
		end
		for (i = 0; i < 8192; i = i + 1) begin
			if (cpu.mem.memory[i] != memory[i])
				FAILED = 1;
		end

		if (FAILED) begin
			$display("Simulation failed.");
			for (i = 0; i < 32; i = i + 1)
				$display("index: %d, dat: %h, %h", i, cpu.rf.register_file[i], register_file[i]);
		end else
			$display("Simulation success!!!");
		$finish();
    end

	// IF 진입 시마다: 직전 명령어로 shadow 업데이트 후 CPU와 비교
	// always @(posedge clk) begin
	// 	if (!rst && cpu.state == `ST_IF && cpu.inst != 32'b0) begin

	// 		// ── 현재 명령어 이름 디코딩 ──────────────────────────────
	// 		case (cpu.inst[31:26])
	// 			`OP_RTYPE: begin
	// 				case (cpu.inst[5:0])
	// 					`FUNCT_ADDU: inst_name = "ADDU    ";
	// 					`FUNCT_SUBU: inst_name = "SUBU    ";
	// 					`FUNCT_AND:  inst_name = "AND     ";
	// 					`FUNCT_OR:   inst_name = "OR      ";
	// 					`FUNCT_XOR:  inst_name = "XOR     ";
	// 					`FUNCT_NOR:  inst_name = "NOR     ";
	// 					`FUNCT_SLT:  inst_name = "SLT     ";
	// 					`FUNCT_SLTU: inst_name = "SLTU    ";
	// 					`FUNCT_SLL:  inst_name = "SLL     ";
	// 					`FUNCT_SRL:  inst_name = "SRL     ";
	// 					`FUNCT_SRA:  inst_name = "SRA     ";
	// 					`FUNCT_JR:   inst_name = "JR      ";
	// 					default:     inst_name = "R-UNKNWN";
	// 				endcase
	// 			end
	// 			`OP_J:     inst_name = "J       ";
	// 			`OP_JAL:   inst_name = "JAL     ";
	// 			`OP_BEQ:   inst_name = "BEQ     ";
	// 			`OP_BNE:   inst_name = "BNE     ";
	// 			`OP_ADDIU: inst_name = "ADDIU   ";
	// 			`OP_SLTI:  inst_name = "SLTI    ";
	// 			`OP_SLTIU: inst_name = "SLTIU   ";
	// 			`OP_ANDI:  inst_name = "ANDI    ";
	// 			`OP_ORI:   inst_name = "ORI     ";
	// 			`OP_XORI:  inst_name = "XORI    ";
	// 			`OP_LUI:   inst_name = "LUI     ";
	// 			`OP_LW:    inst_name = "LW      ";
	// 			`OP_SW:    inst_name = "SW      ";
	// 			default:   inst_name = "UNKNOWN ";
	// 		endcase

	// 		// ── 직전 명령어로 shadow 상태 업데이트 ───────────────────
	// 		if (!first_inst) begin
	// 			s_op       = saved_inst[31:26];
	// 			s_rs       = saved_inst[25:21];
	// 			s_rt       = saved_inst[20:16];
	// 			s_rd       = saved_inst[15:11];
	// 			s_sa       = saved_inst[10:6];
	// 			s_fn       = saved_inst[5:0];
	// 			s_imm      = saved_inst[15:0];
	// 			s_sign_imm = {{16{s_imm[15]}}, s_imm};
	// 			s_zero_imm = {16'b0, s_imm};
	// 			s_rs_val   = shadow_rf[s_rs];
	// 			s_rt_val   = shadow_rf[s_rt];
	// 			s_mem_addr = (s_rs_val + s_sign_imm) >> 2; // byte → word index

	// 			case (s_op)
	// 				`OP_RTYPE: begin
	// 					case (s_fn)
	// 						`FUNCT_ADDU: shadow_rf[s_rd] = s_rs_val + s_rt_val;
	// 						`FUNCT_SUBU: shadow_rf[s_rd] = s_rs_val - s_rt_val;
	// 						`FUNCT_AND:  shadow_rf[s_rd] = s_rs_val & s_rt_val;
	// 						`FUNCT_OR:   shadow_rf[s_rd] = s_rs_val | s_rt_val;
	// 						`FUNCT_XOR:  shadow_rf[s_rd] = s_rs_val ^ s_rt_val;
	// 						`FUNCT_NOR:  shadow_rf[s_rd] = ~(s_rs_val | s_rt_val);
	// 						`FUNCT_SLT:  shadow_rf[s_rd] = ($signed(s_rs_val) < $signed(s_rt_val)) ? 32'd1 : 32'd0;
	// 						`FUNCT_SLTU: shadow_rf[s_rd] = (s_rs_val < s_rt_val) ? 32'd1 : 32'd0;
	// 						`FUNCT_SLL:  shadow_rf[s_rd] = s_rt_val << s_sa;
	// 						`FUNCT_SRL:  shadow_rf[s_rd] = s_rt_val >> s_sa;
	// 						`FUNCT_SRA:  shadow_rf[s_rd] = $signed(s_rt_val) >>> s_sa;
	// 						// JR: no register write
	// 					endcase
	// 				end
	// 				`OP_ADDIU: shadow_rf[s_rt] = s_rs_val + s_sign_imm;
	// 				`OP_SLTI:  shadow_rf[s_rt] = ($signed(s_rs_val) < $signed(s_sign_imm)) ? 32'd1 : 32'd0;
	// 				`OP_SLTIU: shadow_rf[s_rt] = (s_rs_val < s_sign_imm) ? 32'd1 : 32'd0;
	// 				`OP_ANDI:  shadow_rf[s_rt] = s_rs_val & s_zero_imm;
	// 				`OP_ORI:   shadow_rf[s_rt] = s_rs_val | s_zero_imm;
	// 				`OP_XORI:  shadow_rf[s_rt] = s_rs_val ^ s_zero_imm;
	// 				`OP_LUI:   shadow_rf[s_rt] = {s_imm, 16'b0};
	// 				`OP_LW:    shadow_rf[s_rt] = shadow_mem[s_mem_addr];
	// 				`OP_SW:    shadow_mem[s_mem_addr] = s_rt_val;
	// 				`OP_JAL:   shadow_rf[31] = saved_pc + 4;
	// 				// BEQ, BNE, J, JR: PC 변경만 있고 레지스터/메모리 변화 없음
	// 			endcase
	// 			shadow_rf[0] = 32'b0; // $zero는 항상 0

	// 			// ── 비교 ───────────────────────────────────────────────
	// 			mismatch = 0;
	// 			for (i = 0; i < 32; i = i + 1)
	// 				if (cpu.rf.register_file[i] !== shadow_rf[i]) mismatch = 1;
	// 			for (i = 0; i < 8192; i = i + 1)
	// 				if (cpu.mem.memory[i] !== shadow_mem[i]) mismatch = 1;

	// 			if (mismatch) begin
	// 				$display("[%0t] MISMATCH after PC=%08h  INST=%08h  [%s]",
	// 					$time, saved_pc, saved_inst, saved_inst_name);
	// 				for (i = 0; i < 32; i = i + 1)
	// 					if (cpu.rf.register_file[i] !== shadow_rf[i])
	// 						$display("  !! $%02d = %08h  (expected %08h)",
	// 							i, cpu.rf.register_file[i], shadow_rf[i]);
	// 				for (i = 0; i < 8192; i = i + 1)
	// 					if (cpu.mem.memory[i] !== shadow_mem[i])
	// 						$display("  !! MEM[%0d] = %08h  (expected %08h)",
	// 							i, cpu.mem.memory[i], shadow_mem[i]);
	// 			end
	// 		end

	// 		// ── 현재 명령어 저장 (다음 IF 때 비교용) ─────────────────
	// 		saved_inst      = cpu.inst;
	// 		saved_pc        = cpu.PC;
	// 		saved_inst_name = inst_name;
	// 		first_inst      = 0;
	// 	end
	// end

endmodule
