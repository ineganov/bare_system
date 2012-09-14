//===============================================//
module imem ( input         CLK,
              input  [29:0] DATA_A,
              input         DATA_WE,
              input  [31:0] DATA_WD,
              output [31:0] DATA_RD,

              input  [29:0] MAIN_A, 
              output [31:0] MAIN_RD );

//the mem must be registered to synthesize properly
//on altera cyclone-3 devices

              
logic [31:0] RAM[0:1023];
logic [31:0] read_reg_1, read_reg_2;

initial
  $readmemh ("soft/program.txt", RAM);

always_ff@(posedge CLK)
   begin
   if(DATA_WE) RAM[DATA_A] <= DATA_WD;
   read_reg_1 <= RAM[MAIN_A];
   read_reg_2 <= RAM[DATA_A];
   end
  
assign MAIN_RD = read_reg_1;
assign DATA_RD = read_reg_2;

endmodule
//===============================================//

//===============================================//
module dmem ( input        CLK,
              input        WE,
              input [ 3:0] BE,    
              input [29:0] ADDR, 
              input [31:0] WD,
              output[31:0] RD );

parameter D = 6;
              
logic [3:0][7:0] RAM[0:2**D-1];
logic [31:0] read_reg;

initial
  $readmemh ("soft/data.txt", RAM);

always_ff@(posedge CLK)
   begin
   if (WE) 
     begin
     if(BE[0]) RAM[ADDR[D-1:0]][0] <= WD[07:00];
     if(BE[1]) RAM[ADDR[D-1:0]][1] <= WD[15:08];
     if(BE[2]) RAM[ADDR[D-1:0]][2] <= WD[23:16];
     if(BE[3]) RAM[ADDR[D-1:0]][3] <= WD[31:24];
     end
   read_reg <= RAM[ADDR[D-1:0]];
   end

assign RD = read_reg;

endmodule
//===============================================//
