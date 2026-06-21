`include "global_def.v"
`include "ctrl_signal_def.v"

module RF(
    input [4:0] RR1,
    input [4:0] RR2,
    input [4:0] WR,
    input [31:0] WD,
    input RFWrite,
    input clk,
    output [31:0] RD1,
    output [31:0] RD2
);
    reg [31:0] register [0:31];

    //always @(clk) begin
    //    register[0] = 32'h0;
    //end

    always @(posedge clk) begin
        if ((WR != 0) && (RFWrite == 1)) begin
            register[WR] <= WD;
            `ifdef DEBUG
                $display("R[00-07]=%8X %8X %8X %8X %8X %8X %8X %8X", 0, register[1], register[2], register[3], register[4], register[5], register[6], register[7]);
                $display("R[08-15]=%8X %8X %8X %8X %8X %8X %8X %8X", register[8], register[9], register[10], register[11], register[12], register[13], register[14], register[15]);
                $display("R[16-23]=%8X %8X %8X %8X %8X %8X %8X %8X", register[16], register[17], register[18], register[19], register[20], register[21], register[22], register[23]);
                $display("R[24-31]=%8X %8X %8X %8X %8X %8X %8X %8X", register[24], register[25], register[26], register[27], register[28], register[29], register[30], register[31]);
            `endif
        end
    end

    assign RD1 = (RR1 == 5'b00000) ? 32'h0 : register[RR1];
    assign RD2 = (RR1 == 5'b00000) ? 32'h0 : register[RR2];
endmodule