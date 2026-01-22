`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/03 19:35:42
// Design Name: 
// Module Name: transmitter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module transmitter(
    input WR,
    input RD,
    inout [7:0] D,
    input A0,//addr
    input CS,
    input CLK,
    input FS,
    input RST,
    output TxD
    );

    reg [7:0] TSR;
    reg [7:0] THR [3:0];
    reg TxD_1;
    reg TxD;
    reg [7:0] shift_en;
    reg mux1;
    reg mux2;
    reg THR_state;

    reg [2:0]cnt5;
    reg [2:0]cnt8;
    reg [4:0]cnt32;
    reg [7:0]EH_shifter;

    // always@(posedge CLK or posedge RST)
    //     if(RST)
    //         THR <= 8'h00;
    //     else if(WR == 1'b0 && CS == 1'b0 && A0 == 1'b0)
    //         THR <= D;
    reg [1:0] thr_wr_ptr;
    reg [1:0] thr_rd_ptr;
    reg [2:0] thr_cnt;     // 0~4

    
    always @(posedge CLK or posedge RST) begin
    if (RST) begin
        thr_wr_ptr <= 0;
        thr_cnt    <= 0;
    end 
    else if (!WR && !CS && A0==1'b0 && thr_cnt < 4) begin
        THR[thr_wr_ptr] <= D;
        thr_wr_ptr <= (thr_wr_ptr + 1'b1)%4;
        thr_cnt <= thr_cnt + 1'b1;
    end
    end


    always@(posedge CLK or posedge RST)
        if(RST)
            cnt5 <= 3'b100;
        else if(TSR[7] == 1'b0)
            cnt5 <= 3'b100;
        else
            cnt5 <= cnt5 - 1;
    


    always@(*)
        if(cnt5 == 3'b000)
            shift_en = 0;
        else 
            shift_en = 1;
        

    always@(posedge CLK or posedge RST)
        if(RST)
            cnt8 <= 3'b111;
        else if(~FS)
            cnt8 <=3'b111;           
        else if(shift_en)
            if(cnt8 == 3'b000)
                cnt8 <= 3'b111;
                else 
                cnt8 <= cnt8 - 1;

    always@(posedge CLK or posedge RST)
        if(RST)
            cnt32 <= 5'b11111;
        else if(~FS)
            begin
            cnt32 <=5'b11111;   
            end        
        else if(shift_en)
            cnt32 <= cnt32 - 1;

    always @(posedge CLK or posedge RST ) begin
    if (RST) begin
        thr_rd_ptr <= 0;
    end 
    else if (thr_cnt != 0 && cnt8 == 3'b000 || ~FS) begin
        TSR <= THR[thr_rd_ptr];
        thr_rd_ptr <= thr_rd_ptr + 1'b1;
        thr_cnt <= thr_cnt - 1'b1;
    end 
    else if (shift_en) begin
        TSR <= {TSR[6:0],1'b0};
    end
    end


    always@(*)
        if(cnt5 == 0)
            mux1 = 1;
        else mux1 = 0;

    always@(*)
        if(cnt32 > 0)
            mux2 = 0;
        else mux2 = 1;

    always@(*)
        if(!mux1)
            TxD_1 = TSR[7];
        else
            TxD_1 = 0;

    always@(posedge CLK or posedge RST)
        if(RST)
            EH_shifter <= 8'b01111110;
        else if(cnt32 == 0)
            EH_shifter <= 8'b01111110;
        else
            EH_shifter <= {EH_shifter[6:0],EH_shifter[7]};
         
    always@(*)
        if(mux2)
            TxD = EH_shifter[7];
        else
            TxD = TxD_1;

    always@(posedge RST or posedge CLK)
        if(RST)
            THR_state = 1'b0;
        else if(WR == 0 && cnt32 != 0 && A0 == 1'b0)
            THR_state = 1'b1;
        else if(WR == 1'b1 && cnt32 == 0)
            THR_state = 1'b0;

    assign D=(RD ==1'b0 && A0 == 1'b0)?THR_state:8'hzz;





endmodule