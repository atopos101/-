module ext (imm16,ExtOp,imm32);

    input   [15:0] imm16;    // IR[15:0]
    input          ExtOp;    // 扩展控制信号
    output  [31:0] imm32;

    assign imm32 = (ExtOp == 1'b1) ?
                   {{16{imm16[15]}}, imm16} :  // 符号扩展
                   {16'b0, imm16};             // 零扩�?

endmodule
