module datapath ( input CLK,
                  input CLK_MEM,
                  input RESET,
                  input RUN,

                 //Controller iface
                  input        WRITE_REG,    //write to register file
                  input        WRITE_MEM,    //write data memory
                  input        ALUORMEM_WR,  //write regfile from alu or from memory
                  input        MEM_PARTIAL,  //memory byte- or halfword access
                  input  [1:0] MEM_OPTYPE,   //mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh 
                  input        MULTIPLY,     //do multiplication and write hi&lo
                  input        BRANCH_E,     //branch equal
                  input        BRANCH_NE,    //branch not equal
                  input        BRANCH_LEZ,   //branch less than or equal zero
                  input        BRANCH_LTZ,   //branch less than zero
                  input        BRANCH_GEZ,   //branch greater than or equal zero
                  input        BRANCH_GTZ,   //branch greater than zero
                  input        JUMP,         //j-type jump
                  input        JUMP_R,       //jr, jalr
                  input        ALU_SRC_B,    //ALU Operand B 0 - reg_2, 1 - immediate
                  input  [6:0] ALU_OP,       //ALU Operation select
                  input  [1:0] REG_DST,      //write destination in regfile (0 - rt, 1 - rd, 1X -- 31)
                  input  [1:0] IMMED_EXT,    //immediate extension type (sign, zero, swap)
                  input  [1:0] MFCOP_SEL,    //move from cop sel. 0 - from alu, 1 - from HI, 2 - from LO, 3 -- from C0
 
                  output [5:0] OPCODE,       //instruction opcode
                  output [5:0] FCODE,        //instruction fcode
                  output [4:0] RT,           //instruction RT field
                 
                 //External inst memory iface
                  output [29:0] inst_mem_addr,
                  input  [31:0] inst_mem_data,

                 //External data memory iface
                  output        data_mem_we,
                  output [ 3:0] data_mem_be,
                  output [29:0] data_mem_addr,
                  output [31:0] data_mem_wdata,
                  input  [31:0] data_mem_rdata );

//------------------------WIRE DEFINITIONS-----------------------------------//
//FETCH:
wire [31:0] branch_target, jump_target, jumpr_target, next_pc_reg, pc, pc_plus_4;

//DECODE:
wire [31:0] inst_d, pc_plus_4_d, rd1, rd2, regfile_wdata, immed_extend_d, immed_extend_sl2_d,
            rd1_fwd, rd2_fwd;
wire  [4:0] reg_dst_addr_w, rs_d, rt_d;

wire        link_d, do_branch, stall, lw_stall, br_stall;

//EXECUTE:
wire [31:0] pc_plus_4_e, immed_extend_e, src_a_e, src_b_e, 
            src_a_fwd_e, src_b_fwd_e, src_a, src_b, hi_e,
            lo_e, aluout_e, aluout_mux_e;
wire  [6:0] alu_op_e;
wire  [4:0] reg_dst_addr_e, rs_e, rt_e, rd_e, shamt_e;
wire  [1:0] reg_dst_e, mfcop_sel_e, mem_optype_e;
wire        write_reg_e, write_mem_e, aluormem_e, multiply_e, 
            alu_src_b_e, link_e, alu_zero, mem_partial_e;

//MEM:
wire [31:0] aluout_m, src_b_m, mem_reordered_m;
wire  [4:0] reg_dst_addr_m;
wire  [1:0] mem_optype_m;
wire        write_reg_m, write_mem_m, aluormem_m, mem_partial_m;

//WRITEBACK:
wire [31:0] aluout_w, mem_reordered_w;
wire        write_reg_w, aluormem_w;

//------------------------FETCH STAGE----------------------------------------//
assign pc_plus_4 = pc + 4;
assign stall = lw_stall | br_stall;
assign inst_mem_addr = pc[31:2];

wire [1:0] next_pc_select = JUMP      ? 2'b11 :
                            JUMP_R    ? 2'b10 :
                            do_branch ? 2'b01 :
                                        2'b00 ;

mux4  pc_src_mux( next_pc_select,
                  pc_plus_4,        //00: pc = pc + 4
                  branch_target,    //01: conditional branch
                  jumpr_target,     //10: from register file
                  jump_target,      //11: from j-type instruction
                  next_pc_reg );

ffd   pc_reg(CLK, RESET, ~stall & RUN, next_pc_reg, pc );

ffd #(64) pipe_reg_D(CLK, RESET, ~stall & RUN, 
                              {  inst_mem_data, 
                                 pc_plus_4 }, 

                              {  inst_d, 
                                 pc_plus_4_d }); 
//---------------------------------------------------------------------------//


//------------------------DECODE STAGE---------------------------------------//
assign OPCODE = inst_d[31:26];
assign FCODE  = inst_d [5:0];
assign RT     = inst_d[20:16];

assign rs_d = inst_d[25:21];
assign rt_d = inst_d[20:16];

