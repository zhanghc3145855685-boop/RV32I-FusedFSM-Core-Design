`timescale 1ns / 1ps
`include "ctrl_signal_def.v"
`include "instruction_def.v"

module ControlUnit(
    input clk,
    input rst,
    input zero,
    input [6:0] in_ins,
    input [6:0] opcode,
    input [6:0] Funct7,
    input [2:0] Funct3,
    output reg RFWrite,
    output reg DMCtrl,
    output reg PCWrite,
    output reg IRWrite,
    output reg InsMemRW,
    output reg ExtSel,
    output reg [3:0] ALUOp,
    output reg [1:0] NPCOp,
    output ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg [1:0] RegSel,
    output reg [1:0] WDSel
);

    // 状态定义
    parameter IF  = 3'b000;
    parameter DAE = 3'b001;
    parameter WB  = 3'b010;
    parameter MEM = 3'b011;
    parameter IT  = 3'b101;

    reg [2:0] state, next_state;

    // 第一段：状态寄存器更新
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IT;
        else     state <= next_state;
    end

    // 第二段：下一状态转移逻辑
    always @(*) begin
        case(state)
            IT:  next_state = IF;
            IF:  next_state = DAE;
            DAE: begin
                if (opcode == `INSTR_LW_OP || opcode == `INSTR_SW_OP)
                    next_state = MEM;
                //else if (opcode == `INSTR_BTYPE_OP)
                //next_state = IF;  // 分支指令直接回取指
                else
                    next_state = WB;  // I/R/Jump 指令去写回
            end
            WB:  next_state = IF;
            MEM: begin
                if (opcode == `INSTR_SW_OP)
                    next_state = IF;  // Store 指令无 WB 阶段
                else
                    next_state = WB;  // Load 指令去 WB
            end
            default: next_state = IF;
        endcase
    end

    // 第三段：控制信号输出
    always @(*) begin
        // --- 0. 默认值初始化，消除 Latch 并解决 Identifier 报错 ---
        RFWrite = 0; DMCtrl = 0; PCWrite = 0; IRWrite = 0;
        InsMemRW = 0; ExtSel = `ExtSel_SIGNED;
        ALUOp = `ALUOp_ADD;
        NPCOp = `NPC_PC;
        ALUSrcA = `ALUSrcA_A;
        ALUSrcB = `ALUSrcB_B;
        RegSel = `RegSel_rd;
        WDSel = `WDSel_FromALU;

        case(state)
            IT: begin
                InsMemRW = 1; //in_ins
                //PCWrite = 1;
            end

            //in_ins
            IF: begin
                IRWrite = 1; //out_ins
                if(in_ins == `INSTR_ITYPE_OP || in_ins == `INSTR_RTYPE_OP || in_ins == `INSTR_SW_OP || in_ins == `INSTR_LW_OP)
                    PCWrite = 1; //PC updata
                else
                    PCWrite = 0; //B/jump
            end

            //out_ins,opcode,Funct......
            DAE: begin
                case(opcode)
                    `INSTR_RTYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;  // 修正：R型指令(含移位) A端口应接 rs1
                        ALUSrcB = `ALUSrcB_B;  // B端口接 rs2
                        case(Funct3)
                            3'b000: ALUOp = (Funct7[5]) ? `ALUOp_SUB : `ALUOp_ADD;
                            3'b001: ALUOp = `ALUOp_SLL;
                            3'b100: ALUOp = `ALUOp_XOR;
                            3'b101: ALUOp = (Funct7[5]) ? `ALUOp_SRA : `ALUOp_SRL;
                            3'b110: ALUOp = `ALUOp_OR;
                            3'b111: ALUOp = `ALUOp_AND;
                            default: ALUOp = `ALUOp_ADD;
                        endcase
                    end

                    `INSTR_ITYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ExtSel = (Funct3 == 3'b110) ? `ExtSel_ZERO : `ExtSel_SIGNED;
                        case(Funct3)
                            3'b000: ALUOp = `ALUOp_ADD;
                            3'b110: ALUOp = `ALUOp_OR;
                            default: ALUOp = `ALUOp_ADD;
                        endcase
                    end

                    `INSTR_LW_OP, `INSTR_SW_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ALUOp = `ALUOp_ADD;
                    end

                    `INSTR_BTYPE_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_B;
                        ALUOp = `ALUOp_SUB;
                        //PCWrite = 1; // WB 阶段直接更新分支跳转 PC
                        //InsMemRW = 1;
                        if ((Funct3 == `INSTR_BEQ_FUNCT && zero) || (Funct3 == `INSTR_BNE_FUNCT && !zero))
                            NPCOp = `NPC_offset12;
                        else
                            NPCOp = `NPC_PC;
                    end

                    `INSTR_JAL_OP: begin
                        WDSel = `WDSel_FromPC;
                        NPCOp = `NPC_offset20;
                    end

                    `INSTR_JALR_OP: begin
                        ALUSrcA = `ALUSrcA_A;
                        ALUSrcB = `ALUSrcB_Imm;
                        ALUOp = `ALUOp_ADD;
                        WDSel = `WDSel_FromPC;
                        NPCOp = `NPC_rs;
                    end
                endcase

                if(opcode == `INSTR_ITYPE_OP || opcode == `INSTR_RTYPE_OP || opcode == `INSTR_SW_OP || opcode == `INSTR_LW_OP) begin
                    InsMemRW = 1;
                end
                else begin
                    InsMemRW = 0;
                    PCWrite = 1; //B/jump PC updata
                    if(opcode == `INSTR_JAL_OP || opcode == `INSTR_JALR_OP)
                        RFWrite = 1;
                    else
                        RFWrite = 0;
                end
            end

            MEM: begin
                if (opcode == `INSTR_LW_OP) begin
                    DMCtrl = `DMCtrl_RD;
                end else if (opcode == `INSTR_SW_OP) begin
                    DMCtrl = `DMCtrl_WR;
                end
            end

            WB: begin
                if(opcode == `INSTR_BTYPE_OP || opcode == `INSTR_JAL_OP || opcode == `INSTR_JALR_OP)
                    RFWrite = 0;
                else
                    RFWrite = 1;

                if(opcode == `INSTR_BTYPE_OP || opcode == `INSTR_JAL_OP || opcode == `INSTR_JALR_OP)
                    InsMemRW = 1; //LW jump B in_ins updata
                else
                    InsMemRW = 0;

                if (opcode == `INSTR_LW_OP) begin
                    WDSel = `WDSel_FromMEM;
                    NPCOp = `NPC_PC;
                end
                else begin
                    WDSel = `WDSel_FromALU;
                    NPCOp = `NPC_PC;
                end
            end
        endcase
    end

endmodule