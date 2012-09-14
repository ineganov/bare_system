module mcpu(  input CLK,
              input CLK_MEM,
              input RESET,
              input RUN,
              
              //External inst memory iface
              output [29:0] INST_ADDR,
              input  [31:0] INST_RD,
                 
              //External data memory iface
              output        DATA_WE,
              output [3:0]  DATA_BE,
              output [29:0] DATA_ADDR,
              output [31:0] DATA_WD,
              input  [31:0] DATA_RD );
              
            
wire  WRITE_REG, WRITE_MEM, ALUORMEM_WR, MULTIPLY, 
      ALU_SRC_B, BRANCH_E, BRANCH_NE, JUMP, JUMP_R,
      BRANCH_LEZ, BRANCH_LTZ, BRANCH_GEZ, BRANCH_GTZ,
      MEM_PARTIAL;

wire [1:0] IMMED_EXT, REG_DST, MFCOP_SEL, MEM_OPTYPE;     
wire [6:0] ALU_OP;
wire [5:0] OPCODE;
wire [5:0] FCODE;
wire [4:0] RT;

controller the_controller ( .OPCODE     (OPCODE     ),  //instruction opcode
                            .FCODE      (FCODE      ),  //instruction fcode
                            .RT         (RT         ),  //instruction RT
                            .WRITE_REG  (WRITE_REG  ),  //write to register file
                            .WRITE_MEM  (WRITE_MEM  ),  //write data memory
                            .MEM_PARTIAL(MEM_PARTIAL),  //memory byte- or halfword access
                            .MEM_OPTYPE (MEM_OPTYPE ),  //mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh 
                            .ALUORMEM_WR(ALUORMEM_WR),  //write regfile from alu or from memory
                            .MULTIPLY   (MULTIPLY   ),  //multiply and write hi and lo
                            .BRANCH_E   (BRANCH_E   ),  //branch equal
                            .BRANCH_NE  (BRANCH_NE  ),  //branch not equal
                            .BRANCH_LEZ (BRANCH_LEZ ),  //branch less than or equal zero
                            .BRANCH_LTZ (BRANCH_LTZ ),  //branch less than zero
                            .BRANCH_GEZ (BRANCH_GEZ ),  //branch greater than or equal zero
                            .BRANCH_GTZ (BRANCH_GTZ ),  //branch greater than zero                    
                            .JUMP       (JUMP       ),  //j-type jump
                            .JUMP_R     (JUMP_R     ),  //r-type jump
                            .ALU_SRC_B  (ALU_SRC_B  ),  //ALU Operand B 0 - reg_2, 1 - immediate
                            .ALU_OP     (ALU_OP     ),  //ALU Operation select
                            .REG_DST    (REG_DST    ),  //write destination in regfile (0 - rt, 1 - rd)
                            .IMMED_EXT  (IMMED_EXT  ),  //immed-extension type
                            .MFCOP_SEL  (MFCOP_SEL  )); //move from coprocessor sel

datapath the_datapath (     .CLK            (CLK        ),
                            .CLK_MEM        (CLK_MEM     ),
                            .RESET          (RESET      ),
                            .RUN            (RUN        ),
                                  
                            //Controller iface
                            .OPCODE         (OPCODE     ), //instruction opcode
                            .FCODE          (FCODE      ), //instruction fcode
                            .RT             (RT         ), //instruction RT
                            .WRITE_REG      (WRITE_REG  ), //write to register file
                            .WRITE_MEM      (WRITE_MEM  ), //write data memory
                            .MEM_PARTIAL    (MEM_PARTIAL), //memory byte- or halfword access
                            .MEM_OPTYPE     (MEM_OPTYPE ), //mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh 
                            .ALUORMEM_WR    (ALUORMEM_WR), //write regfile from alu or from memory
                            .MULTIPLY       (MULTIPLY   ), //multiply and write hi and lo
                            .BRANCH_E       (BRANCH_E   ), //branch equal
                            .BRANCH_NE      (BRANCH_NE  ), //branch not equal
                            .BRANCH_LEZ     (BRANCH_LEZ ), //branch less than or equal zero
                            .BRANCH_LTZ     (BRANCH_LTZ ), //branch less than zero
                            .BRANCH_GEZ     (BRANCH_GEZ ), //branch greater than or equal zero
                            .BRANCH_GTZ     (BRANCH_GTZ ), //branch greater than zero
                            .JUMP           (JUMP       ), //j-type jump
                            .JUMP_R         (JUMP_R     ), //r-type jump
                            .ALU_SRC_B      (ALU_SRC_B  ), //ALU Operand B 0 - reg_2, 1 - immediate
                            .ALU_OP         (ALU_OP     ), //ALU Operation select
                            .REG_DST        (REG_DST    ), //write destination in regfile (0 - rt, 1 - rd)
                            .IMMED_EXT      (IMMED_EXT  ), //immed ext (sign, zero, swap)
                            .MFCOP_SEL      (MFCOP_SEL  ), //move from coprocessor sel
                  
                            //External inst memory iface
                            .inst_mem_addr  (INST_ADDR),
                            .inst_mem_data  (INST_RD  ),
                                 
                            //External data memory iface
                            .data_mem_we    (DATA_WE  ),
                            .data_mem_be    (DATA_BE  ),
                            .data_mem_addr  (DATA_ADDR),
                            .data_mem_wdata (DATA_WD  ),
                            .data_mem_rdata (DATA_RD  ) );
            
          
endmodule
