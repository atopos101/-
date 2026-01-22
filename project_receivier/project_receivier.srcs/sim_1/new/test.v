// `timescale 1ns/1ps 

// module tb_serial_receiver;

//     reg BCL;
//     reg NRZ;
//     reg RST;
//     reg IOR;
//     reg IOW;
//     reg [7:0] adder;
//     wire [7:0] data;

//     serial_receiver uut (
//         .BCL(BCL),
//         .NRZ(NRZ),
//         .RST(RST),
//         .IOR(IOR),
//         .IOW(IOW),
//         .adder(adder),
//         .data(data)
//     );

//     reg [7:0] data_drive;
//     reg drive;

//     // Inout 总线三态驱动
//     assign data = (drive) ? data_drive : 8'bZ;

//     // 10MHz BCL
//     always #25 BCL = ~BCL;

//     initial begin
//         adder = 8'h00;
//     end

//     // CPU 写同步字
//     task cpu_write_sync_word;
//         input [7:0] data_in;
//         begin
//             @(negedge BCL);
//             drive = 1;
//             adder = 8'h00;
//             data_drive = data_in;
//             IOW = 0;
//             @(negedge BCL);
//             drive = 0;
//             IOW = 1;
//             adder = 8'h01;
//         end
//     endtask

//     // CPU 读寄存器
//     task cpu_read;
//         input [7:0] addr;
//         begin
//             @(negedge BCL);
//             drive = 0;
//             adder = addr;
//             IOR = 0;

//             @(negedge BCL);
//             @(negedge BCL);
//             IOR = 1;
//         end
//     endtask

//     // ===== NRZ 发送 1 个字节，MSB first =====
//     task send_byte;
//         input [7:0] data_in;
//         integer i;
//         begin
//             for(i = 7; i >= 0; i = i - 1) begin
//                 NRZ = data_in[i];
//                 @(negedge BCL);
//             end
//         end
//     endtask

//     // ===== 发送 1 帧：64 words，第 1 word 是同步字 =====
//     task send_frame;
//         input [7:0] sync;
//         integer w;
//         begin
//             // word0: SYNC
//             send_byte(sync);

//             // word1~63：测试用假数据，例如每个字节加 w
//             for(w=1; w<64; w=w+1)
//                 send_byte(w[7:0]);
//         end
//     endtask


//     // ===========================
//     // 主测试流程
//     // ===========================
//     initial begin
//         $dumpfile("serial_receiver.vcd");
//         $dumpvars(0, tb_serial_receiver);

//         BCL = 0;
//         NRZ = 0;
//         RST = 1;
//         drive = 0;
//         IOR = 1;
//         IOW = 1;
//         adder = 8'h00;

//         #200;
//         RST = 0;
        
//         // 写同步字 A5
//         cpu_write_sync_word(8'hA5);
//         cpu_read(8'h00);

//         // 等待内部寄存器更新
//         repeat(5) @(negedge BCL);

//         // ======== 发送 8 帧 NRZ 数据 ========
//         // 前 3 帧：sync = A5
//         send_frame(8'hA5);
        
//         send_frame(8'hA5);
        
//         send_frame(8'hA5);
        
        

//         // 第 4 帧：sync != A5（例如 0x55）
//         send_frame(8'hA5);
        

//         // 后 4 帧：sync = A5
//         send_frame(8'hA5);
        
//         send_frame(8'hA5);
//         send_frame(8'hA5);
//         send_frame(8'hA5);

//         // 读数据寄存器
//         repeat(10) @(negedge BCL);
//         cpu_read(8'h01);

//         #1000;
//         $finish;
//     end

// endmodule


