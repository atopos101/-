module pc(clk,rst,NPC,PC,PCWr);
    input clk;
    input rst;
    input [31:2]NPC;
    input PCWr;
    output reg [31:2]PC;

    always@(posedge clk or posedge rst)
        if(rst)
            PC <= 30'h00000C00;
        else if(PCWr)
            PC <= NPC;
    
endmodule

module npc(PC, NPC, imm, instr_index, control);
    input [31:0]imm;//ext todo
    input [25:0]instr_index;
    input [1:0]control;
    input [31:2] PC;
    output reg [31:2] NPC;
    
    wire [31:2] PC_plus_1 = PC + 1;
    always@(*)
        begin
            case(control)
                2'b00: NPC = PC_plus_1;
                2'b01: NPC = PC_plus_1 + imm;
                2'b10: NPC = { PC_plus_1[31:28], instr_index };
                default:NPC = PC + 1;
            endcase
        end
endmodule