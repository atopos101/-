module mips( clk, rst );
   input   clk;
   input   rst;
   (* DONT_TOUCH = "TRUE" *) wire [29:0] PC;
   (* DONT_TOUCH = "TRUE" *) wire [29:0] NPC;
   (* DONT_TOUCH = "TRUE" *) wire [29:0] PC_plus_4 = PC + 1;
   (* DONT_TOUCH = "TRUE" *) wire PCWr;
   (* DONT_TOUCH = "TRUE" *) wire PC_ctrl;
   (* DONT_TOUCH = "TRUE" *) wire IRWr;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] im_dout;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] IR;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] imm;
   (* DONT_TOUCH = "TRUE" *) wire ExtOp;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] A;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] B;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] B_R;
   (* DONT_TOUCH = "TRUE" *) wire [2:0] ALUOp;
   (* DONT_TOUCH = "TRUE" *) wire [1:0] ALUCtrl;
   (* DONT_TOUCH = "TRUE" *) wire RWr;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] rdata1;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] rdata2;
   (* DONT_TOUCH = "TRUE" *) wire ABWr;
   (* DONT_TOUCH = "TRUE" *) wire [1:0] c_wdata;
   (* DONT_TOUCH = "TRUE" *) wire [1:0] c_waddr;
   (* DONT_TOUCH = "TRUE" *) wire c_B;
   (* DONT_TOUCH = "TRUE" *) wire DMWr;
   (* DONT_TOUCH = "TRUE" *) wire [4:0] waddr;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] wdata;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] dm_dout;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] dmrout;
   (* DONT_TOUCH = "TRUE" *) wire [31:0] Result;

   pc U_PC(
      .clk(clk),.rst(rst),.NPC(NPC[29:0]),.PC(PC[29:0]),.PCWr(PCWr)
   );

   npc U_NPC(
      .PC(PC[29:0]), .NPC(NPC[29:0]), .imm(imm), .instr_index(IR[25:0]), .control(PC_ctrl)
   );

   ir U_IR(
      .clk(clk), .rst(rst), .IRWr(IRWr), .IM_out(im_dout), .IR(IR)
   );
 
   im_4k U_IM ( 
      .addr(PC[9:0]) , .dout(im_dout)
   );
   
   ext U_EXT (
      .imm16(IR[15:0]),.ExtOp(ExtOp),.imm32(imm)
   );

   mux_wdata U_WDATA (
      .c_wdata(c_wdata), .wdata(wdata), .dmrout(dmrout), .aluout(Result), .NPC({PC_plus_4, 2'b00})
   );

   mux_wadd U_ADD (
      .c_waddr(c_waddr), .waddr(waddr), .IR(IR)
   );

   rf U_RF (
      .clk(clk), .rst(rst), .RWr(RWr), .add1(IR[25:21]), .add2(IR[20:16]), .waddr(waddr), .wdata(wdata), .rdata1(rdata1), .rdata2(rdata2)
   );

   reg_AB U_AB (
      .clk(clk),.rst(rst),.ABWr(ABWr), .rdata1(rdata1), .rdata2(rdata2), .A(A), .B(B)     
   );

   mux_B U_B (
      .B(B_R), .c_B(c_B), .rdata2(B), .imm32(imm)
   );

   alu U_ALU (
      .clk(clk), .rst(rst), .A(A), .B(B_R), .ALUCtrl(ALUCtrl), .Result(Result)
   );

   alu_control U_ALU_CTRL (
      .ALUOp(ALUOp), .funct(IR[5:0]), .ALUCtrl(ALUCtrl)
   );

   dm_4k U_DM ( 
      .addr(Result[11:2]), .din(rdata2), .DMWr(DMWr), .clk(clk), .dout(dm_dout)
   );
   
   dmr U_DMR (
      .clk(clk), .rst(rst), .dout(dm_dout), .dmrout(dmrout)
   );
   
   FSM FSM (
      .clk(clk), .rst(rst), .opcode(IR[31:26]), .IRWr(IRWr), .ALUOp(ALUOp), .PC_ctrl(PC_ctrl), .PCWr(PCWr), .DMWr(DMWr), .ExtOp(ExtOp), .RWr(RWr), .ABWr(ABWr), .c_waddr(c_waddr), .c_B(c_B), .c_wdata(c_wdata), .Result(Result), .A(A), .B(B), .rdata1(rdata1), .rdata2(rdata2)
   );

endmodule