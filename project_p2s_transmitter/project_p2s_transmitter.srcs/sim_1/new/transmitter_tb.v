`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/01 20:15:54
// Design Name: 
// Module Name: serial_sender_tb
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


module serial_sender_tb(
    );

    reg [7:0] DATA_drv;
    wire [7:0] DATA;
    wire TxD;
    reg RD,WR,CS,CLK,RST,FS,A0;

    parameter IDLE_DATA = 8'h7E, initial_random_seed = 0;
    integer random_seed = initial_random_seed;
    integer i;
    reg sending_data;   // 正发送数据
    reg [7:0] serial_data[3:0];

    transmitter sender(
        .CLK(CLK), 
        .RST(RST), 
        .FS(FS), 
        .WR(WR), 
        .RD(RD), 
        .CS(CS), 
        .D(DATA),
        .A0(A0),
        .TxD(TxD)
    );

    assign DATA = (~WR) ? DATA_drv : 8'bz;
    // clock
    initial begin
        CLK = 0;
        forever begin
            A0 = 1'b0;
            #5 CLK = ~CLK;
        end
    end

    // reset
    initial begin
        RST = 1;
        #5 RST = 0;
    end

    task send_data;
        input [7:0] data0;
        input [7:0] data1;
        input [7:0] data2;
        input [7:0] data3;
        begin
            CS = 0;
            WR = 0;
            DATA_drv = 8'h00;
            $display("%t, Sending 4 bytes Data: 0x%h, 0x%h, 0x%h, 0x%h", $time, data0, data1, data2, data3);
            #10; // 此处等10ns使其进入状态
            DATA_drv = data0;
            #10;
            DATA_drv = data1;
            #10;
            DATA_drv = data2;
            #10;
            DATA_drv = data3;
            #10;
            WR = 1;
            $display("%t, Send 4 bytes Data End", $time);
        end
    endtask

    task read_data;
        output [7:0] data_out;
        begin
            CS = 0;
            RD = 0;
            #10;
            data_out = DATA;
            RD = 1;
        end
    endtask

    task ensure_THR_not_full;
        begin : ensure_THR_not_full_block
            reg THR_full_state;
            reg [7:0] data_out;
            THR_full_state = 1;
            while(THR_full_state) begin
                read_data(data_out);
                $display("%t, Read Data: 0x%h", $time, data_out);
                if(data_out == 8'd1) begin
                    $display("%t, Read State is THR Full", $time);
                end
                else begin
                    $display("%t, Read State is THR Not Full, Continuing...", $time);
                    THR_full_state = 0;
                end
            end
        end
    endtask

    task start_send_serial;
        begin : start_send_serial_block
            reg THR_full_state;
            reg [7:0] data_out;
            FS = 0;
            RD = 1;
            THR_full_state = 1;
            #10;
            FS = 1;
            sending_data = 1;
            while(THR_full_state) begin
                read_data(data_out);
                if(data_out == 8'd0) begin
                    $display("%t, Read State is THR Not Full, Data send complete.", $time);
                    THR_full_state = 0;
                end
            end
            sending_data = 0;
            RD = 1;
        end
    endtask

    task test;
        input [7:0] data0;
        input [7:0] data1;
        input [7:0] data2;
        input [7:0] data3;
        begin
            $display("%t, Testing Data: 0x%h, 0x%h, 0x%h, 0x%h", $time, data0, data1, data2, data3);
            ensure_THR_not_full();
            send_data(data0, data1, data2, data3);
            start_send_serial();

            if(data0 == serial_data[0] && data1 == serial_data[1] && data2 == serial_data[2] && data3 == serial_data[3]) begin
                $display("%t, Test Pass", $time);
            end
            else begin
                $display("%t, Test Fail", $time);
            end
        end
    endtask

    initial begin
        sending_data = 0;
        RD = 1;
        WR = 1;
        CS = 0;
        FS = 1;

        #50;
        // 无连续5个1
        $display("No Sequence of 1");
        test(8'h01,8'h02,8'd03,8'h04);

        #50;

        // 有连续5个1
        $display("Sequence of 5 1");
        test(8'hff,8'hfe,8'hfd,8'hfc);
        
        #50;
        // byte中间为5个1后
        $display("Sequence of 5 1 in the end");
        test(8'b10011111,8'b10011111,8'b10011111,8'b10011111);

        #50;
        // byte中间为5个1前
        $display("Sequence of 5 1 in the front");
        test(8'b11111010,8'b11111010,8'b11111010,8'b11111010);

        #50;
        // byte中间为5个1中间
        $display("Sequence of 5 1 in the middle");
        test(8'b01111110,8'b01111110,8'b01111110,8'b01111110);

        #50
        // 发送顺序数据
        $display("Test sequence data (Up)");
        for(i = 0; i < 256; i = i + 4) begin
            test(i, i + 1, i + 2, i + 3);
        end

        #50;
        // 发送顺序数据
        $display("Test sequence data (Down)");
        for(i = 255; i >= 0; i = i - 4) begin
            test(i, i - 1, i - 2, i - 3);
        end

        #50;
        $display("Test random data");
        for(i = 0; i < 1000; i = i + 1) begin
            $display("%t, Test random data: #%d", $time, i);
            test($random(random_seed), $random(random_seed), $random(random_seed), $random(random_seed));
        end
        $finish;
    end

    initial begin
        forever begin : serial_receive_block
            integer bits, bytes, one_count;
            serial_data[0] = 8'b0;
            serial_data[1] = 8'b0;
            serial_data[2] = 8'b0;
            serial_data[3] = 8'b0;
            bits = 0;
            bytes = 0;
            one_count = 0;
            if(sending_data) begin
                $display("%t, Receiveing Serial Data", $time);
                while(bits < 8 && bytes < 4) begin
                    if(TxD) begin
                        serial_data[bytes][7 - bits] = TxD;
                        if(one_count < 5) begin
                            if(bits == 7) begin
                                bits = 0;
                                bytes = bytes + 1;
                            end
                            else begin
                                bits = bits + 1;
                            end
                            one_count = one_count + 1;
                        end
                    end
                    else begin
                        if(one_count != 5) begin
                            //$display("%t, bits: %d, bytes: %d, one_count: %d, TxD: %b, Assign", $time, bits, bytes, one_count, TxD);
                            serial_data[bytes][7 - bits] = TxD;
                            if(bits == 7) begin
                                bits = 0;
                                bytes = bytes + 1;
                            end
                            else begin
                                bits = bits + 1;
                            end
                        end      
                        one_count = 0;                      
                    end
                    if(bits == 0) begin
                        $display("%t, Received Serial Data #%d: 0x%h", $time, bytes, serial_data[bytes-1]);
                    end
                    #10;
                end
            end
            #10;
        end
    end
endmodule
