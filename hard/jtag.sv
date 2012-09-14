// Virtual JTAG module
// 
// The module consists of 4 register chains + bypass (ergo 3 bit jtag instructions)

// chain 1: control, L=3bit 
// Used to setup debug facilities, such as reset, run/stop and instruction source
// {RESET, STOP, INST_SRC}
// RESET is active-1, RUN is active-0 (hence a STOP) and INST_SRC is 0 for the mem, 1 for JTAG

// chain 2: JTAG DEBUG, L=32bit
// Used to feed CPU with instructions from JTAG port 
// Receives instruction as input, transmits requested addr as output
// Strobes RUN after each access

// chain 3: MEM DEBUG, L=64bit
// Used to debug program in memory
// Read-only chain. It has 32bit addr in MSB and 32bit instr in LSB
// Strobes RUN after each access

// chain 4: DATA IO, L=32bit
// Used for data interchange between CPU and HOST.
// RW 32-bit word. Beware of the timing and use some kind of mailbox logic!!


module jtag    (  input         CPU_CLK,

                  //primary CPU CONTROLS
                  output        RESET,       //cpu reset, 1 -- reset;
                  output        RUN,         //cpu run. 0 - pause, 1 - run. Pulsed in step-by-step
                  output        I_SOURCE,    //cpu instruction source; 0 for normal mem
                  
                  //32bit DEBUG DATA PORT
                  input         WE,
                  input  [31:0] WD,
                  output [31:0] RD,
                  
                  //32bit DEBUG INSTR PORT
                  output [31:0] DEBUG_INST,  //cpu instruction from jtag
                  input  [31:0] MEM_INST,    //current instruction from main mem
                  input  [29:0] INST_ADDR ); //cpu inst memory address

wire [2:0] INST;
wire [2:0] INST_READOUT = 3'b101;

wire  TCK, TDI, TDO;
wire  TDO_ctrl, TDO_jtrace, TDO_mtrace, TDO_dataio, TDO_bypass; 
wire  EN_ctrl, EN_jtrace, EN_mtrace, EN_dataio;
wire  ST_CAPTURE_DATA, ST_SHIFT_DATA, ST_UPDATE_DATA, ST_UPDATE_INST; 
wire  sync_update, pulse_update;

wire [31:0] cpu_data;
wire [2:0] controls;
wire  run_mode = ~controls[1];

vji   virtual_jtag (  .tck    ( TCK                ),
                      .tdo    ( TDO                ),
                      .tdi    ( TDI                ),
                      .ir_out ( INST_READOUT       ),
                      .ir_in  ( INST               ),

                      .virtual_state_cdr  ( ST_CAPTURE_DATA  ),
                      .virtual_state_sdr  ( ST_SHIFT_DATA    ),
                      .virtual_state_udr  ( ST_UPDATE_DATA   ),
                      .virtual_state_uir  ( ST_UPDATE_INST   ));

inst_decoder decode(  .TCK       ( TCK            ),
                      .UPDATE    ( ST_UPDATE_INST ),
                      .IN        ( INST           ),
                      .EN_ctrl   ( EN_ctrl        ),
                      .EN_jtrace ( EN_jtrace      ),
                      .EN_mtrace ( EN_mtrace      ),
                      .EN_dataio ( EN_dataio      ));
                  
bypass_chain bypass (TCK, TDI, TDO_bypass);

scan_chain #(3)  ctrl_chain(  .TCK     ( TCK                ),
                              .TDI     ( TDI                ),
                              .TDO     ( TDO_ctrl           ),
                              .EN      ( EN_ctrl            ),
                              .CAPTURE ( ST_CAPTURE_DATA    ),
                              .SHIFT   ( ST_SHIFT_DATA      ),
                              .UPDATE  ( ST_UPDATE_DATA     ),
                              .IN      ( controls           ), 
                              .OUT     ( controls           ));


