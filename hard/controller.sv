module controller ( input   [5:0] OPCODE,       //instruction opcode
                    input   [5:0] FCODE,        //instruction fcode
                    input   [4:0] RT,           //instruction RT field

                    output        WRITE_REG,    //write to register file
                    output        WRITE_MEM,    //write data memory
                    output        MEM_PARTIAL,  //memory byte- or halfword access
                    output  [1:0] MEM_OPTYPE,   //mem op: 00-ubyte, 01-uhalf, 10-sb, 11-sh 
                    output        ALUORMEM_WR,  //write regfile from alu or from memory
                    output        MULTIPLY,     //do multiplication and write hi&lo
                    output        BRANCH_E,     //branch equal
                    output        BRANCH_NE,    //branch not equal
                    output        BRANCH_LEZ,   //branch less than or equal zero
                    output        BRANCH_LTZ,   //branch less than zero
                    output        BRANCH_GEZ,   //branch greater than or equal zero
                    output        BRANCH_GTZ,   //branch greater than zero
                    output        JUMP,         //j-type jump
                    output        JUMP_R,       //r-type jump
                    output        ALU_SRC_B,    //ALU Operand B 0 - reg_2, 1 - immediate
                    output  [6:0] ALU_OP,       //ALU Operation select
                    output  [1:0] REG_DST,      //write destination in regfile (0 - rt, 1 - rd, 1X - 31)
                    output  [1:0] IMMED_EXT,
                    output  [1:0] MFCOP_SEL );  //move from cop sel. 0 - from alu, 1 - from HI, 2 - from LO, 3 -- from C0

                    
parameter OP_RT    = 6'b000000; //regtype

parameter OP_LW    = 6'b100011;
parameter OP_LH    = 6'b100001;
parameter OP_LHU   = 6'b100101;
parameter OP_LB    = 6'b100000;
parameter OP_LBU   = 6'b100100;

parameter OP_SW    = 6'b101011;
parameter OP_SH    = 6'b101001;
parameter OP_SB    = 6'b101000;

parameter OP_ADDI  = 6'b001000;
parameter OP_ADDIU = 6'b001001;
parameter OP_ANDI  = 6'b001100;
parameter OP_ORI   = 6'b001101;
parameter OP_XORI  = 6'b001110;
parameter OP_LUI   = 6'b001111;

parameter OP_BRT   = 6'b000001; //1 branch-type
parameter OP_BEQ   = 6'b000100; //4
parameter OP_BNE   = 6'b000101; //5
parameter OP_BLEZ  = 6'b000110; //6
parameter OP_BGTZ  = 6'b000111; //7

parameter OP_J     = 6'b000010;
parameter OP_JAL   = 6'b000011;
parameter OP_SLTI  = 6'b001010;
parameter OP_SLTIU = 6'b001011;
 
logic  [28:0] controls;
assign { WRITE_REG, 
         WRITE_MEM,
         MEM_PARTIAL,
         MEM_OPTYPE,
         ALUORMEM_WR, //0 - alu
         MULTIPLY,
         REG_DST,     //00:RT,  01:RD, 1X:31
         MFCOP_SEL,   //00:ALU, 01:FROM_HI, 10:FROM_LO, 11:COP0
         BRANCH_E,
         BRANCH_NE,
         BRANCH_LEZ,
         BRANCH_LTZ,
         BRANCH_GEZ,
         BRANCH_GTZ,
         JUMP,
         JUMP_R,
         ALU_SRC_B, //0:R, 1:I
         IMMED_EXT,
         ALU_OP } = controls;

