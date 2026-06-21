`include "ctrl_signal_def.v"
module Flopr(clk,rst,in_data,out_data );
    input clk;
    input rst;
    input [31:0] in_data;
    output reg [31:0] out_data;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            out_data <= 0;
        end
        else begin
            out_data <= in_data;
        end
    end
endmodule