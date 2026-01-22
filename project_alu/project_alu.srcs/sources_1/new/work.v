`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/29 16:34:53
// Design Name: 
// Module Name: work
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


module alu(RST,CLK, Opcode, X, Y, S, Busy_m, Busy_d, Cout, Result);

    input RST;
    input CLK;
    input [2:0] Opcode;
    input S;//区分无符号有符号
    input [31:0] X,Y;
    output Cout;
    output Busy_m,Busy_d;
    output [64:0] Result;


    reg Busy_m, Busy_d;
    reg [64:0] Result;
    reg Cout;
    reg [31:0] A,B;
    reg [31:0] add_re;
    reg cin;
    reg [4:0] mul_counter;
    reg [31:0] mul_B;
    reg [31:0] div_Y;
    reg div_sign;
    reg [31:0] abs_X, abs_Y;
    reg dividend_sign;
    reg [31:0] rem_temp, quo_temp;
    reg [1:0] op_in;
    reg [31:0] Y_in;
    reg [31:0] div;

    

    always@(*)
        {Cout,add_re} = A + B + cin;
    
    


    always@(posedge RST or posedge CLK)
    begin
        if(RST)
            mul_counter <= 5'b0;
        else if(Opcode == 3'b110 || Opcode == 3'b111)
            mul_counter <= 5'b11111;
        else if(Busy_m || Busy_d)
            mul_counter <= mul_counter - 1; 
    end



    always@(posedge RST or posedge CLK)
    begin
        if(RST)
        begin
            Busy_m <= 1'b0;
            Busy_d <= 1'b0;
        end
        else if(Opcode == 3'b110 )
            Busy_m <= 1'b1;
        else if(Opcode == 3'b111)
            begin
                Busy_d <= 1'b1;
                div_sign <= X[31] ^ Y[31];
                dividend_sign <= X[31];//余数
                // take absolute values for unsigned division algorithm
                abs_X <= X[31] ? (~X + 1'b1) : X;
                abs_Y <= Y[31] ? (~Y + 1'b1) : Y;
                div <= Y[31] ? (~Y + 1'b1) : Y;
            end
        else if(Busy_m == 1'b1 && mul_counter == 5'b0 )
            Busy_m <= 1'b0;
        else if(Busy_d == 1'b1 && mul_counter == 5'b0 )
            begin
                Busy_d <= 1'b0;
            end
    end

    always@(posedge RST or posedge CLK)
    begin
        if(RST)
            mul_B <= 32'b0;
        else if(Opcode == 3'b110)
            mul_B <= Y;
        
    end

   
    always@(posedge RST or posedge CLK)
    begin
        if(RST)
        Result <= 65'b0;
        else if(Opcode == 3'b110)
            begin
                Result <= {32'b0, X,1'b0};
            end
        else if(Opcode == 3'b111)
            Result <= {31'b0, X[31] ? (~X + 1'b1) : X, 2'b0};
        
        else if(Busy_d)
        begin
            if(mul_counter != 5'b0)begin
                if(add_re[31] == 1'b0)
                    Result[64:1] <= {add_re[30:0] , Result[32:1], 1'b1};
                else
                    Result[64:1] <= {Result[63:1], 1'b0};
            end
            else begin
                if(add_re[31] == 1'b0)
                    Result[64:1] <= {X[31] ? ( ~add_re[30:0] + 1'b1 ) : add_re[30:0] , div_sign ? (~{Result[32:1] , 1'b1} + 1'b1) : {Result[32:1] , 1'b1}};
                else
                    Result[64:1] <= {X[31] ? ( ~Result[63:32] + 1'b1 ) : Result[63:32] ,div_sign ? (~{Result[31:1] , 1'b0} + 1'b1) : {Result[31:1] , 1'b0}};
            end
            
        end
        else 
            Result <= {add_re[31], add_re, Result[32:1]};
    end


    always@(*)
        if(Busy_m || Busy_d)
            A <= Result[64:33];
        else 
            A <= X;

    always@(*)
        if(Busy_m)
            Y_in <= mul_B;
        else if(Busy_d)
            Y_in <= div;
        else
            Y_in <= Y;

    always@(*)
        if(op_in == 2'b10)
            B <= Y_in;
        else if(op_in == 2'b11)
            B <= ~Y_in;
        else 
            B <= 32'b0;

    always@(*)
        if(op_in == 2'b11)
            cin <= 1'b1;
        else 
            cin <= 1'b0;

    always@(*)
        if(Busy_m)
        begin
            if(Result[1:0] == 2'b00 || Result[1:0] == 2'b11)
                op_in <= 2'b00;
            else if(Result[1:0] == 2'b01)
                op_in <= 2'b10;
            else 
                op_in <= 2'b11;
        end
        else
        begin
            if(Opcode == 3'b100)//add
                op_in <= 2'b10;
            else if(Opcode == 3'b101 || Busy_d)//sub,div
                op_in <= 2'b11;
            else
                op_in <= 2'b00;
        end

   


endmodule