scan_chain #(32) jtag_trace(  .TCK     ( TCK                ),
                              .TDI     ( TDI                ),
                              .TDO     ( TDO_jtrace         ),
                              .EN      ( EN_jtrace          ),
                              .CAPTURE ( ST_CAPTURE_DATA    ),
                              .SHIFT   ( ST_SHIFT_DATA      ),
                              .UPDATE  ( ST_UPDATE_DATA     ),
                              .IN      ( {INST_ADDR, 2'b00} ), 
                              .OUT     ( DEBUG_INST         ));

read_chain #(64)  mem_trace(  .TCK     ( TCK                ),
                              .TDI     ( TDI                ),
                              .TDO     ( TDO_mtrace         ),
                              .EN      ( EN_mtrace          ),
                              .CAPTURE ( ST_CAPTURE_DATA    ),
                              .SHIFT   ( ST_SHIFT_DATA      ),
                              .IN      ( { INST_ADDR,
                                           2'b00,
                                           MEM_INST}        ));


scan_chain #(32)    data_io(  .TCK     ( TCK                ),
                              .TDI     ( TDI                ),
                              .TDO     ( TDO_dataio         ),
                              .EN      ( EN_dataio          ),
                              .CAPTURE ( ST_CAPTURE_DATA    ),
                              .SHIFT   ( ST_SHIFT_DATA      ),
                              .UPDATE  ( ST_UPDATE_DATA     ),
                              .IN      ( cpu_data           ), 
                              .OUT     ( RD                 ));

ffd #(32) cpu_data_reg(CPU_CLK, 1'b0, WE, WD, cpu_data); 

sync  sync_resetm(CPU_CLK, controls[2], RESET ); 
sync  sync_instsm(CPU_CLK, controls[0], I_SOURCE );
sync sync_updatem(CPU_CLK, ST_UPDATE_DATA, sync_update ); 

edetect pulsem(CPU_CLK, sync_update, pulse_update );      // detect update posedge

assign TDO = EN_ctrl   ? TDO_ctrl   :
             EN_jtrace ? TDO_jtrace :
             EN_mtrace ? TDO_mtrace :
             EN_dataio ? TDO_dataio :
                         TDO_bypass;

assign RUN = run_mode | (pulse_update & (EN_mtrace | EN_jtrace));

endmodule
//=========================================================================//
module inst_decoder (  input       TCK,
                       input       UPDATE,
                       input [2:0] IN,
                       
                       output      EN_ctrl,
                       output      EN_jtrace,
                       output      EN_mtrace,
                       output      EN_dataio );

reg [2:0] inst_reg = 3'b000;

always_ff @(posedge TCK)
   if(UPDATE) inst_reg <= IN;

assign EN_ctrl    = (inst_reg == 3'd1);
assign EN_jtrace  = (inst_reg == 3'd2);
assign EN_mtrace  = (inst_reg == 3'd3);
assign EN_dataio  = (inst_reg == 3'd4);

endmodule


//=========================================================================//
module bypass_chain ( input      TCK,
                      input      TDI,
                      output reg TDO );

always_ff @(posedge TCK)
   TDO <= TDI;
endmodule


//=========================================================================//
module scan_chain #(parameter SIZE = 8) ( input TCK,
                                          input TDI,
                                          output TDO,
                           
                                          input EN,
                                          input CAPTURE,
                                          input SHIFT,
                                          input UPDATE,
                           
                                          input  [SIZE-1:0] IN,
                                          output [SIZE-1:0] OUT );

logic [SIZE-1:0] sreg, oreg;

always_ff @(posedge TCK)
   if(EN)
      begin
      if(CAPTURE)    sreg <= IN;
      else if(SHIFT) sreg <= { TDI, sreg[SIZE-1:1]};
      end

always_ff @(posedge UPDATE)
   if(EN) oreg <= sreg;

assign OUT = oreg;
assign TDO = sreg[0];

endmodule
//=========================================================================//
module read_chain #(parameter SIZE = 8) ( input            TCK,
                                          input            TDI,
                                          output           TDO,
                                       
                                          input            EN,
                                          input            CAPTURE,
                                          input            SHIFT,
                                       
                                          input [SIZE-1:0] IN );

logic [SIZE-1:0] sreg;

always_ff @(posedge TCK)
   if(EN)
      begin
      if(CAPTURE)    sreg <= IN;
      else if(SHIFT) sreg <= {TDI, sreg[SIZE-1:1]};
      end

assign TDO = sreg[0];

endmodule
//=========================================================================//
