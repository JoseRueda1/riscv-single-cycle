`timescale 1ns/1ps
// Testbench autoverificable: ejecuta el programa de prueba y compara TODOS los registros y la memoria
// de datos contra los valores esperados calculados por un simulador de referencia (gen_program.py).
module tb_riscv_top;
    logic clk = 0, rst = 1;
    logic [31:0] pc, instr, result;
    integer errores = 0, ciclos = 0;

    riscv_top #(.DMEM_WORDS(16)) dut (.clk, .rst, .pc, .instr, .result);

    always #50 clk = ~clk;   // 100 MHz

    `include "expected.svh"

    initial begin
`ifdef FSDB
        $fsdbDumpfile("dump_riscv.fsdb");
        $fsdbDumpvars(0, tb_riscv_top);
`elsif VCD
        $dumpfile("dump_riscv.vcd");
        $dumpvars(0, tb_riscv_top);
`endif
        repeat (2) @(posedge clk);
        #1 rst = 0;
        // Esperar a que el PC llegue al bucle final (END_PC) o agotar el tiempo
        while (pc !== END_PC && ciclos < 2000) begin @(posedge clk); ciclos++; end
        repeat (3) @(posedge clk);
        #1;
        if (pc !== END_PC) begin $display("ERROR: el PC no llego a END_PC (pc=%0d)", pc); errores++; end
        for (int i = 1; i < 32; i++) begin
            // registros que el programa nunca escribe quedan en X en simulacion (esperado 0): se omiten
            if (!(EXP_REG[i] === 32'd0 && ^dut.u_rf.regs[(31-(i))*32 +: 32] === 1'bx) && dut.u_rf.regs[(31-(i))*32 +: 32] !== EXP_REG[i]) begin
                $display("ERROR x%0d: obtenido %h esperado %h", i, dut.u_rf.regs[(31-(i))*32 +: 32], EXP_REG[i]);
                errores++;
            end
        end
        for (int i = 0; i < 16; i++) begin
            if (EXP_MEM[i] !== 32'd0 || ^dut.u_dmem.mem[(15-(i))*32 +: 32] !== 1'bx) begin
                if (dut.u_dmem.mem[(15-(i))*32 +: 32] !== EXP_MEM[i]) begin
                    $display("ERROR mem[%0d]: obtenido %h esperado %h", i, dut.u_dmem.mem[(15-(i))*32 +: 32], EXP_MEM[i]);
                    errores++;
                end
            end
        end
        $display("Instrucciones ejecutadas hasta END_PC: %0d ciclos", ciclos);
        $display("x3=%0d x4=%0d x27(suma 1..10)=%0d mem[2]=%0d x30(saltos)=%0d x31=%0d",
                 dut.u_rf.regs[(31-(3))*32 +: 32], dut.u_rf.regs[(31-(4))*32 +: 32], dut.u_rf.regs[(31-(27))*32 +: 32], dut.u_dmem.mem[(15-(2))*32 +: 32],
                 dut.u_rf.regs[(31-(30))*32 +: 32], dut.u_rf.regs[(31-(31))*32 +: 32]);
        $display("Errores: %0d  (registros escritos + memoria de datos)", errores);
        $finish;
    end
endmodule
