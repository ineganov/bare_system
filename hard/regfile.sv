module regfile(   input           CLK,
                  input   [4:0]   RD_ADDR_1, 
                  input   [4:0]   RD_ADDR_2, 
                  input   [4:0]   WR_ADDR_3,
                  input   [31:0]  W_DATA,
                  input           WE,
                  output  [31:0]  R_DATA_1,
                  output  [31:0]  R_DATA_2);

logic [31:0] rf[31:0];
logic [31:0] rd1, rd2, rd_reg1, rd_reg2;

always_ff@ (posedge CLK)
   begin
   if(WE) rf[WR_ADDR_3] <= W_DATA;

   rd_reg1 <= rf[RD_ADDR_1];
   rd_reg2 <= rf[RD_ADDR_2];

   end

always_comb
  begin
  if(WE)
    begin
      if      (RD_ADDR_1 == 0)          rd1 = 0;
      else if (RD_ADDR_1 == WR_ADDR_3)  rd1 = W_DATA;
      else                              rd1 = rd_reg1;
    end
  else
    begin
      if      (RD_ADDR_1 == 0)          rd1 = 0;
      else                              rd1 = rd_reg1;
    end
  end

always_comb
  begin
  if(WE)
    begin
      if      (RD_ADDR_2 == 0)          rd2 = 0;
      else if (RD_ADDR_2 == WR_ADDR_3)  rd2 = W_DATA;
      else                              rd2 = rd_reg2;
    end
  else
    begin
      if      (RD_ADDR_2 == 0)          rd2 = 0;
      else                              rd2 = rd_reg2;
    end
  end

assign R_DATA_1 = rd1;
assign R_DATA_2 = rd2;

endmodule

