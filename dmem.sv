// Memoria de datos de WORDS palabras de 32 bits (lectura combinacional, escritura sincrona)
module dmem #(parameter WORDS = 16) (
    input  logic        clk,
    input  logic        we,
    input  logic [31:0] addr,
    input  logic [31:0] wd,
    output logic [31:0] rd
);
    localparam AW = $clog2(WORDS);
    logic [31:0] mem [0:WORDS-1];
    wire [AW-1:0] idx = addr[AW+1:2];
    always_ff @(posedge clk)
        if (we) mem[idx] <= wd;
    assign rd = mem[idx];
endmodule
