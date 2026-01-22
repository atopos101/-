module reg_AB (
    input         clk,
    input         rst,
    input         ABWr,        // A/B 写使能（ID周期=1）
    input  [31:0] rdata1,      // RF 读口1
    input  [31:0] rdata2,      // RF 读口2
    output reg [31:0] A,
    output reg [31:0] B
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A <= 32'b0;
            B <= 32'b0;
        end
        else if (ABWr) begin
            A <= rdata1;
            B <= rdata2;
        end
    end

endmodule



module alu(clk, rst, A, B, ALUCtrl, Result);
    input [31:0] A;
    input clk;
    input rst;
    input [31:0] B;
    input [1:0] ALUCtrl;
    output reg [31:0] Result;

    reg [31:0] Re;

    always@(*)
        case(ALUCtrl)
            2'b00: Re = 32'b0;
            2'b01: Re = A + B;
            2'b10: Re = A - B;
            2'b11: Re = A | B;
            default: Re = 32'b0;
        endcase
    
    always@(posedge clk or posedge rst)
        if(rst)
            Result <= 0;
        else
            Result <= Re;
endmodule
