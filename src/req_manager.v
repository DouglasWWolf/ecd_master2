
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// This module reads data requests, and transmits the correspond row of data
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//===================================================================================================
//                            ------->  Revision History  <------
//===================================================================================================
//
//   Date     Who   Ver  Changes
//===================================================================================================
// 06-Oct-22  DWW  1000  Initial creation
//===================================================================================================

module req_manager
(
    input clk, resetn,

    //==========================  AXI Stream interface for request input  ===========================
    input[31:0]         AXIS_RQ_TDATA,
    input               AXIS_RQ_TVALID,
    output              AXIS_RQ_TREADY,
    //===============================================================================================


    //==========================  AXI Stream interface for data input  ==============================
    input[511:0]        AXIS_RX_TDATA,
    input               AXIS_RX_TVALID,
    output reg          AXIS_RX_TREADY,
    //===============================================================================================


    //========================  AXI Stream interface for data_output  ===============================
    output reg[511:0]  AXIS_TX_TDATA,
    output reg         AXIS_TX_TVALID,
    input              AXIS_TX_TREADY
    //===============================================================================================

);

// This is how many beats of the RX data stream are in a single outgoing packet
localparam RX_BEATS_PER_PACKET = 32;

// Define the AXIS handshake for each stream
wire RQ_HANDSHAKE = AXIS_RQ_TVALID & AXIS_RQ_TREADY;
wire TX_HANDSHAKE = AXIS_TX_TVALID & AXIS_TX_TREADY;
wire RX_HANDSHAKE = AXIS_RX_TVALID & AXIS_RX_TREADY;


//===================================================================================================
// State machine that allows incoming data-requests to flow in
//===================================================================================================

// This will be driven high for one cycle when we're ready for a new data-request to arrive
reg get_new_rq;

// The most recently arrived data-request
reg[31:0] rq_data;

// This is '1' if rq_data holds a valid data-request
reg rq_data_valid;

// AXIS_RQ_TREADY stays high as long as this is high
reg axis_rq_tready;      

// AXIS_RQ_TREADY goes high as soon as get_new_rq goes high
assign AXIS_RQ_TREADY = (resetn == 1) && (get_new_rq || axis_rq_tready);

//===================================================================================================
always @(posedge clk) begin
   
    // If we're in reset, by definition rq_data isn't valid.
    // When we come out of reset, we want to instantly drive AXIS_RQ_TREADY 
    // high so that a data-request flows in as soon as one is available
    if (resetn == 0) begin
        rq_data_valid  <= 0;
        axis_rq_tready <= 1;
    end else begin

        // If the other state machine asked for a new data-request, AXIS_RQ_TREADY is 
        // already high.   Here we keep track of the fact that we want it to stay high
        // and we declare that the rq_data register no longer holds a valid data-request.
        if (get_new_rq) begin
            axis_rq_tready <= 1;
            rq_data_valid  <= 0;
        end

        // If a new data-request has arrived...
        if (RQ_HANDSHAKE) begin
            
            // Lower the AXIS_RQ_TREADY signal
            axis_rq_tready <= 0;
            
            // Store the data-request that just arrived
            rq_data <= AXIS_RQ_TDATA;

            // And indicate that rq_data holds a valid data-request
            rq_data_valid  <= 1;
        end
    end

end
//===================================================================================================




//===================================================================================================
// flow state machine: main state machine that waits for a data-request to arrive, then transmits
// a 1 cycle packet header, 32 cycles of packet data, and 1 cycle of packet footer
//===================================================================================================
reg[2:0]   fsm_state;
reg[31:0]  req_id;
reg[7:0]   beat_countdown;
//===================================================================================================

localparam FSM_WAIT_FOR_REQ    = 0;
localparam FSM_SEND_DATA       = 1;
localparam FSM_EMIT_FOOTER     = 2;
localparam FSM_WAIT_FOR_FINISH = 3;

always @(posedge clk) begin
    
    // These signals strobe high for only a single cycle
    get_new_rq <= 0;
    
    if (resetn == 0) begin
        AXIS_TX_TVALID <= 0;
        AXIS_RX_TREADY <= 0;
        fsm_state      <= FSM_WAIT_FOR_REQ;
    end else case(fsm_state)


    FSM_WAIT_FOR_REQ:

        // If a new request has arrived...
        if (rq_data_valid) begin
            
            // Keep track of the data-request ID for future use
            req_id <= rq_data;

            // Emit a packet-header which consists of the data-request ID
            AXIS_TX_TDATA <= rq_data;

            // We have valid data on the TX data bus
            AXIS_TX_TVALID <= 1;

            // We're ready to receive data that data that should be transmitted
            AXIS_RX_TREADY <= 1;

            // Allow another data-request to get buffered up
            get_new_rq <= 1;

            // This is how many beats of RX data we have left to send
            beat_countdown <= RX_BEATS_PER_PACKET;

            // And go to the next state
            fsm_state <= FSM_SEND_DATA;
        end
        

    
    FSM_SEND_DATA:
        if (AXIS_RX_TVALID) begin
            AXIS_TX_TDATA  <= AXIS_RX_TDATA;
            AXIS_TX_TVALID <= 1;
            if (beat_countdown == 1) begin
                AXIS_RX_TREADY <= 0;
                fsm_state      <= FSM_EMIT_FOOTER;
            end
            beat_countdown <= beat_countdown - 1;
        end else begin
            AXIS_TX_TVALID <= 0;
        end
        


    FSM_EMIT_FOOTER:

        // Our last data-beat has finished transmitting, so place a packet
        // footer on the TX data-bus and go wait for it to be accepted
        begin
            AXIS_TX_TDATA <= req_id;
            fsm_state     <= FSM_WAIT_FOR_FINISH;
        end

    FSM_WAIT_FOR_FINISH:

        // If the packet footer was accepted...
        if (AXIS_TX_TREADY) begin

            // If we have another data-request pending...
            if (rq_data_valid) begin
                  
                // Keep track of the data-request ID for future use
                req_id <= rq_data;

                // Emit a packet-header which consists of the data-request ID
                AXIS_TX_TDATA <= rq_data;

                // The TX_TDATA bus is valid (it contains the request-ID)
                AXIS_TX_TVALID <= 1;

                // We're ready to receive data to be retransmitted
                AXIS_RX_TREADY <= 1;

                // Allow another data-request to get buffered up
                get_new_rq <= 1;

                // This is how many beats of RX data we have left to send
                beat_countdown <= RX_BEATS_PER_PACKET;


                // Go start emitting packet data
                fsm_state <= FSM_SEND_DATA;

            end

            // Otherwise, we no longer have valid data on the TX data-bus
            // and we need to go wait for a request to arrive
            else begin
                AXIS_TX_TVALID <= 0;
                fsm_state      <= FSM_WAIT_FOR_REQ;
            end
        end

    endcase

end
//===================================================================================================


endmodule


