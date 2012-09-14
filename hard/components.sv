//=============================================================//
module ffd #( parameter WIDTH = 32)
            ( input                  CLK, 
              input                  RESET,
              input                  EN,
              input      [WIDTH-1:0] D,
              output reg [WIDTH-1:0] Q );
                 
always_ff @(posedge CLK)
  if (RESET)  Q <= 0;
  else if(EN) Q <= D;

endmodule
//=============================================================//
module mux2 #(parameter WIDTH = 32)
             ( input             S,
               input [WIDTH-1:0] D0,
               input [WIDTH-1:0] D1,
               output[WIDTH-1:0] Y);

assign Y = S ? D1 : D0;

endmodule
//=============================================================//
module mux4 #(parameter WIDTH = 32)
             ( input [1:0] S,
               input [WIDTH-1:0] D0, D1, D2, D3,
               output[WIDTH-1:0] Y);

assign Y = S[1] ? (S[0] ? D3 : D2)
                : (S[0] ? D1 : D0);
                
endmodule
//=============================================================//
module mux8 #(parameter WIDTH = 32)
             ( input [2:0]       S,
               input [WIDTH-1:0] D0, D1, D2, D3, D4, D5, D6, D7,
               output[WIDTH-1:0] Y);

assign Y = S[2] ? (S[1] ? (S[0] ? D7 : D6) :
                          (S[0] ? D5 : D4)):
                  (S[1] ? (S[0] ? D3 : D2) :
                          (S[0] ? D1 : D0));

endmodule
//=============================================================//
module signext( input  [15:0] a,
                output [31:0] y );
                
assign y = {{16{a[15]}}, a};

endmodule
//=============================================================//
module immed_extend( input      [1:0] sel,
                     input      [15:0] immed,
                     output reg [31:0] immed_extend );
                     
always@(*)
  case(sel)
  2'b00:   immed_extend = {{16{immed[15]}}, immed}; //sign-extension
  2'b01:   immed_extend = {16'd0, immed};       //zero-extension
  2'b10:   immed_extend = 32'd0;                //zero for branches
  default: immed_extend = {immed, 16'd0};       //swap for lui 
  endcase
                     
endmodule
//=============================================================//
module sl2 (input  [31:0] a,
            output [31:0] y );

// shift left by 2
assign y = {a[29:00], 2'b00};

endmodule
//=============================================================//
module sync (  input  CLK,
               input  IN,
               output OUT );
 
reg [1:0] v;

always_ff @(posedge CLK)
  v <= {v[0], IN};

assign OUT = v[1];
               
endmodule
//=============================================================//
module edetect (  input  CLK,
                  input  IN,
                  output POS,
                  output NEG );
 
reg [1:0] v;

always@(posedge CLK)
  v <= {v[0], IN};

assign POS = v[0] & (~v[1]); 
assign NEG = v[1] & (~v[0]); 
               
endmodule
//===============================================//
module hystheresis (  input  CLK,
                      input  RESET,
                      input  IN,
                      output OUT );

reg [3:0] sr;
reg       val;

always_ff @(posedge CLK)
  if(RESET)
    begin
    sr <= 4'd0;
    val <= 1'b0;
    end
  else
    begin
    sr <= {sr[2:0], IN};
    if     (sr == '1)       val <= 1'b1;
    else if(sr == '0)       val <= 1'b0;
    else                    val <= val;
    end

assign OUT = val;
          
endmodule
