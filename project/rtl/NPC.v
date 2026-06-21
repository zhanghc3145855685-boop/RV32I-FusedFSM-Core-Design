`include "ctrl_signal_def.v"
`include "instruction_def.v"
module NPC(rs_target, NPCop,Offset12,Offset20,PC,rs,PCA4, NPC);
    input [1:0]  NPCop;
    input [12:1] Offset12;
    input [20:1] Offset20;
    input [31:0] PC;
    input [31:0] rs;
    input [31:0] rs_target;
    output reg [31:0] PCA4;
    output reg [31:0] NPC;

    wire signed [12:0] Offset13;
    wire signed [20:0] Offset21;

    assign Offset13 = $signed({Offset12[12:1],1'b0});
    assign Offset21 = $signed({Offset20[20:1],1'b0});

    always@(*) begin
        case(NPCop)
            `NPC_PC       : NPC = PC + 4;
            `NPC_Offset12 : NPC = $signed({1'b0,PC}) + $signed(Offset13);
            `NPC_rs       : NPC = {rs_target[31:2], 2'b0};
            `NPC_Offset20 : NPC = $signed({1'b0,PC}) + $signed(Offset21);
        endcase
        PCA4 = PC + 4;
    end
endmodule