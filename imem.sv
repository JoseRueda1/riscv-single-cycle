// ROM de instrucciones (generada por gen_program.py). Programa de prueba RV32I.
module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    always_comb begin
        case (addr[31:2])
            30'd0: instr = 32'h00a00093;
            30'd1: instr = 32'h00500113;
            30'd2: instr = 32'h002081b3;
            30'd3: instr = 32'h40208233;
            30'd4: instr = 32'h0020f2b3;
            30'd5: instr = 32'h0020e333;
            30'd6: instr = 32'h001123b3;
            30'd7: instr = 32'h0020a433;
            30'd8: instr = 32'hffd00493;
            30'd9: instr = 32'h0014a533;
            30'd10: instr = 32'h401105b3;
            30'd11: instr = 32'h00302023;
            30'd12: instr = 32'h00402223;
            30'd13: instr = 32'h00002603;
            30'd14: instr = 32'h00402683;
            30'd15: instr = 32'h00000f13;
            30'd16: instr = 32'h00000f93;
            30'd17: instr = 32'h00108463;
            30'd18: instr = 32'h064f0f13;
            30'd19: instr = 32'h001f0f13;
            30'd20: instr = 32'h02208263;
            30'd21: instr = 32'h002f0f13;
            30'd22: instr = 32'h00220463;
            30'd23: instr = 32'h064f0f13;
            30'd24: instr = 32'h004f0f13;
            30'd25: instr = 32'h00800d6f;
            30'd26: instr = 32'h064f8f93;
            30'd27: instr = 32'h007f8f93;
            30'd28: instr = 32'h00c0006f;
            30'd29: instr = 32'hfff00f13;
            30'd30: instr = 32'hffdff06f;
            30'd31: instr = 32'h00000d93;
            30'd32: instr = 32'h00a00e13;
            30'd33: instr = 32'h000e0863;
            30'd34: instr = 32'h01cd8db3;
            30'd35: instr = 32'hfffe0e13;
            30'd36: instr = 32'hff5ff06f;
            30'd37: instr = 32'h01b02423;
            30'd38: instr = 32'h00802e83;
            30'd39: instr = 32'h01e02623;
            30'd40: instr = 32'h0000006f;
            default: instr = 32'h00000013; // NOP
        endcase
    end
endmodule
