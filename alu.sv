// ALU de 32 bits: suma, resta, AND, OR, set-less-than (con signo)
module alu (
    input  logic [31:0] a, b,
    input  logic [2:0]  alu_ctrl,
    output logic [31:0] y
);
    always_comb begin
        case (alu_ctrl)
            3'b000:  y = a + b;                              // ADD
            3'b001:  y = a - b;                              // SUB
            3'b010:  y = a & b;                              // AND
            3'b011:  y = a | b;                              // OR
            3'b101:  y = {31'd0, $signed(a) < $signed(b)};   // SLT
            default: y = 32'd0;
        endcase
    end
endmodule
