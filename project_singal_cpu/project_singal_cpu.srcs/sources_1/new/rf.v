
module rf(clk, rst, RWr, add1, add2, waddr, wdata, rdata1, rdata2);
    input clk;
    input rst;
    input [4:0] add1;
    input [4:0] add2;
    input [4:0] waddr;
    input [31:0] wdata;
    input RWr;
    output [31:0] rdata1;
    output [31:0] rdata2;

    reg [31:0] GPR[31:0];

    integer i;
    always@(posedge clk or posedge rst)
        if(rst) begin
            for (i = 0;i < 32 ;i = i + 1 ) begin
                GPR[i] <= 32'b0;
            end
        end
        else if(RWr && (waddr != 5'b0))begin
            GPR[waddr] <= wdata;
        end
        

    assign rdata1 = (add1 == 5'b00000) ? 32'b0 : GPR[add1];//禁写0号
    assign rdata2 = (add2 == 5'b00000) ? 32'b0 : GPR[add2];
    
endmodule