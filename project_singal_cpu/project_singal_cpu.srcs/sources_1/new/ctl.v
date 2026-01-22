module alu_control(ALUOp, funct, ALUCtrl);
    input  [2:0] ALUOp;
    input  [5:0] funct;
    output reg [1:0] ALUCtrl;

    parameter OP_ADD =  3'b001;
    parameter OP_SUB =  3'b010;
    parameter OP_OR =  3'b011;
    parameter OP_R =  3'b000;
    
    parameter ADDU =  6'b100001;
    parameter SUBU =  6'b100011;



always @(*) begin
    case (ALUOp)
        OP_ADD: ALUCtrl = 2'b01; // ADD
        OP_SUB: ALUCtrl = 2'b10; // SUB
        OP_OR : ALUCtrl = 2'b11; // OR

        OP_R: begin
            case (funct)
                ADDU: ALUCtrl = 2'b01;
                SUBU: ALUCtrl = 2'b10;
                default:     ALUCtrl = 2'b00;
            endcase
        end

        default: ALUCtrl = 2'b00;
    endcase
end

endmodule


module FSM(clk, rst, opcode, IRWr, ALUOp, PC_ctrl, PCWr, DMWr, ExtOp, RWr, ABWr, c_waddr, c_B, c_wdata, Result, A, B, rdata1, rdata2);//�?小信息原�?
    input clk;
    input rst;
    input [5:0] opcode;
    input [31:0] Result;
    input [31:0] A;
    input [31:0] B;
    input [31:0] rdata1;
    input [31:0] rdata2;
    output reg [1:0] PC_ctrl;
    output reg PCWr;
    output reg DMWr;
    output reg IRWr;
    output reg ExtOp;
    output reg RWr;
    output reg ABWr;
    output reg [1:0] c_waddr;
    output reg [1:0] c_wdata;
    output reg c_B;
    output reg [2:0] ALUOp;


    parameter IF =  4'b0000;
    parameter ID =  4'b0001;
    parameter R =  4'b0010;
    parameter Ori =  4'b0011;
    parameter LSW =  4'b0100;
    parameter BEQ =  4'b0101;
    parameter DM =  4'b0110;
    parameter JMP =  4'b0111;
    parameter WB =  4'b1000;
    
    parameter OP_ADD =  3'b001;
    parameter OP_SUB =  3'b010;
    parameter OP_OR =  3'b011;
    parameter OP_R =  3'b000;
    
    reg [3:0] state, next_state;

    always@(*)
    begin
        PC_ctrl = 2'b00;
        next_state = IF;
        PCWr = 0;
        ALUOp = 3'b100;
        DMWr = 0;
        ExtOp = 0;
        RWr = 0;
        ABWr = 0;
        c_waddr = 2'b00;
        c_wdata = 2'b00;
        c_B = 1;
        IRWr = 0;
        case(state)
            IF:begin
                PC_ctrl = 2'b00;
                PCWr = 1;
                IRWr = 1;
                next_state = ID;
            end
            ID:begin
                case(opcode)
                    6'b000000: next_state = R;
                    6'b001101: next_state = Ori;
                    6'b100011: next_state = LSW;
                    6'b101011: next_state = LSW;
                    6'b000100: next_state = BEQ;
                    6'b000011: next_state = JMP;
                    default: next_state = IF;
                endcase
                ABWr = 1;
            end
            R:begin
                ALUOp = OP_R;
                c_B = 0;
                next_state = WB;
            end
            Ori:begin
                ALUOp = OP_OR;
                c_B = 1;
                next_state = WB;
                ExtOp = 0;
            end
            LSW:begin
                ALUOp = OP_ADD;
                c_B = 1;
                ExtOp = 1;
                next_state = DM;
            end
            DM:begin
                if(opcode == 6'b101011)begin
                    DMWr = 1;                   
                    next_state = IF;
                end   
                else if(opcode == 6'b100011)begin
                    DMWr = 0;
                    next_state = WB;
                end
            end
            WB:begin
                RWr = 1;
                case (opcode)
                    6'b000000: begin
                        c_waddr = 2'b00;
                        c_wdata = 2'b01;
                    end // R�? �? rd
                    6'b100011: begin
                        c_waddr = 2'b01;
                        c_wdata = 2'b00;
                    end // lw 
                    6'b001101: begin
                        c_waddr = 2'b01;
                        c_wdata = 2'b01;
                    end // / ori �? rt
                    6'b000011: begin
                        c_waddr = 2'b10;
                        c_wdata = 2'b10;
                    end // jal �? $31
                endcase
                next_state = IF;
            end
            BEQ:begin
                PC_ctrl = (rdata1 == rdata2) ? 2'b01 : 2'b00;
                // PCWr = 1;
                ExtOp = 1;
                next_state = IF;
            end
            JMP:begin
                ALUOp = OP_ADD;
                c_B = 1;
                PC_ctrl = 2'b10;
                next_state = WB;
            end
            default:begin
            end

        endcase
    end
    
    always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IF;
    else
        state <= next_state;
    end

endmodule