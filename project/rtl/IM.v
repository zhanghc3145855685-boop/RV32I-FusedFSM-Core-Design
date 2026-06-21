`timescale 1ns / 1ps
`include "ctrl_signal_def.v"
module IM(clk, InsMemRW, addr, Ins);
    input          clk, InsMemRW;
    input  [11:2]  addr;
    output reg [31:0] Ins;
    reg [31:0] memory[0:1023];

    always @(posedge clk) begin
        if (InsMemRW) begin
            Ins <= memory[addr];
        end
    end
endmodule