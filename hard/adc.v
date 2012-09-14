module adc_interface (  input         CLK,
                        input         CLK_1M,
                      
                      //processor interface
                        input  [31:0] DATA_IN,
                        output [31:0] DATA_OUT,
                        input         WR,

                      //device interface
                        output        CS,
                        output        SCLK,
                        output        SDO,
                        input         SDI  );  
                        
wire DEV_BUSY;

reg [1:0] state = 0, nextstate = 0;
reg [2:0] channel;
reg [11:0] saved_data;

wire [11:0] conv_result;
wire request  = (state == 2'd1);
wire busy     = (state != 2'd0);

always@ (*)
  case(state)
  2'd0: if (WR)         nextstate = 1; //wait for request
        else            nextstate = 0;
                  
  2'd1: if (DEV_BUSY)   nextstate = 2; //wait for device to start
        else            nextstate = 1;
        
  2'd2: if (!DEV_BUSY)  nextstate = 3; //wait for device to stop
        else            nextstate = 2;
        
  default:              nextstate = 0;
  
  endcase
  
always@ (posedge CLK)
  begin
  state <= nextstate;
  if(WR) channel <= DATA_IN[2:0];
  if(state == 3) saved_data <= conv_result;
  end
  
   
assign DATA_OUT = {busy, 19'd0, saved_data};  
  
spi4 spi4_m(  .CLK         ( CLK_1M      ),
              
              .CHANNEL     ( channel     ),
              .CONV_RESULT ( conv_result ),
              .REQUEST     ( request     ),
              .BUSY        ( DEV_BUSY    ),
              
              .CS          ( CS          ),
              .SCLK        ( SCLK        ),  
              .SDO         ( SDO         ),  
              .SDI         ( SDI         ));

                        
endmodule



module spi4(  input   CLK,
             
              //host interface
              input  [ 2:0] CHANNEL,
              output [11:0] CONV_RESULT,
              input         REQUEST,
              output        BUSY,
              
              //device interface
              output  CS,
              output  SCLK,
              output  SDO,
              input   SDI  );

reg [ 4:0] tx_sreg = 0;
reg [15:0] rx_sreg = 0;
reg [11:0] saved_data = 0;
reg [4:0] bit_cnt = 0;

              
always @(negedge CLK)
  begin
  if(BUSY)
    begin
    if(bit_cnt < 16)  bit_cnt <= bit_cnt + 5'd1;
    else              
      begin
      saved_data <= rx_sreg[11:0];
      bit_cnt <= 0;
      end
      
    tx_sreg[4:1] <= tx_sreg[3:0];
    tx_sreg[0] <= 0;
      
    end
  else
    begin
    if(REQUEST)
      begin
      bit_cnt <= 1;
      tx_sreg <= {2'b0, CHANNEL};
      end
    end
  end              


always@(posedge CLK)
  begin
  if(BUSY)
    begin
    rx_sreg[0] <= SDI;
    rx_sreg[15:1] <= rx_sreg[14:0];
    end
  end

//-----------------------------------------------

assign BUSY = (bit_cnt != 5'd0);
assign CS   = ~BUSY;
assign SDO  = tx_sreg[4];
assign SCLK = BUSY & CLK;
assign CONV_RESULT = saved_data; 

endmodule
              