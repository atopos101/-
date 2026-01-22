module mux_wadd(c_waddr, waddr, IR);
    input [1:0] c_waddr;
    input [31:0] IR;
    output reg [4:0] waddr;
    always@(*)
        begin
            if(c_waddr==2'b00)
                waddr = IR[15:11];
            else if(c_waddr== 2'b01)
                waddr = IR[20:16];
            else if(c_waddr == 2'b10)
                waddr = 5'b11111;

        end
endmodule

module mux_wdata(c_wdata, wdata, dmrout, aluout, NPC);
    input [1:0] c_wdata;
    input [31:0] dmrout;
    input [31:0] aluout;
    input [31:0] NPC;
    output reg [31:0] wdata;
    always@(*)
        begin
            if(c_wdata==2'b00)
                wdata = dmrout;
            else if(c_wdata== 2'b01)
                wdata = aluout;
            else if(c_wdata == 2'b10)
                wdata = NPC;

        end
endmodule

module mux_B(B, c_B, rdata2, imm32);
    input c_B;
    input [31:0] rdata2;
    input [31:0] imm32;
    output reg [31:0] B;
    always@(*)
        if(c_B)
            B = imm32;
        else
            B = rdata2;
endmodule
