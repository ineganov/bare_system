module io6( input         CLK_IO,
            input   [1:0] BTNS,
            input   [3:0] DIP_SW,
            output [31:0] IO_OUT );

logic [5:0] stage1, stage2;

always_ff @(posedge CLK_IO)
   begin
   stage1 <= {~BTNS, DIP_SW};
   stage2 <= stage1;
   end

assign IO_OUT = {26'd0, stage2};

endmodule
