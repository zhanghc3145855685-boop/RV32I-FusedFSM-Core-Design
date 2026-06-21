`include "ctrl_signal_def.v"

module ALU(A, B, ALUOp, ALU_result, zero);
    input [31:0] A;
    input [31:0] B;
    input [3:0]  ALUOp;
    output reg [31:0] ALU_result;
    output zero;

	assign zero = ~(|(A ^ B));

    always @(*) begin
        case(ALUOp)
            `ALUOp_ADD : ALU_result = A + B;
            `ALUOp_SUB : ALU_result = A - B;
            `ALUOp_AND : ALU_result = A & B;
            `ALUOp_OR  : ALU_result = A | B;
            `ALUOp_XOR : ALU_result = A ^ B;
            `ALUOp_SLL : ALU_result = A << B[4:0];
            `ALUOp_SRL : ALU_result = A >> B[4:0];
            `ALUOp_SRA : ALU_result = $signed(A) >>> B[4:0];
			`ALUOp_BR  : ALU_result = (A==B) ? 32'd1 : 32'd0;
            default    : ALU_result = 32'b0;
        endcase
    end
endmodule