`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 

// Create Date: 2025/11/23 11:48:03
// Design Name: 
// Module Name: serial_receiver_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 

// Dependencies: 

// Revision:
// Revision 0.01 - File Created
// Additional Comments:

////////////////////////////////////////////////////////////////////////////////


module serial_receiver_tb(
    );    
    // testbench 和被测模块同时驱动同一信号 DATA（reg），Verilog 不允许对非 net（非 wire）执行并行赋值。
    reg [7:0] ADDER, data_drv;
    wire [7:0] DATA;
    reg IOR,IOW,NRZ,BCL,RST;

    parameter initial_sync_word = 8'b10110101, initial_random_seed = 0;
    integer random_seed = initial_random_seed;
    reg [7:0] sync_word = initial_sync_word;
    reg enable_read_data;
    

    serial_receiver reviever(
        .adder(ADDER), 
        .IOR(IOR), 
        .IOW(IOW), 
        .NRZ(NRZ), 
        .BCL(BCL), 
        .RST(RST), 
        .data(DATA)
    );
    assign DATA = (~IOW) ? data_drv : 8'bz;
    // clock
    initial begin
        BCL = 0;
        forever begin
            #5 BCL = ~BCL;
        end
    end

    initial begin
        RST = 1;
        #10
        #5 RST = 0;
    end

    initial begin
    #60;    // 第一次读取触发点
    forever begin
        if (enable_read_data) begin
            IOW = 1;
            IOR = 0;
            #10;
            $display("%t, Read Data: 0x%h, %b", $time, DATA, DATA);
            IOW = 1;
            IOR = 1;
        end
        else begin
            $display("%t, Skip Read Data", $time);
            #10;
        end
        #70;  // 之后每一轮周期仍然是 70ns
    end
end


    task write_sync_word; 
        input [7:0] target_sync_word;
        begin
            #5
            // write sync word
            IOW = 0;
            IOR = 1;
            ADDER = 8'h00;
            data_drv = target_sync_word;
            $display("%t, Writing Sync Word: 0x%h, %b", $time, target_sync_word, target_sync_word);

            #10
            #10
            
            // try read sync word
            IOW = 1;
            IOR = 0;
            ADDER = 8'h00;
            $display("%t, Reading Sync Word: 0x%h, %b", $time, DATA, DATA);
            #10
            
            // read data
            enable_read_data = 1;
            ADDER = 8'h01;
        end
    endtask

    task send_byte;
        input [7:0] bytes;

        begin : send_byte_block
            integer i;
            $display("%t, Send byte: 0x%h, %b", $time, bytes, bytes);
            for(i = 7; i >= 0; i = i - 1) begin
                NRZ = bytes[i];
                #10;
            end
        end
    endtask

    task send_random_bit;
        input integer bits;
        begin : send_random_bit_block
            integer i;
            reg candidate;
            reg [7:0] new_window;
            reg [7:0] bit_history;
            $display("%t, Send %d random bits", $time, bits);
            for(i = 0; i < bits; i = i + 1) begin
                candidate = {$random(random_seed)} % 2;
                new_window = {bit_history[6:0], candidate};
                // 若形成 sync_word，则反转 candidate（或重抽），以避开同步字
                if (new_window == sync_word) begin
                    candidate = ~candidate;
                    new_window = {bit_history[6:0], candidate};
                end
                NRZ = candidate;
                #10;
                bit_history = new_window;
            end
        end
    endtask

    task send_sequence_data;
        integer i,j;

        begin : send_random_data_block
            reg[7:0] bytes;
            
            for(i = 0; i < 63; i = i + 1) begin
                bytes = i;
                $display("%t, Send #%d Sequence Data: 0x%h, %b", $time, i, bytes, bytes);
                send_byte(bytes);
            end
        end

    endtask

    task send_frames;
        input integer nums;
        begin : send_frames_block
            integer i;
            $display("%t, Send %d Frame(s)", $time, nums);
            for(i = 0; i < nums; i = i + 1) begin
                $display("%t, Send Frame #%d", $time, i);
                $display("%t, Send Frame #%d Sync Word", $time, i);
                send_byte(sync_word);
                $display("%t, Send Frame #%d Data Section", $time, i);
                send_sequence_data();
            end
        end
        
    endtask

    initial begin : main_test // need 300us
        integer i;
        write_sync_word(sync_word);
        NRZ = 0; // 防止发送z
        #40

        $display("Test normal states");
        $display("Send Random Bits");
        send_random_bit({$random(random_seed)} % 50); // 先发送几个随机位，模拟干扰
        $display("Send 10 frames");
        // 发送10个正常包
        send_frames(10);

        $display("Test Desync states");
        $display("Send Random Bits");
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        // 发送1个正常包
        send_frames(1);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(2);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(3);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态

        $display("Test sync to desync states");
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(5);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(6);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(7);
        sync_word = 8'b11010001;
        $display("Changing sync word");
        write_sync_word(sync_word); // 尝试改变同步字
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(8);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(2);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(3);
        send_random_bit({$random(random_seed)} % 50); // 发送随机位让其恢复0状态
        send_frames(5);

        $display("Test end");
        $display("Total: %dns", $time);
    end
endmodule
