

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This module is a auto-matic switch to map multile AXIS input streams to a single output stream
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//===================================================================================================
//                            ------->  Revision History  <------
//===================================================================================================
//
//   Date     Who   Ver  Changes
//===================================================================================================
// 12-Dec-22  DWW  1000  Initial creation
//===================================================================================================


module axis_switch #
(
    parameter DATA_WIDTH  = 512
) 
(
    input clk, resetn,

    //========================  AXI Stream interface for the input side  ============================
    input[DATA_WIDTH-1:0]   AXIS_IN1_TDATA,
    input                   AXIS_IN1_TVALID,
    output                  AXIS_IN1_TREADY,
    //===============================================================================================

    //========================  AXI Stream interface for the input side  ============================
    input[DATA_WIDTH-1:0]   AXIS_IN2_TDATA,
    input                   AXIS_IN2_TVALID,
    output                  AXIS_IN2_TREADY,
    //===============================================================================================


    //========================  AXI Stream interface for the output side  ===========================
    output[DATA_WIDTH-1:0]  AXIS_OUT_TDATA,
    output                  AXIS_OUT_TVALID,
    input                   AXIS_OUT_TREADY
    //===============================================================================================
);

reg[1:0] selector;
reg[1:0] fsm_state;
reg[15:0] counter;

assign AXIS_OUT_TDATA  = (selector == 1  ) ? AXIS_IN1_TDATA :
                         (selector == 2  ) ? AXIS_IN2_TDATA :
                         (AXIS_IN1_TVALID) ? AXIS_IN1_TDATA :
                         (AXIS_IN2_TVALID) ? AXIS_IN2_TDATA :
                         0;

assign AXIS_OUT_TVALID = (selector == 1)   ? AXIS_IN1_TVALID :
                         (selector == 2)   ? AXIS_IN2_TVALID :
                         (AXIS_IN1_TVALID) ? 1 :
                         (AXIS_IN2_TVALID) ? 1 :
                         0;

assign AXIS_IN1_TREADY = (selector == 1) ? AXIS_OUT_TREADY : 0;
assign AXIS_IN2_TREADY = (selector == 2) ? AXIS_OUT_TREADY : 0;

always @(posedge clk) begin
    if (resetn == 0) begin
        selector  <= 0;
        fsm_state <= 0;
    end else case (fsm_state)

    0:  if (AXIS_IN1_TVALID) begin
            selector  <= 1;
            fsm_state <= 1;
            counter   <= 0;
        end else if (AXIS_IN2_TVALID) begin
            selector  <= 2;
            fsm_state <= 1;
            counter   <= 0;
        end


    1:  if (AXIS_OUT_TVALID == 0) begin
            if (counter == 1024) begin
                fsm_state <= 0;
                selector  <= 0;
            end
            counter <= counter + 1;
        end else counter <= 0;
    
    endcase

end

endmodule
