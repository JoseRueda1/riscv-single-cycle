// Generador de inmediatos: I (addi, lw), S (sw), B (beq), J (jal)
module imm_gen (
    input  logic [31:0] instr,
    input  logic [1:0]  imm_src,   // 0=I 1=S 2=B 3=J
    output logic [31:0] imm
);
    always_comb begin
        case (imm_src)
            2'd0: imm = {{20{instr[31]}}, instr[31:20]};
            2'd1: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            2'd2: imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            default: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        endcase
    end
endmodule
