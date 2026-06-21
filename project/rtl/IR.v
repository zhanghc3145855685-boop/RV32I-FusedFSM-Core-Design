`include "ctrl_signal_def.v"
module IR(in_ins, clk, IRWrite, out_ins);
    input          clk, IRWrite;
    input [31:0]   in_ins;
    output reg[31:0] out_ins;

    always @(posedge clk) begin
        if (IRWrite) begin
            out_ins <= in_ins;
        end
    end
endmodule