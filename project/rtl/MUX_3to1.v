`include "ctrl_signal_def.v"
module MUX_3to1(X,Y,Z,control,out);
    input [4:0] X;
    input [4:0] Y;
    input [4:0] Z;
    input [1:0] control;
    output reg[4:0] out;

    always @ (X or Y or Z or control) begin
        case(control)
            `RegSel_rd : out = X;
            `RegSel_rt : out = Y;
            `RegSel_31 : out = Z;
            `RegSel_else : out = 0;
        endcase
    end
endmodule