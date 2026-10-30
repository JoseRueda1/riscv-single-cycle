// Procesador RISC-V single-cycle (TOP) - version del video (Harris & Harris)
// Instrucciones: ADD SUB AND OR SLT, ADDI, LW SW, BEQ, JAL
module riscv_top #(
    parameter DMEM_WORDS = 16
) (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] pc,        // observacion: contador de programa
    output logic [31:0] instr,     // observacion: instruccion actual
    output logic [31:0] result     // observacion: dato escrito en el banco de registros
);
    logic        reg_write, alu_src, mem_write, branch, jump, zero, pc_src;
    logic [1:0]  imm_src, result_src;
    logic [2:0]  alu_ctrl;
    logic [31:0] pc_next, pc_plus4, pc_target, imm, rd1, rd2, src_b, alu_y, mem_rd;

    // ---------------- Fetch ----------------
    pc_reg u_pc   (.clk, .rst, .pc_next, .pc);
    imem   u_imem (.addr(pc), .instr);
    assign pc_plus4 = pc + 32'd4;

    // ---------------- Decode ----------------
    control_unit u_ctrl (
        .opcode(instr[6:0]), .funct3(instr[14:12]), .funct7_5(instr[30]),
        .reg_write, .imm_src, .alu_src, .mem_write, .result_src, .branch, .jump, .alu_ctrl
    );
    imm_gen u_imm (.instr, .imm_src, .imm);
    regfile u_rf (
        .clk, .we(reg_write), .ra1(instr[19:15]), .ra2(instr[24:20]),
        .wa(instr[11:7]), .wd(result), .rd1, .rd2
    );

    // ---------------- Execute ----------------
    assign src_b = alu_src ? imm : rd2;
    alu u_alu (.a(rd1), .b(src_b), .alu_ctrl, .y(alu_y));
    assign zero = (rd1 == rd2);                 // comparador para BEQ

    // ---------------- Memory ----------------
    dmem #(.WORDS(DMEM_WORDS)) u_dmem (.clk, .we(mem_write), .addr(alu_y), .wd(rd2), .rd(mem_rd));

    // ---------------- Write back ----------------
    always_comb begin
        case (result_src)
            2'd0:    result = alu_y;
            2'd1:    result = mem_rd;
            default: result = pc_plus4;
        endcase
    end

    // ---------------- Siguiente PC ----------------
    assign pc_target = pc + imm;
    assign pc_src    = (branch & zero) | jump;
    assign pc_next   = pc_src ? pc_target : pc_plus4;
endmodule
