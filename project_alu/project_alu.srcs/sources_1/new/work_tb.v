`timescale 1ns / 1ps

module alu_tb;

    // Inputs
    reg RST;
    reg CLK;
    reg [2:0] Opcode;
    reg S;
    reg [31:0] X;
    reg [31:0] Y;

    // Outputs
    wire Busy_m;
    wire Busy_d;
    wire [64:0] Result;
    wire Cout;

    // Instantiate the Unit Under Test (UUT)
    alu uut (
        .RST(RST),
        .CLK(CLK),
        .Opcode(Opcode),
        .S(S),
        .X(X),
        .Y(Y),
        .Busy_m(Busy_m),
        .Busy_d(Busy_d),
        .Result(Result),
        .Cout(Cout)
    );

    // Clock generation
    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK; // 10ns period
    end

    // Test procedure
    initial begin
        // Initialize inputs
        RST = 1;
        Opcode = 3'b000;
        S = 0;
        X = 32'b0;
        Y = 32'b0;

        // Wait for global reset
        #10;
        RST = 0;

        // Test cases
        $display("Starting ALU Testbench");

        // Test 1: Unsigned Addition (Opcode 100, S=0)
        $display("Test 1: Unsigned Add 10 + 5");
        Opcode = 3'b100;
        S = 0;
        X = 32'd10;
        Y = 32'd5;
        #10; // Wait for operation
        $display("Result: %d, Cout: %b", Result[63:32], Result[64]);

        // Test 2: Signed Addition (Opcode 100, S=1)
        $display("Test 2: Signed Add -10 + 5");
        Opcode = 3'b100;
        S = 1;
        X = -32'd10;
        Y = 32'd5;
        #10;
        $display("Result: %d, Cout: %b", $signed(Result[63:32]), Result[64]);

        // Test 3: Unsigned Subtraction (Opcode 101, S=0)
        $display("Test 3: Unsigned Sub 10 - 5");
        Opcode = 3'b101;
        S = 0;
        X = 32'd10;
        Y = 32'd5;
        #10;
        $display("Result: %d, Cout: %b", Result[63:32], Result[64]);

        // Test 4: Signed Subtraction (Opcode 101, S=1)
        $display("Test 4: Signed Sub -10 - 5");
        Opcode = 3'b101;
        S = 1;
        X = -32'd10;
        Y = 32'd5;
        #10;
        $display("Result: %d, Cout: %b", $signed(Result[63:32]), Result[64]);

        // Test 5: Unsigned Multiplication (Opcode 110, S=0)
        $display("Test 5: Unsigned Mul 6 * 7");
        Opcode = 3'b110;
        S = 0;
        X = 32'd6;
        Y = 32'd7;
        #10;
        Opcode = 3'b000;
        wait(Busy_m == 0); // Wait for multiplication to complete
        
        $display("Result: %d", Result[64:1]);
        #10;
        // Test 6: Signed Multiplication (Opcode 110, S=1)
        $display("Test 6: Signed Mul -6 * 7");
        Opcode = 3'b110;
        S = 1;
        X = -32'd6;
        Y = 32'd7;
        
        #10;
        Opcode = 3'b000;
        wait(Busy_m == 0);
        $display("Result: %d", $signed(Result[64:1]));
        #10;
        // Test 7: Unsigned Division (Opcode 111, S=0)
        $display("Test 7: Unsigned Div 20 / 3");
        Opcode = 3'b111;
        S = 0;
        X = 32'd20;
        Y = 32'd3;
        #10;
        Opcode = 3'b000;
        wait(Busy_d == 0);
        $display("Remainder: %d,Quotient: %d ", Result[64:34], Result[32:1]);
        #10;
        // Test 8: Signed Division (Opcode 111, S=1)
        $display("Test 8: Signed Div -20 / 3");
        Opcode = 3'b111;
        S = 1;
        X = -32'd20;
        Y = 32'd3;
        #10;
        Opcode = 3'b000;
        wait(Busy_d == 0);
        $display("Remainder: %d,Quotient: %d ", $signed(Result[64:34]), $signed(Result[32:1]));

        // Finish simulation
        $display("All tests completed");
        $finish;
    end

endmodule