module im_4k( addr, dout );
    
    input [11:2] addr;
    output [31:0] dout;
    
    reg [31:0] imem[63:0];
    
    assign dout = imem[addr];
    
endmodule    

module ir(clk, rst, IRWr, IM_out, IR);

    input clk;
    input rst;
    input IRWr;
    input [31:0] IM_out;
    output reg [31:0]IR;

    always@(posedge clk or posedge rst)
        if(rst)
            IR <= 32'b0;
        else if(IRWr)
            IR <= IM_out;

    
endmodule