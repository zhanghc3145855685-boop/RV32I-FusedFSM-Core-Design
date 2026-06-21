`include "ctrl_signal_def.v"
module EXT(sw_imm_in, imm_in, ExtSel, imm_out);
    input [11:0]       imm_in;
    input [11:0]       sw_imm_in;
    input              ExtSel;
    output reg[31:0]   imm_out;

    always@(imm_in or ExtSel) begin
        case(ExtSel)
            `ExtSel_ZERO  :imm_out = {20'b0,imm_in[11:0]};
            `ExtSel_SIGNED:imm_out = {{20{sw_imm_in[11]}}, sw_imm_in};
            default       :imm_out = 32'b0;
        endcase
    end
endmodule