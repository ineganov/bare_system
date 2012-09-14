module io8( input         CLK,
            input         WE,
            input  [31:0] DATA_IN,
            output  [7:0] IO_OUT );

//reg [31:0] out_reg;
reg [7:0] out_reg;

always@ (posedge CLK)
   if(WE) out_reg <= DATA_IN[7:0];

//assign IO_OUT = SEL[1] ? (SEL[0] ? out_reg[31:24] : out_reg[23:16]) :
//                         (SEL[0] ? out_reg[15:08] : out_reg[07:00]);

assign IO_OUT = out_reg;

endmodule
