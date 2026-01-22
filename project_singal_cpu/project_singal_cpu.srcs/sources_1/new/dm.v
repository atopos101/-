module dm_4k( addr, din, DMWr, clk, dout );
   
   input  [11:2] addr;
   input  [31:0] din;
   input         DMWr;
   input         clk;
   output [31:0] dout;
     
   reg [31:0] dmem[63:0];
   
   always @(posedge clk) begin
      if (DMWr)
         dmem[addr] <= din;
   end // end always
   
   assign dout = dmem[addr];
    
endmodule    

module dmr(clk, rst, dout, dmrout);
   input [31:0] dout;
   input clk;
   input rst;
   output reg [31:0] dmrout;

   always@(posedge clk or posedge rst)
        if(rst)
            dmrout <= 0;
        else
            dmrout <= dout;
endmodule