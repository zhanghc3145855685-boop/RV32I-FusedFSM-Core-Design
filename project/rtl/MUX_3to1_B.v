`include "ctrl_signal_def.v"
module MUX_3to1_B(X,Y,Z,control,out);
    input [31:0] X;
    input [31:0] Y;
    input [11:0] Z;
    input [1:0]  control;
    output reg signed [31:0] out;

    always @ (X or Y or Z or control) begin
        case(control)
            `ALUSrcB_B      : out = X;
            `ALUSrcB_Imm    : out = Y;
            `ALUSrcB_Offset : out = $signed(Z);
            `ALUSrcB_else   : out = X;
        endcase
    end
endmodule