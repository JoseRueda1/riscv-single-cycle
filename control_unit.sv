// Unidad de control: decodificador principal + decodificador de ALU
module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    output logic       reg_write,
    output logic [1:0] imm_src,
    output logic       alu_src,     // 0=rs2, 1=inmediato
    output logic       mem_write,
    output logic [1:0] result_src,  // 0=ALU 1=memoria 2=PC+4
    output logic       branch,
    output logic       jump,
    output logic [2:0] alu_ctrl
);
    logic [1:0] alu_op;   // 0=suma  1=resta (beq)  2=tipo R

    always_comb begin
        reg_write = 0; imm_src = 2'd0; alu_src = 0; mem_write = 0;
        result_src = 2'd0; branch = 0; jump = 0; alu_op = 2'd0;
        case (opcode)
            7'b0110011: begin reg_write = 1; alu_op = 2'd2; end                         // tipo R
            7'b0010011: begin reg_write = 1; alu_src = 1; end                           // ADDI
            7'b0000011: begin reg_write = 1; alu_src = 1; result_src = 2'd1; end        // LW
            7'b0100011: begin imm_src = 2'd1; alu_src = 1; mem_write = 1; end           // SW
            7'b1100011: begin imm_src = 2'd2; branch = 1; alu_op = 2'd1; end            // BEQ
            7'b1101111: begin reg_write = 1; imm_src = 2'd3; jump = 1; result_src = 2'd2; end // JAL
            default: ;
        endcase
    end

    always_comb begin
        case (alu_op)
            2'd0:    alu_ctrl = 3'b000;
            2'd1:    alu_ctrl = 3'b001;
            default: begin
                case (funct3)
                    3'b000:  alu_ctrl = funct7_5 ? 3'b001 : 3'b000;  // SUB / ADD
                    3'b010:  alu_ctrl = 3'b101;                      // SLT
                    3'b110:  alu_ctrl = 3'b011;                      // OR
                    3'b111:  alu_ctrl = 3'b010;                      // AND
                    default: alu_ctrl = 3'b000;
                endcase
            end
        endcase
    end
endmodule
