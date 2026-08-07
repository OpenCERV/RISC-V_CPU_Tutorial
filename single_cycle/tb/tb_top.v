`timescale 1ns/1ps

// Tutorial wrapper around the upstream RV32I_Single_Cycle top module.
// The core itself is copied from RISCV_core_rv32i; this file only supplies
// clock/reset, waveform capture, and beginner-friendly checks.
module tb_top;
    reg clk = 1'b0;
    reg rst = 1'b1;
    wire [31:0] pc;
    wire [31:0] instr;
    wire ebreak_pulse;
    integer cycles;
    integer errors;

    top uut (
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .instr(instr),
        .ebreak_pulse(ebreak_pulse)
    );

    always #5 clk = ~clk;

    task check_reg;
        input integer index;
        input [31:0] expected;
        begin
            if (uut.u_regfile.regs[index] !== expected) begin
                $display("[FAIL] x%0d = 0x%08x, expected 0x%08x",
                         index, uut.u_regfile.regs[index], expected);
                errors = errors + 1;
            end else begin
                $display("[PASS] x%0d = %0d", index, expected);
            end
        end
    endtask

    initial begin
        $dumpfile("build/cpu.vcd");
        $dumpvars(0, tb_top);
        errors = 0;

        // The upstream PC and register file use synchronous reset.
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // The demo ends in a JAL self-loop. Check after it has settled.
        repeat (100) @(posedge clk);
        #1;

        check_reg(0,  32'd0);
        check_reg(1,  32'd5);
        check_reg(2,  32'd7);
        check_reg(3,  32'd12);
        check_reg(4,  32'd2);
        check_reg(5,  32'h1000_0000);
        check_reg(6,  32'd12);
        check_reg(7,  32'd42);
        check_reg(8,  32'd3);
        check_reg(9,  32'd3);
        check_reg(10, 32'd84);
        check_reg(11, 32'd42);
        check_reg(12, 32'd108);
        check_reg(13, 32'd104);
        check_reg(14, 32'd42);
        check_reg(15, 32'd5);
        check_reg(16, 32'd7);
        check_reg(17, 32'd2);
        check_reg(18, 32'd1);
        check_reg(19, 32'd10);
        check_reg(20, 32'd3);

        if (uut.u_MEM.dmem[0] !== 8'h0c ||
            uut.u_MEM.dmem[1] !== 8'h00 ||
            uut.u_MEM.dmem[2] !== 8'h00 ||
            uut.u_MEM.dmem[3] !== 8'h00) begin
            $display("[FAIL] data memory at 0x10000000 is not 12");
            errors = errors + 1;
        end else begin
            $display("[PASS] memory[0x10000000] = 12");
        end

        if (errors == 0)
            $display("PASS: upstream single-cycle RV32I tutorial program completed");
        else
            $display("FAIL: %0d checks failed", errors);

        $finish;
    end
endmodule
