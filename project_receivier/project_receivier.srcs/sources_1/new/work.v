`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/25 19:15:47
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


module serial_receiver(
    input BCL,
    input NRZ,
    input RST,
    input IOR,
    input IOW,
    input [7:0] adder,
    inout [7:0] data
    );
    
    reg [7:0] sync_word;
    reg [7:0] data_reg;
    reg [7:0] read_sync_word;
    reg [7:0] read_data;
    reg data_empty;

    // initial
    // begin
    //     read_data = 0;
    // end
    
    always@(posedge BCL or posedge RST)
    begin
        if(!IOR)  // IOR低电平时
        begin
            case(adder)
                8'h00: read_data <= sync_word;        
                8'h01: begin                        
                    if(!data_empty)                
                        read_data <= sync_word;         
                    else
                        read_data <= data_reg;      
                end
                default: read_data <= sync_word;
            endcase
        end
        
    end
  
    always@(posedge BCL or posedge RST)
        begin
            if(!IOW)
            begin
                if (adder == 8'h00)
                    sync_word <= data;  
            end
        end
    
    assign data = (!IOR) ? read_data : 8'bZZZZZZZZ;    

    always @(*)//genxin
    if (RST)
        read_sync_word = 8'h00;
    else
        read_sync_word = sync_word;



    reg [7:0] shift_reg;
    reg [7:0] curr_data_reg;
    
    always@(negedge BCL or posedge RST)
        begin
            if(RST)
            shift_reg <= 0;
            else
            shift_reg <={shift_reg[6:0], NRZ};//注意大小端
        end

    

    // always@(posedge BCL or posedge RST)
    //     begin
    //         if(RST)
    //         curr_data_reg <= 0;
    //         else if(bit_counter == 7)
    //         curr_data_reg <= shift_reg;
    //     end

    reg [2:0] bit_counter;
    reg [8:0] cyc_counter;

    reg [2:0] y,Y;
    reg cyc_clr,cyc_en,bit_clr,bit_en;

    parameter [2:0] 
        R_Head1 = 3'b000,
        R_Data1 = 3'b001,
        R_Head2 = 3'b010,
        R_Data2 = 3'b011,
        R_Head3 = 3'b100,
        R_Data3 = 3'b101,
        R_Head = 3'b110,
        R_Data = 3'b111;

    
     always@(*)
        if(y == R_Data1 || y== R_Data2 || y== R_Data3 || y== R_Data)
            bit_clr = 1'b1;
        else bit_clr = 1'b0;

    always@(*)
        if(y == R_Head || y== R_Head2 || y== R_Head3 )
            bit_en = 1'b1;
        else bit_en = 1'b0;

    always@(*)
        if(y == R_Head1 || y== R_Head2 || y== R_Head3 || y== R_Head )
            cyc_clr = 1'b1;
        else cyc_clr = 1'b0;

    always@(*)
        if(y == R_Data1 || y== R_Data2 || y== R_Data3 || y== R_Data)
            cyc_en = 1'b1;
        else cyc_en = 1'b0;



    always@(posedge BCL or posedge RST)
        if (RST)
        bit_counter <= 0;
    else if (bit_clr)
        bit_counter <= 0;     // 未检测到同步字前，保持为0
    else if (bit_en)
        bit_counter <= bit_counter + 1;

    

    always@(posedge BCL or posedge RST)
        if (RST)
        cyc_counter <= 0;
    else if (cyc_clr)
        cyc_counter <= 0;     // 未检测到同步字前，保持为0
    else if (cyc_en)
        cyc_counter <= cyc_counter + 1; 


    // reg first_en;

    // always@(posedge BCL or posedge RST)
    //     if (RST)
    //     first_counter <= 0;
    // else if (!first_en)
    //     first_counter <= 0;     // 未检测到同步字前，保持为0
    // else if (cyc_counter == 503)
    //     first_counter <= 0;
    // else
    //     first_counter <= first_counter + 1;   

    
    always@(*)

        case(y)
            R_Head1: if(shift_reg == sync_word) Y = R_Data1;
                    else 
                        begin
                        Y = R_Head1;
                        end
            R_Data1: if(cyc_counter==503) Y = R_Head2;
                    else Y = R_Data1; 
            R_Head2: if(bit_counter==7)
                        begin
                            if(shift_reg == sync_word)
                             Y = R_Data2;
                             else Y = R_Head1;
                        end
                        else
                        Y = R_Head2;                   
            R_Data2: if(cyc_counter==503) Y = R_Head3;
                    else Y = R_Data2; 
            R_Head3: if(bit_counter==7)
                        begin
                            if(shift_reg == sync_word)
                             Y = R_Data3;
                             else Y = R_Head1;
                        end
                        else
                        Y = R_Head3;   
            R_Data3: if(cyc_counter==503) Y = R_Head;
                    else Y = R_Data3; 
            R_Head: if(bit_counter==7)
                        begin
                            if(shift_reg == sync_word)
                             Y = R_Data;
                             else Y = R_Head1;
                        end
                        else
                        Y = R_Head;   
            R_Data: if(cyc_counter==503)
                        Y = R_Head;
                    else
                        Y = R_Data;
            default: begin
                Y=R_Head1;
            end
        endcase
    
    always@(posedge BCL or posedge RST)
        if(RST) begin
        data_reg <= 8'b0;
                end
        else if(cyc_en == 1'b1 && cyc_counter[2:0] == 3'b111)//计满八个数据
        begin
            data_reg <= shift_reg;

        end
      
    always@(*)
        if(y == R_Data)
            data_empty = 1;
        else
            data_empty = 0;
    

    always@(posedge BCL or posedge RST)
        if(RST) y<= R_Head1;
        else y <=Y;

 

       
endmodule

//为什么adder是输入
    //寄存器内的内容不能直接被检测吗，还需要用cpu读出来 ?另外的用处
    //那不是没检测到三个同步字就开始向cpu传数据了吗？
    //串行接收器接收的数据是输出data吗？
    //那data与cpu有关系吗？