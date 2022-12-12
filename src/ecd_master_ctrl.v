`timescale 1ns / 1ps

//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 04-Oct-22  DWW  1000  Initial creation
//====================================================================================

`define AXIS_DATA_WIDTH  512
`define M_AXI_DATA_WIDTH 512
`define M_AXI_ADDR_WIDTH 64

module ecd_master_ctrl
(
    input clk, resetn,

    // Interrupt request signals for the ping-pong buffers
    output IRQ_PPB0, IRQ_PPB1,

    // This is high when data is being received from the PCI bridge and thrown away
    output DRAINING,

    //================== This is an AXI4-Lite slave interface ==================
        
    // "Specify write address"              -- Master --    -- Slave --
    input[31:0]                             S_AXI_AWADDR,   
    input                                   S_AXI_AWVALID,  
    output                                                  S_AXI_AWREADY,
    input[2:0]                              S_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    input[31:0]                             S_AXI_WDATA,      
    input                                   S_AXI_WVALID,
    input[3:0]                              S_AXI_WSTRB,
    output                                                  S_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    output[1:0]                                             S_AXI_BRESP,
    output                                                  S_AXI_BVALID,
    input                                   S_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    input[31:0]                             S_AXI_ARADDR,     
    input                                   S_AXI_ARVALID,
    input[2:0]                              S_AXI_ARPROT,     
    output                                                  S_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    output[31:0]                                            S_AXI_RDATA,
    output                                                  S_AXI_RVALID,
    output[1:0]                                             S_AXI_RRESP,
    input                                   S_AXI_RREADY,
    //==========================================================================





    //===============  AXI Stream interface for outputting data ================
    output[`AXIS_DATA_WIDTH-1:0] AXIS_TX_TDATA,
    output                       AXIS_TX_TVALID,
    input                        AXIS_TX_TREADY,
    //==========================================================================





    //======================  An AXI Master Interface  =========================

    // "Specify write address"         -- Master --    -- Slave --
    output[`M_AXI_ADDR_WIDTH-1:0]      M_AXI_AWADDR,
    output                             M_AXI_AWVALID,
    output[2:0]                        M_AXI_AWPROT,
    output[3:0]                        M_AXI_AWID,
    output[7:0]                        M_AXI_AWLEN,
    output[2:0]                        M_AXI_AWSIZE,
    output[1:0]                        M_AXI_AWBURST,
    output                             M_AXI_AWLOCK,
    output[3:0]                        M_AXI_AWCACHE,
    output[3:0]                        M_AXI_AWQOS,
    input                                              M_AXI_AWREADY,


    // "Write Data"                    -- Master --    -- Slave --
    output[`M_AXI_DATA_WIDTH-1:0]      M_AXI_WDATA,
    output                             M_AXI_WVALID,
    output[(`M_AXI_DATA_WIDTH/8)-1:0]  M_AXI_WSTRB,
    output                             M_AXI_WLAST,
    input                                              M_AXI_WREADY,


    // "Send Write Response"           -- Master --    -- Slave --
    input [1:0]                                        M_AXI_BRESP,
    input                                              M_AXI_BVALID,
    output                             M_AXI_BREADY,

    // "Specify read address"          -- Master --    -- Slave --
    output reg[`M_AXI_ADDR_WIDTH-1:0]  M_AXI_ARADDR,
    output reg                         M_AXI_ARVALID,
    output[2:0]                        M_AXI_ARPROT,
    output                             M_AXI_ARLOCK,
    output[3:0]                        M_AXI_ARID,
    output[7:0]                        M_AXI_ARLEN,
    output[2:0]                        M_AXI_ARSIZE,
    output[1:0]                        M_AXI_ARBURST,
    output[3:0]                        M_AXI_ARCACHE,
    output[3:0]                        M_AXI_ARQOS,
    input                                              M_AXI_ARREADY,

    // "Read data back to master"      -- Master --    -- Slave --
    input[`M_AXI_DATA_WIDTH-1:0]                       M_AXI_RDATA,
    input                                              M_AXI_RVALID,
    input[1:0]                                         M_AXI_RRESP,
    input                                              M_AXI_RLAST,
    output                             M_AXI_RREADY
    //==========================================================================

 );

    // Some convenience declarations
    localparam M_AXI_ADDR_WIDTH = `M_AXI_ADDR_WIDTH;
    localparam M_AXI_DATA_WIDTH = `M_AXI_DATA_WIDTH;
    localparam M_AXI_DATA_BYTES = M_AXI_DATA_WIDTH / 8;

    //==========================================================================
    // We'll communicate with the AXI4-Lite Slave core with these signals.
    //==========================================================================
    // AXI Slave Handler Interface for write requests
    wire[31:0]  ashi_waddr;     // Input:  Write-address
    wire[31:0]  ashi_wdata;     // Input:  Write-data
    wire        ashi_write;     // Input:  1 = Handle a write request
    reg[1:0]    ashi_wresp;     // Output: Write-response (OKAY, DECERR, SLVERR)
    wire        ashi_widle;     // Output: 1 = Write state machine is idle

    // AXI Slave Handler Interface for read requests
    wire[31:0]  ashi_raddr;     // Input:  Read-address
    wire        ashi_read;      // Input:  1 = Handle a read request
    reg[31:0]   ashi_rdata;     // Output: Read data
    reg[1:0]    ashi_rresp;     // Output: Read-response (OKAY, DECERR, SLVERR);
    wire        ashi_ridle;     // Output: 1 = Read state machine is idle
    //==========================================================================

    // The state of our two state machines
    reg[2:0] ctrl_read_state, ctrl_write_state;

    // The state machines are idle when they're in state 0 and their "start" signals are low
    assign ashi_widle = (ashi_write == 0) && (ctrl_write_state == 0);
    assign ashi_ridle = (ashi_read  == 0) && (ctrl_read_state  == 0);

    // Data storage for the AXI registers
    reg[31:0] axi_register[0:4];

    // Some convenient human readable names for the AXI registers
    localparam REG_PPB0H    = 0;   // Ping Pong Buffer #0, hi 32-bits
    localparam REG_PPB0L    = 1;   // Ping Pong Buffer #0, lo 32-bits
    localparam REG_PPB1H    = 2;   // Ping Pong Buffer #1, hi 32-bits
    localparam REG_PPB1L    = 3;   // Ping Pong Buffer #1, lo 32-bits
    localparam REG_PPB_SIZE = 4;   // Ping Pong buffer size in 2048-byte blocks
    localparam REG_START    = 10;  // A write to this register starts data transfer
    localparam REG_PPB_RDY  = 11;  // Used to signal that a PPB has been loaded with data
    
    // These are the valid values for ashi_rresp and ashi_wresp
    localparam OKAY   = 0;
    localparam SLVERR = 2;
    localparam DECERR = 3;
   

    // An AXI slave is gauranteed a minimum of 128 bytes of address space
    // (128 bytes is 32 32-bit registers)
    localparam ADDR_MASK = 7'h7F;

    // Every burst transfer will fetch us 32 AXI beats of data
    localparam BEATS_PER_BURST = 32;

    // This is the number of bytes fetched in a single burst read
    localparam BYTES_PER_BURST = M_AXI_DATA_BYTES * BEATS_PER_BURST;

    // This will strobe to 1 when it's time to start fetching data from the master interface
    reg start_fetching_data;

    // Bit flags that say whether a particular ping-pong buffer has data in it
    reg[1:0] ppb_ready;

    // When either of these bits goes high, the corresponding bit in ppb_ready goes high
    reg[1:0] signal_ppb_ready;

    // This is the state of the state machine that places read requests onto the AR channel
    reg[3:0] fsm_state;

    // This will be high when we are waiting to be told to start performing AXI reads 
    wire fsm_idle = (fsm_state == 0);

    // For debugging only: this goes high when data DMA'd from the PCI bridge is being thrown away
    assign DRAINING = fsm_idle & M_AXI_RVALID & M_AXI_RREADY;

    // Burst parameters never change.  Burst type is INCR
    assign M_AXI_ARSIZE  = $clog2(M_AXI_DATA_BYTES);
    assign M_AXI_ARLEN   = BEATS_PER_BURST - 1;
    assign M_AXI_ARBURST = 1;

    // The AXI-Stream output is driven directly from the AXI Master interface    
    assign AXIS_TX_TVALID = M_AXI_RVALID & ~fsm_idle;
    
    // We're ready to receive data from the PCI bus if the FIFO is ready for data or
    // if we're idle.   If we're idle, the data is just thrown away
    assign M_AXI_RREADY = AXIS_TX_TREADY | fsm_idle;

    // We drive AXIS_TX_TDATA directly from M_AXI_RDATA, but we need to put the bytes
    // back in their original order (The PCI bridge delivers them to us in little-endian)
    genvar x;
    for (x=0; x<64; x=x+1) assign AXIS_TX_TDATA[x*8+7:x*8] = M_AXI_RDATA[(63-x)*8+7:(63-x)*8];
    
    // The interrupt request lines to signal when a ping-pong buffer is empty
    reg[1:0] irq_ppb;
    assign IRQ_PPB0 = irq_ppb[0];
    assign IRQ_PPB1 = irq_ppb[1];

    //==========================================================================
    // World's simplest state machine for handling write requests
    //==========================================================================
    always @(posedge clk) begin

        // When these goes high, they only stay high for once cycle
        start_fetching_data <= 0;
        signal_ppb_ready    <= 0;

        // If we're in reset, initialize important registers
        if (resetn == 0) begin
            ctrl_write_state <= 0;
            axi_register[REG_PPB0H   ] <= 0;
            axi_register[REG_PPB0L   ] <= 32'hC000_0000;
            axi_register[REG_PPB1H   ] <= 0;
            axi_register[REG_PPB1L   ] <= 32'hC001_0000;
            axi_register[REG_PPB_SIZE] <= 8;


        // If we're not in reset, and a write-request has occured...        
        end else if (ashi_write) begin
       
            // Assume for the moment that the result will be OKAY
            ashi_wresp <= OKAY;              
            
            // Convert the byte address into a register index
            case ((ashi_waddr & ADDR_MASK) >> 2)
                
                // Allow a write to any valid register
                REG_PPB0H:    axi_register[REG_PPB0H   ] <= ashi_wdata;
                REG_PPB0L:    axi_register[REG_PPB0L   ] <= ashi_wdata;
                REG_PPB1H:    axi_register[REG_PPB1H   ] <= ashi_wdata;
                REG_PPB1L:    axi_register[REG_PPB1L   ] <= ashi_wdata;
                REG_PPB_SIZE: axi_register[REG_PPB_SIZE] <= ashi_wdata;
                REG_START:    start_fetching_data        <= 1;
                REG_PPB_RDY:  begin
                                if (ashi_wdata[0]) signal_ppb_ready[0] <= 1;
                                if (ashi_wdata[1]) signal_ppb_ready[1] <= 1;
                              end
                
                // Writes to any other register are a decode-error
                default: ashi_wresp <= DECERR;
            endcase
        end
    end
    //==========================================================================



    //==========================================================================
    // World's simplest state machine for handling read requests
    //==========================================================================
    always @(posedge clk) begin

        // If we're in reset, initialize important registers
        if (resetn == 0) begin
            ctrl_read_state <= 0;
        
        // If we're not in reset, and a read-request has occured...        
        end else if (ashi_read) begin
       
            // Assume for the moment that the result will be OKAY
            ashi_rresp <= OKAY;              
            
            // Convert the byte address into a register index
            case ((ashi_raddr & ADDR_MASK) >> 2)

                // Allow a read from any valid register                
                REG_PPB0H:    ashi_rdata <= axi_register[REG_PPB0H   ];
                REG_PPB0L:    ashi_rdata <= axi_register[REG_PPB0L   ];
                REG_PPB1H:    ashi_rdata <= axi_register[REG_PPB1H   ];
                REG_PPB1L:    ashi_rdata <= axi_register[REG_PPB1L   ];
                REG_PPB_SIZE: ashi_rdata <= axi_register[REG_PPB_SIZE];
                REG_PPB_RDY:  ashi_rdata <= {30'h0, ppb_ready};

                // Reads of any other register are a decode-error
                default: ashi_rresp <= DECERR;
            endcase
        end
    end
    //==========================================================================



    //==========================================================================
    // This state machine places read-requests on the AR channel of the AXI
    // Master bus
    //==========================================================================
    reg       ppb_index;
    reg[31:0] blocks_remaining;
    //==========================================================================

    always @(posedge clk) begin


        // Watch for the signals that tell us that a ping-pong buffer has been loaded with data
        if (signal_ppb_ready[0]) ppb_ready[0] <= 1;
        if (signal_ppb_ready[1]) ppb_ready[1] <= 1;

        if (resetn == 0) begin
            fsm_state     <= 0;
            M_AXI_ARVALID <= 0;
        end 

        else case(fsm_state)

        // Here we're idle, waiting to be told to start fetching data
        0:  if (start_fetching_data) begin
                ppb_ready <= -1;
                ppb_index <= 0;
                fsm_state <= 1;
            end

        // If this ping-pong buffer is loaded with data...
        1:  if (ppb_ready[ppb_index]) begin
                
                // Determine the starting PCI address of this buffer 
                if (ppb_index == 0)
                    M_AXI_ARADDR <= {axi_register[REG_PPB0H], axi_register[REG_PPB0L]};
                else
                    M_AXI_ARADDR <= {axi_register[REG_PPB1H], axi_register[REG_PPB1L]};                
    
                // Fetch the number of blocks remaining to be read-in from this buffer
                blocks_remaining <= axi_register[REG_PPB_SIZE];

                // The AR channel now contains valid data
                M_AXI_ARVALID <= 1;

                // And go to the next state
                fsm_state <= 2;
            end


        // If our read-request was accepted...
        2:  if (M_AXI_ARREADY & M_AXI_ARVALID) begin
                if (blocks_remaining == 1) begin
                    M_AXI_ARVALID        <= 0;
                    ppb_ready[ppb_index] <= 0;
                    ppb_index            <= ~ppb_index;
                    fsm_state            <= 1;
                end else begin
                    M_AXI_ARADDR         <= M_AXI_ARADDR + BYTES_PER_BURST;
                    M_AXI_ARVALID        <= 1;
                    blocks_remaining     <= blocks_remaining - 1;
                end
            end

        endcase

    end
    //==========================================================================


    //==========================================================================
    // This state machine is responsible for raising an interrupt when the
    // last block in a buffer has been received.
    //==========================================================================
    reg [31:0] blocks_remaining_to_read;
    reg        r_buffer_index;
    //==========================================================================
    always @(posedge clk) begin

        // When an interrupt-request line is raised, it should only strobe high for one cycle
        irq_ppb <= 0;

        // If we've just been told that "data fetching" (i.e., DMA transfers) has begun,
        // initialize our variables 
        if (start_fetching_data) begin
            blocks_remaining_to_read <= axi_register[REG_PPB_SIZE];
            r_buffer_index           <= 0;            
        end

        // If we're fetching data, and this is a valid data cycle from the PCI bridge, and 
        // this is the last cycle of a block...
        else if (~fsm_idle & M_AXI_RREADY & M_AXI_RVALID & M_AXI_RLAST) begin
            
            // If this was the last block that was available in this buffer...
            if (blocks_remaining_to_read == 1) begin
                
                // Reload our counter of blocks remaining to be read
                blocks_remaining_to_read <= axi_register[REG_PPB_SIZE];
                
                // Raise the interrupt that says "this buffer is empty"
                irq_ppb[r_buffer_index] <= 1;
                
                // Switch to the other buffer
                r_buffer_index <= ~r_buffer_index;
            end

            // Otherwise, if this was not the last block available in the buffer,
            // just keep track of how many blocks are left in this buffer
            else blocks_remaining_to_read <= blocks_remaining_to_read - 1;
        end
    end
    //==========================================================================



    //==========================================================================
    // This connects us to an AXI4-Lite slave core
    //==========================================================================
    axi4_lite_slave axi_slave
    (
        .clk            (clk),
        .resetn         (resetn),
        
        // AXI AW channel
        .AXI_AWADDR     (S_AXI_AWADDR),
        .AXI_AWVALID    (S_AXI_AWVALID),   
        .AXI_AWPROT     (S_AXI_AWPROT),
        .AXI_AWREADY    (S_AXI_AWREADY),
        
        // AXI W channel
        .AXI_WDATA      (S_AXI_WDATA),
        .AXI_WVALID     (S_AXI_WVALID),
        .AXI_WSTRB      (S_AXI_WSTRB),
        .AXI_WREADY     (S_AXI_WREADY),

        // AXI B channel
        .AXI_BRESP      (S_AXI_BRESP),
        .AXI_BVALID     (S_AXI_BVALID),
        .AXI_BREADY     (S_AXI_BREADY),

        // AXI AR channel
        .AXI_ARADDR     (S_AXI_ARADDR), 
        .AXI_ARVALID    (S_AXI_ARVALID),
        .AXI_ARPROT     (S_AXI_ARPROT),
        .AXI_ARREADY    (S_AXI_ARREADY),

        // AXI R channel
        .AXI_RDATA      (S_AXI_RDATA),
        .AXI_RVALID     (S_AXI_RVALID),
        .AXI_RRESP      (S_AXI_RRESP),
        .AXI_RREADY     (S_AXI_RREADY),

        // ASHI write-request registers
        .ASHI_WADDR     (ashi_waddr),
        .ASHI_WDATA     (ashi_wdata),
        .ASHI_WRITE     (ashi_write),
        .ASHI_WRESP     (ashi_wresp),
        .ASHI_WIDLE     (ashi_widle),

        // AMCI-read registers
        .ASHI_RADDR     (ashi_raddr),
        .ASHI_RDATA     (ashi_rdata),
        .ASHI_READ      (ashi_read ),
        .ASHI_RRESP     (ashi_rresp),
        .ASHI_RIDLE     (ashi_ridle)
    );
    //==========================================================================

endmodule






