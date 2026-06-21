`include "ctrl_signal_def.v"
module DM( Addr,WD,clk,DMCtrl,RD);
    input  [11:2] Addr;
    input  [31:0] WD;
    input  clk;
    input  DMCtrl;
    output reg [31:0] RD;

    reg [31:0] memory[0:1023];
    always @(posedge clk) begin
        if (DMCtrl) begin
            memory[Addr] <= WD;
        end
        else begin
            RD <= memory[Addr];
        end
    end
endmodule