// Banco de registros 32 x 32: 2 lecturas combinacionales, 1 escritura sincrona. x0 siempre es 0.
module regfile (
    input  logic        clk,
    input  logic        we,
    input  logic [4:0]  ra1, ra2, wa,
    input  logic [31:0] wd,
    output logic [31:0] rd1, rd2
);
    logic [31:0] regs [1:31];
    always_ff @(posedge clk)
        if (we && wa != 5'd0) regs[wa] <= wd;
    assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];
endmodule
