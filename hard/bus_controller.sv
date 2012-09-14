module bus_controller(  input  [29:0]  CPU_ADDR,
                        input          CPU_WE,
                        input  [03:0]  CPU_BE,
                        input  [31:0]  CPU_WD,
                        output [31:0]  CPU_RD,
               
                        output [29:0]  STACK_MEM_A,
                        output         STACK_MEM_WE,
                        output [03:0]  STACK_MEM_BE,
                        output [31:0]  STACK_MEM_WD,
                        input  [31:0]  STACK_MEM_RD,
                        
                        output [29:0]  CODE_MEM_A,
                        output         CODE_MEM_WE,
                        output [31:0]  CODE_MEM_WD,
                        input  [31:0]  CODE_MEM_RD,

                        output         JTAG_WE,
                        output [31:0]  JTAG_WD,
                        input  [31:0]  JTAG_RD,
                        
                        output         ADC_WE,
                        output [31:0]  ADC_WD,
                        input  [31:0]  ADC_RD,
                        
                        input  [31:0]  USER_IO,
                        
                        output         LEDS_WE,
                        output [31:0]  LEDS_WD  );

wire [31:0] IO_MEM_RD;
wire        IO_MEM_WE;

aspace_mux address_space_mux( .SEL         ( CPU_ADDR[29:28] ),
                              .CPU_WE      ( CPU_WE          ),
                              .CPU_RD      ( CPU_RD          ),
                              .DATA_SEG    ( STACK_MEM_RD    ),
                              .DATA_SEG_WE ( STACK_MEM_WE    ),
                              .CODE_SEG    ( CODE_MEM_RD     ),
                              .CODE_SEG_WE ( CODE_MEM_WE     ),
                              .IO_SEG      ( IO_MEM_RD       ),
                              .IO_SEG_WE   ( IO_MEM_WE       ) );

iospace_mux inout_space_mux(  .SEL         ( CPU_ADDR[1:0] ),        
                              .IO_SEG_WE   ( IO_MEM_WE     ),
                              .IO_SEG      ( IO_MEM_RD     ),
                      
                              .IO_0_RD     ( JTAG_RD       ),
                              .IO_0_WE     ( JTAG_WE       ),
                      
                              .IO_1_RD     ( USER_IO       ), //LEDs
                              .IO_1_WE     ( LEDS_WE       ), //reading leds returns uio
                              
                              .IO_2_RD     ( ADC_RD        ), //ADC
                              .IO_2_WE     ( ADC_WE        ),
                              
                              .IO_3_RD     ( 32'h10203040  )  //unused -- ret const
                              );
                              
assign STACK_MEM_A   = CPU_ADDR;
assign STACK_MEM_WD  = CPU_WD;

assign CODE_MEM_A    = CPU_ADDR;
assign CODE_MEM_WD   = CPU_WD;

assign ADC_WD        = CPU_WD;
assign LEDS_WD       = CPU_WD;
assign JTAG_WD       = CPU_WD;

assign STACK_MEM_BE  = CPU_BE;

endmodule
//================================================================//
module aspace_mux (  input   [1:0] SEL,
                     input         CPU_WE,
                     output [31:0] CPU_RD,
                     
                     input  [31:0] DATA_SEG,
                     output        DATA_SEG_WE,
                     
                     input  [31:0] CODE_SEG,
                     output        CODE_SEG_WE,
                     
                     input  [31:0] IO_SEG,
                     output        IO_SEG_WE );
                     

logic [34:0] ctrl;

always_comb
   case(SEL)
   2'b00:   ctrl = {3'b001, IO_SEG};   //IO  : ADDR[31:30] == 2'b00
   2'b01:   ctrl = {3'b010, CODE_SEG}; //CODE: ADDR[31:30] == 2'b01
   default: ctrl = {3'b100, DATA_SEG}; //DATA: ADDR[31:30] == 2'b1X
   endcase

assign CPU_RD = ctrl[31:0];
assign DATA_SEG_WE = CPU_WE & ctrl[34];
assign CODE_SEG_WE = CPU_WE & ctrl[33];
assign IO_SEG_WE   = CPU_WE & ctrl[32];

endmodule
//================================================================//
module iospace_mux (  input   [1:0] SEL,        
                      input         IO_SEG_WE,
                      output [31:0] IO_SEG,
                      
                      input  [31:0] IO_0_RD,
                      output        IO_0_WE,
                      
                      input  [31:0] IO_1_RD,
                      output        IO_1_WE,

                      input  [31:0] IO_2_RD,
                      output        IO_2_WE,

                      input  [31:0] IO_3_RD,
                      output        IO_3_WE );
                      
logic [3:0] wes;
logic [31:0] out;

always_comb
   begin
   wes = '0;
   wes[SEL] = IO_SEG_WE;
   end

always_comb
   case(SEL)
   2'd0: out = IO_0_RD;
   2'd1: out = IO_1_RD;
   2'd2: out = IO_2_RD;
   2'd3: out = IO_3_RD;
   endcase
   
assign IO_0_WE = wes[0];
assign IO_1_WE = wes[1];
assign IO_2_WE = wes[2];
assign IO_3_WE = wes[3];

assign IO_SEG = out;

endmodule
