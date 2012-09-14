module alu( input   [6:0] ctrl,
            input  [31:0] A, 
            input  [31:0] B,
            input   [4:0] SH,
            output [31:0] Y,
            output        Z );

// ctrl  [6]: SHIFT SRC (1 - reg, 0 - shamt)
// ctrl[5:4]: SHIFT OP
// ctrl  [3]: NEGATE B
// ctrl[2:0]: ALU OP


wire Cin = ctrl[3]; //carry in. Equals 1 when B = NEGATE(B)
wire [31:0] BB; //inverted or not B
wire [31:0] Sum = A + BB + Cin;
wire [31:0] Zero_extend;

mux2 bb_mux( .S(ctrl[3]),
             .D0( B),
             .D1(~B),
             .Y (BB)  );


wire [4:0] shamt; 
mux2 #(5) shift_in_mux( .S (ctrl[6]),
                        .D0(SH),
                        .D1(A[4:0]),
                        .Y (shamt));

wire[31:0] sh_out;
shifter shifter_unit( .S(ctrl[5:4]),
                      .N(  shamt  ),
                      .A(    B    ),
                      .Y(  sh_out ) );


assign Zero_extend = {31'b0, Sum[31]};
mux8 out_mux( .S (  ctrl[2:0]      ),
              .D0(  A & BB         ),
              .D1(  A | BB         ),
              .D2(  A ^ BB         ),
              .D3(~(A | BB)        ),
              .D4(  Sum            ),
              .D5(  0              ), //mul? 
              .D6(  sh_out         ), 
              .D7(  Zero_extend    ),
              .Y (  Y              ) );

assign Z  = {Y == 32'b0};

endmodule

//-------------------------------------------------------------------------//
module shifter( input         [1:0] S,
                input         [4:0] N,
                input signed [31:0] A,
                output       [31:0] Y );
            
//sel[1]: 0 -- logical, 1 -- arithmetic
//sel[0]: 0 -- left,    1 --right

assign Y = S[1] ? (S[0] ? A >>> N : A <<< N) :
                  (S[0] ?  A >> N : A << N);
          
endmodule
//-------------------------------------------------------------------------//




/*
//-------------------------NORMAL-ADDER------------------------------//
module qqq_sum( input[31:0]  A, B,
                output[31:0] R,
                input  Cin );

//assign {Cout, R} = A + B + Cin;
assign R = A + B + Cin;

endmodule
//-------------------------RIPPLE-CARRY-ADDER------------------------------//
module rca_sum( input[31:0]  A, B,
                output[31:0] R,
                input  Cin,
                output Cout );

wire  c0,  c1,  c2,  c3,  c4,  c5,  c6,  c7,
      c8,  c9, c10, c11, c12, c13, c14, c15,
     c16, c17, c18, c19, c20, c21, c22, c23,
     c24, c25, c26, c27, c28, c29, c30;

full_adder  fa0(A[ 0], B[ 0], R[ 0], Cin,  c0);
full_adder  fa1(A[ 1], B[ 1], R[ 1],  c0,  c1);
full_adder  fa2(A[ 2], B[ 2], R[ 2],  c1,  c2);
full_adder  fa3(A[ 3], B[ 3], R[ 3],  c2,  c3);
full_adder  fa4(A[ 4], B[ 4], R[ 4],  c3,  c4);
full_adder  fa5(A[ 5], B[ 5], R[ 5],  c4,  c5);
full_adder  fa6(A[ 6], B[ 6], R[ 6],  c5,  c6);
full_adder  fa7(A[ 7], B[ 7], R[ 7],  c6,  c7);

full_adder  fa8(A[ 8], B[ 8], R[ 8],  c7,  c8);
full_adder  fa9(A[ 9], B[ 9], R[ 9],  c8,  c9);
full_adder fa10(A[10], B[10], R[10],  c9, c10);
full_adder fa11(A[11], B[11], R[11], c10, c11);
full_adder fa12(A[12], B[12], R[12], c11, c12);
full_adder fa13(A[13], B[13], R[13], c12, c13);
full_adder fa14(A[14], B[14], R[14], c13, c14);
full_adder fa15(A[15], B[15], R[15], c14, c15);

full_adder fa16(A[16], B[16], R[16], c15, c16);
full_adder fa17(A[17], B[17], R[17], c16, c17);
full_adder fa18(A[18], B[18], R[18], c17, c18);
full_adder fa19(A[19], B[19], R[19], c18, c19);
full_adder fa20(A[20], B[20], R[20], c19, c20);
full_adder fa21(A[21], B[21], R[21], c20, c21);
full_adder fa22(A[22], B[22], R[22], c21, c22);
full_adder fa23(A[23], B[23], R[23], c22, c23);

full_adder fa24(A[24], B[24], R[24], c23, c24);
full_adder fa25(A[25], B[25], R[25], c24, c25);
full_adder fa26(A[26], B[26], R[26], c25, c26);
full_adder fa27(A[27], B[27], R[27], c26, c27);
full_adder fa28(A[28], B[28], R[28], c27, c28);
full_adder fa29(A[29], B[29], R[29], c28, c29);
full_adder fa30(A[30], B[30], R[30], c29, c30);
full_adder fa31(A[31], B[31], R[31], c30, Cout);

endmodule
//-------------------------------------------------------------------------//

//--------------------------------------FULL ADDER-------------------------//
module full_adder( input A, B,
                   output S, 
                   input Cin,
                   output Cout );

   assign S = A ^ B ^ Cin;
   assign Cout = (A & B) | (A & Cin) | (B & Cin);

endmodule */