regfile rf_unit(.CLK        (CLK_MEM        ), 
                .WE         (write_reg_w    ), 
                .RD_ADDR_1  (rs_d           ),  //in_rd_addr
                .RD_ADDR_2  (rt_d           ),  //in_rd_addr
                .WR_ADDR_3  (reg_dst_addr_w ),  //in_wr_addr
                .W_DATA     (regfile_wdata  ),  //in
                .R_DATA_1   (rd1            ),  //out
                .R_DATA_2   (rd2            )); //out

//------IMMEDIATE EXTENSION--------                
immed_extend immed_ext_unit(IMMED_EXT, inst_d[15:0], immed_extend_d);


//------BRANCH LOGIC-------
sl2 shl2_unit(immed_extend_d, immed_extend_sl2_d);

wire fwd_br_a = (rs_d != 0) && (rs_d == reg_dst_addr_m) && write_reg_m;
wire fwd_br_b = (rt_d != 0) && (rt_d == reg_dst_addr_m) && write_reg_m;

mux2 fwd_br_a_mux(fwd_br_a, rd1,            //0 -- no forwarding
                            aluout_m,       //1 -- forward from MEM
                            rd1_fwd );

mux2 fwd_br_b_mux(fwd_br_b, rd2,            //0 -- no forwarding
                            aluout_m,       //1 -- forward from MEM
                            rd2_fwd );

wire br_inst =  BRANCH_E   | BRANCH_NE  | BRANCH_LEZ |
                BRANCH_LTZ | BRANCH_GEZ | BRANCH_GTZ |
                JUMP | JUMP_R;

assign br_stall =  (rs_d != 0) & br_inst &
                  ((write_reg_e & ((reg_dst_addr_e == rs_d)    |    
                                   (reg_dst_addr_e == rt_d) )) |
                   (aluormem_m  & ((reg_dst_addr_m == rs_d)    |    //lw
                                   (reg_dst_addr_m == rt_d) )));



assign branch_target = immed_extend_sl2_d + pc_plus_4_d;
assign jump_target   = {pc_plus_4_d[31:28], inst_d[25:0], 2'b00};
assign jumpr_target  = rd1_fwd; 

wire regs_equal = (rd1_fwd == rd2_fwd);
wire reg_zero   = (rd1_fwd == 0);
assign do_branch = ( (BRANCH_E   &  regs_equal)    |
                     (BRANCH_NE  & ~regs_equal)    |
                     (BRANCH_LEZ & ( rd1_fwd[31]   |  reg_zero)) |  // <= 0
                     (BRANCH_LTZ &   rd1_fwd[31] ) |  // <  0
                     (BRANCH_GEZ &  ~rd1_fwd[31] ) |  // >= 0
                     (BRANCH_GTZ & (~rd1_fwd[31] & ~reg_zero)) ); // >  0

assign link_d = JUMP | JUMP_R | BRANCH_GEZ | BRANCH_LTZ;



ffd #(168) pipe_reg_E(CLK, RESET | stall, RUN,
                  {  WRITE_REG,         // 1/ write to register file
                     WRITE_MEM,         // 1/ write data memory
                     MEM_PARTIAL,       // 1/ memory byte- or halfword access
                     MEM_OPTYPE,        // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     ALUORMEM_WR,       // 1/ write regfile from alu or from memory
                     MULTIPLY,          // 1/ do multiplication and write hi&lo
                     link_d,            // 1/ link
                     ALU_SRC_B,         // 1/ ALU Operand B 0 - reg_2, 1 - immediate
                     ALU_OP,            // 7/ ALU Operation select
                     REG_DST,           // 2/ write destination in regfile (0 - rt, 1 - rd)
                     MFCOP_SEL,         // 2/ mfrom coprocessor selector
                     rd1,               //32/ regfile_out_1
                     rd2,               //32/ regfile_out_2
                     rs_d,              // 5/ RS
                     rt_d,              // 5/ RT
                     inst_d[15:11],     // 5/ RD
                     inst_d[10:06],     // 5/ SHAMT
                     immed_extend_d,    //32/ immediate
                     pc_plus_4_d  },    //32/ pc plus 4

                  {  write_reg_e,       // 1/ write to register file
                     write_mem_e,       // 1/ write data memory
                     mem_partial_e,     // 1/ memory byte- or halfword access
                     mem_optype_e,      // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     aluormem_e,        // 1/ write regfile from alu or from memory
                     multiply_e,        // 1/ do multiplication and write hi&lo
                     link_e,            // 1/ link
                     alu_src_b_e,       // 1/ ALU Operand B 0 - reg_2, 1 - immediate
                     alu_op_e,          // 7/ ALU Operation select
                     reg_dst_e,         // 2/ write destination in regfile (0 - rt, 1 - rd)
                     mfcop_sel_e,       // 2/ mfrom coprocessor selector
                     src_a_e,
                     src_b_e,
                     rs_e,
                     rt_e,
                     rd_e,
                     shamt_e,
                     immed_extend_e, 
                     pc_plus_4_e  }); 
                
//---------------------------------------------------------------------------//

//------------------------EXECUTE STAGE--------------------------------------//

mux4 #(5) regfile_wr_addr_mux( reg_dst_e, 
                               rt_e, 
                               rd_e,
                               5'd31, //ra
                               5'd31, //ra
                               reg_dst_addr_e);