always_comb
  case(OPCODE)              
    OP_RT:
      case(FCODE)             //R_MPTT_AM_RD_MC_BRANCH_JR_S_IE_ALUCTRL 
      6'b100000: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0100; // ADD
      6'b100001: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0100; // ADDU
      6'b100010: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX1100; // SUB
      6'b100011: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX1100; // SUBU
            
      6'b100100: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0000; // AND
      6'b100101: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0001; // OR
      6'b100110: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0010; // XOR
      6'b100111: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX0011; // NOR
            
      6'b101010: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX1111; // SLT
      6'b101011: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_XXX1111; // SLTU
            
      6'b000000: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_0000110; // SLL
      6'b000010: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_0010110; // SRL
      6'b000011: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_0110110; // SRA
      6'b000100: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_1000110; // SLLV
      6'b000110: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_1010110; // SRLV
      6'b000111: controls = 29'b1_0XXX_00_01_00_000000_00_0_XX_1110110; // SRAV
            
      6'b001000: controls = 29'b0_0XXX_00_01_00_000000_01_0_XX_XXX0100; // JR
      6'b001001: controls = 29'b1_0XXX_00_01_00_000000_01_0_XX_XXX0100; // JALR

      6'b010000: controls = 29'b1_0XXX_00_01_01_000000_00_X_XX_XXXXXXX; // MFHI
      6'b010010: controls = 29'b1_0XXX_00_01_10_000000_00_X_XX_XXXXXXX; // MFLO
      
      6'b011000: controls = 29'b0_0XXX_01_01_00_000000_00_X_XX_XXXXXXX; // MULT //same as multu for now
      6'b011001: controls = 29'b0_0XXX_01_01_00_000000_00_X_XX_XXXXXXX; // MULTU
            
      default:   controls = 29'b0_0XXX_X0_XX_00_000000_00_0_XX_XXXXXXX; // ???      
      endcase
                           //R_MPTT_AM_RD_MC_BRANCH_JR_S_IE_ALUCTRL
    OP_LW:    controls = 29'b1_00XX_10_00_00_000000_00_1_00_XXX0100;
    OP_LH:    controls = 29'b1_0111_10_00_00_000000_00_1_00_XXX0100; 
    OP_LHU:   controls = 29'b1_0101_10_00_00_000000_00_1_00_XXX0100; 
    OP_LB:    controls = 29'b1_0110_10_00_00_000000_00_1_00_XXX0100; 
    OP_LBU:   controls = 29'b1_0100_10_00_00_000000_00_1_00_XXX0100; 
    
    OP_SW:    controls = 29'b0_10XX_00_00_00_000000_00_1_00_XXX0100;
    OP_SH:    controls = 29'b0_11X1_00_00_00_000000_00_1_00_XXX0100;
    OP_SB:    controls = 29'b0_11X0_00_00_00_000000_00_1_00_XXX0100;
  

    OP_ADDI:  controls = 29'b1_0XXX_00_00_00_000000_00_1_00_XXX0100;
    OP_ADDIU: controls = 29'b1_0XXX_00_00_00_000000_00_1_00_XXX0100;
    OP_ANDI:  controls = 29'b1_0XXX_00_00_00_000000_00_1_01_XXX0000;
    OP_ORI:   controls = 29'b1_0XXX_00_00_00_000000_00_1_01_XXX0001;
    OP_XORI:  controls = 29'b1_0XXX_00_00_00_000000_00_1_01_XXX0010;
    
    OP_SLTI:  controls = 29'b1_0XXX_00_00_00_000000_00_1_00_XXX1111;
    OP_SLTIU: controls = 29'b1_0XXX_00_00_00_000000_00_1_01_XXX1111;

    OP_LUI:   controls = 29'b1_0XXX_00_00_00_000000_00_1_11_XXX0100; 
    OP_BEQ:   controls = 29'b0_0XXX_00_XX_00_100000_00_0_00_XXX1100; 
    OP_BNE:   controls = 29'b0_0XXX_00_XX_00_010000_00_0_00_XXX1100;
    OP_BLEZ:  controls = 29'b0_0XXX_00_XX_00_001000_00_0_00_XXX0100;  
    OP_BGTZ:  controls = 29'b0_0XXX_00_XX_00_000001_00_0_00_XXX0100;
     
    OP_BRT:
      case(RT)               //R_MPTT_AM_RD_MC_BRANCH_JR_S_IE_ALUCTRL
      5'b00000: controls = 29'b0_0XXX_00_11_00_000100_00_0_00_XXX0100;// BLTZ
      5'b10000: controls = 29'b1_0XXX_00_11_00_000100_00_0_00_XXX0100;// BLTZAL
      5'b00001: controls = 29'b0_0XXX_00_11_00_000010_00_0_00_XXX0100;// BGEZ
      5'b10001: controls = 29'b1_0XXX_00_11_00_000010_00_0_00_XXX0100;// BGEZAL
      default:  controls = 29'b0_0XXX_X0_XX_00_000000_00_0_XX_XXXXXXX;
      endcase
                           //R_MPTT_AM_RD_MC_BRANCH_JR_S_IE_ALUCTRL
    OP_J:     controls = 29'b0_0XXX_00_11_00_000000_10_X_XX_XXX0100;
    OP_JAL:   controls = 29'b1_0XXX_00_11_00_000000_10_X_XX_XXX0100;
    
    default:  controls = 29'b0_0XXX_X0_XX_00_000000_00_0_XX_XXXXXXX;
  endcase

endmodule