//forwarding mux's
wire [1:0] fwd_a = ((rs_e != 0) && (rs_e == reg_dst_addr_m) && write_reg_m) ? 2'b10 :
                   ((rs_e != 0) && (rs_e == reg_dst_addr_w) && write_reg_w) ? 2'b01 :
                                                                              2'b00;

wire [1:0] fwd_b = ((rt_e != 0) && (rt_e == reg_dst_addr_m) && write_reg_m) ? 2'b10 :
                   ((rt_e != 0) && (rt_e == reg_dst_addr_w) && write_reg_w) ? 2'b01 :
                                                                              2'b00;

//lw stall logic
assign lw_stall = aluormem_e & ((rs_d == rt_e) | 
                                (rt_d == rt_e) );

mux4 fwd_src_a(fwd_a, src_a_e,        //00 -- no forwarding
                      regfile_wdata,  //01 -- forward from WB
                      aluout_m,       //10 -- forward from MEM
                      src_a_e,        //11 -- no forwarding
                      src_a_fwd_e );

mux4 fwd_src_b(fwd_b, src_b_e,        //00 -- no forwarding
                      regfile_wdata,  //01 -- forward from WB
                      aluout_m,       //10 -- forward from MEM
                      src_b_e,        //11 -- no forwarding
                      src_b_fwd_e );

//final alu muxes
mux2 alu_src_a_mux( link_e,
                    src_a_fwd_e,
                    pc_plus_4_e,
                    src_a );

mux4 alu_src_b_mux( {link_e, alu_src_b_e}, 
                    src_b_fwd_e,    //00: forwarded src b 
                    immed_extend_e, //01: immediate
                    32'd4,          //10: 4 for ret_addr calculation
                    32'd4,          //11: 4 for ret_addr calculation
                    src_b );

alu alu(alu_op_e, src_a, src_b, shamt_e, aluout_e, alu_zero);

wire [63:0] product_e = src_a_fwd_e * src_b_fwd_e;
ffd #( 64) hi_lo_reg(CLK, RESET, multiply_e & RUN, product_e, {hi_e, lo_e});

mux4 aluout_mux(  mfcop_sel_e,
                  aluout_e,
                  hi_e,           //MFHI
                  lo_e,           //MFLO
                  32'hXXXXXXXX,   //MFC0
                  aluout_mux_e ); 

ffd #( 75) pipe_reg_M(CLK, RESET, RUN,
                  {  write_reg_e,       // 1/ write to register file
                     write_mem_e,       // 1/ write data memory
                     mem_partial_e,     // 1/ memory byte- or halfword access
                     mem_optype_e,      // 2/ mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh
                     aluormem_e,        // 1/ write regfile from alu or from memory
                     aluout_mux_e,      //32/ ALU result
                     src_b_fwd_e,       //32/ regfile data B
                     reg_dst_addr_e },  // 5/ destination reg addr

               
                  {  write_reg_m,
                     write_mem_m,
                     mem_partial_m,         
                     mem_optype_m,
                     aluormem_m,
                     aluout_m,
                     src_b_m,
                     reg_dst_addr_m });

//---------------------------------------------------------------------------//

//------------------------MEMORY STAGE---------------------------------------//
assign data_mem_we = write_mem_m;
assign data_mem_addr = aluout_m[31:2];

store_reorder st_reorder_unit( .LO_ADDR ( aluout_m[1:0]  ),
                               .DATA_IN ( src_b_m        ),
                               .PARTIAL ( mem_partial_m  ),
                               .OP_TYPE ( mem_optype_m   ),
                      
                               .BYTE_EN ( data_mem_be    ),
                               .DATA_OUT( data_mem_wdata ));

load_reorder ld_reorder_unit( .LO_ADDR ( aluout_m[1:0]  ),
                              .DATA_IN ( data_mem_rdata ),
                              .PARTIAL ( mem_partial_m  ),
                              .OP_TYPE ( mem_optype_m   ),
                              .DATA_OUT( mem_reordered_m)); 


ffd #( 71) pipe_reg_W(CLK, RESET, RUN,
                  {  write_reg_m,        // 1/ write to register file
                     aluormem_m,         // 1/ write regfile from alu or from memory
                     aluout_m,           //32/ alu result
                     mem_reordered_m,    //32/ memory data
                     reg_dst_addr_m},    // 5/ destination register
                     
                  {  write_reg_w,        // 1/ write to register file
                     aluormem_w,         // 1/ write regfile from alu or from memory
                     aluout_w,           //32/ alu result
                     mem_reordered_w,    //32/ memory data
                     reg_dst_addr_w} );  // 5/ destination register
                     
//---------------------------------------------------------------------------//

//-----------------------WRITEBACK STAGE-------------------------------------//
mux2 regfile_wr_data_mux( aluormem_w, 
                          aluout_w,        //0: ALU out
                          mem_reordered_w, //1: MEM out
                          regfile_wdata);
//---------------------------------------------------------------------------//
                
endmodule

