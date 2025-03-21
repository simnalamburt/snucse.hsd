`timescale 1 ns / 1 ps

module myip_v1_0_S00_AXI #(
    // NOTE: Users to add parameters here
    parameter integer BRAM_ADDR_WIDTH = 32,
    parameter integer BRAM_DATA_WIDTH = 32,
    parameter integer BRAM_WE_WIDTH = 4,
    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // NOTE: Users to add ports here
    output wire [BRAM_ADDR_WIDTH-1:0] BRAM_ADDR,
    output wire BRAM_CLK,
    output wire [BRAM_DATA_WIDTH-1:0] BRAM_WRDATA,
    input wire [BRAM_DATA_WIDTH-1:0] BRAM_RDDATA,
    output wire BRAM_EN,
    output wire BRAM_RST,
    output wire [BRAM_WE_WIDTH-1:0] BRAM_WE,
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2:0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave)
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1:0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2:0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1:0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire S_AXI_RREADY
);
    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1:0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0] axi_rresp;
    reg axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 4
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;

    // I/O Connections assignments

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;
    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_awready <= 1'b0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
                // slave is ready to accept write address when
                // there is a valid write address and write data
                // on the write address and data bus. This design
                // expects no outstanding transactions.
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    // This process is used to latch the address when both
    // S_AXI_AWVALID and S_AXI_WVALID are valid.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
                // Write Address latching
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is
    // de-asserted when reset is low.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID) begin
                // slave is ready to accept write data when
                // there is a valid write address and write data
                // on the write address and data bus. This design
                // expects no outstanding transactions.
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    wire run_complete;

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 || run_complete) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
                    2'h0: begin
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                // Respective byte enables are asserted as per write strobes
                                // Slave register 0
                                slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                        end
                    end
                    2'h1: begin
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                // Respective byte enables are asserted as per write strobes
                                // Slave register 1
                                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                        end
                    end
                    2'h2: begin
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                // Respective byte enables are asserted as per write strobes
                                // Slave register 2
                                slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                        end
                    end
                    2'h3: begin
                        for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
                            if ( S_AXI_WSTRB[byte_index] == 1 ) begin
                                // Respective byte enables are asserted as per write strobes
                                // Slave register 3
                                slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                            end
                        end
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.
    // This marks the acceptance of address and indicates the status of
    // write transaction.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_bvalid <= 0;
            axi_bresp <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b0; // 'OKAY' response
                // work error responses in future
            end else begin
                // check if bready is asserted while bvalid is high)
                // (there is a possibility that bready is always asserted high)
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is
    // de-asserted when reset (active low) is asserted.
    // The read address is also latched when S_AXI_ARVALID is
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_arready <= 1'b0;
            axi_araddr <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1'b1;
                // Read address latching
                axi_araddr <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers
    // data are available on the axi_rdata bus at this instance. The
    // assertion of axi_rvalid marks the validity of read data on the
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid
    // is deasserted on reset (active low). axi_rresp and axi_rdata are
    // cleared to zero on reset (active low).
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_rvalid <= 0;
            axi_rresp <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                // Valid read data is available at the read data bus
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b0; // 'OKAY' response
            end else if (axi_rvalid && S_AXI_RREADY) begin
                // Read data is accepted by the master
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        // Address decoding for reading registers
        case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
            2'h0: reg_data_out <= slv_reg0;
            2'h1: reg_data_out <= slv_reg1;
            2'h2: reg_data_out <= slv_reg2;
            2'h3: reg_data_out <= slv_reg3;
            default: reg_data_out <= 0;
        endcase
    end

    // Output register or memory read data
    always @( posedge S_AXI_ACLK ) begin
        if ( S_AXI_ARESETN == 1'b0 ) begin
            axi_rdata <= 0;
        end else begin
            // When there is a valid read address (S_AXI_ARVALID) with
            // acceptance of read address by the slave (axi_arready),
            // output the read dada
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out; // register read data
            end
        end
    end



    //
    // User logic
    //
    localparam LOG2_DIM = 6;
    localparam DIM = 1<<LOG2_DIM;
    localparam ZERO_CTR = {(LOG2_DIM*2+1){1'b0}};

    //
    // Inputs
    //
    wire start = slv_reg0 == 32'h00005555;

    //
    // FSM
    //
    // TODO: S_LOAD_V, S_READ_M 사이의 사이클 낭비 줄이기
    localparam S_IDLE       = 3'd0;
    localparam S_LOAD_V     = 3'd1;
    localparam S_READ_M     = 3'd2;
    localparam S_STORE      = 3'd3;
    localparam S_DONE       = 3'd4;

    reg [2:0] state;
    // TODO: counter가 필요한것보다 큰 비트를 갖고있음
    reg [LOG2_DIM*2:0] counter;

    wire [LOG2_DIM*2 + 3:0] next_ = next(state, counter, S_AXI_ARESETN, start);
    wire [2:0] next_state = next_[2:0];
    wire [LOG2_DIM*2:0] next_counter = next_[LOG2_DIM*2 + 3:3];

    function [LOG2_DIM*2 + 3:0] next(
        input [2:0] state,
        input [LOG2_DIM*2:0] counter,
        input S_AXI_ARESETN, start
    );
        if ( S_AXI_ARESETN == 1'b0 ) begin
            next = {ZERO_CTR, S_IDLE};
        end else begin
            case (state)
                S_IDLE: begin
                    if (!start) begin
                        next = {ZERO_CTR, S_IDLE};
                    end else begin
                        next = {ZERO_CTR, S_LOAD_V};
                    end
                end
                S_LOAD_V: begin
                    if (counter < DIM/4 + 2 - 1) begin
                        next = {counter + 1, S_LOAD_V};
                    end else begin
                        next = {ZERO_CTR, S_READ_M};
                    end
                end
                S_READ_M: begin
                    if (counter < DIM*DIM/4 + 2 - 1) begin
                        next = {counter + 1, S_READ_M};
                    end else begin
                        next = {ZERO_CTR, S_STORE};
                    end
                end
                S_STORE: begin
                    if (counter < DIM/2 - 1) begin
                        next = {counter + 1, S_STORE};
                    end else begin
                        next = {ZERO_CTR, S_DONE};
                    end
                end
                S_DONE: begin
                    next = {ZERO_CTR, S_IDLE};
                end
                default: begin
                    // Invalid state
                    next = {ZERO_CTR, S_IDLE};
                end
            endcase
        end
    endfunction

    //
    // Clock Wizard, filters clock
    //
    clk_wiz_0 u_clk (.clk_out1(BRAM_CLK), .clk_in1(S_AXI_ACLK));

    //
    // Memory
    //
    reg signed [7:0] vector[0:DIM - 1];
    reg signed [15:0] result[0:DIM - 1];

    //
    // Outputs
    //
    reg bram_en;
    reg [BRAM_WE_WIDTH-1:0] bram_we;
    reg [BRAM_ADDR_WIDTH-1:0] bram_addr, bram_wrdata;
    assign run_complete = state == S_DONE;
    assign BRAM_EN = bram_en;
    assign BRAM_RST = 1'b0;
    assign BRAM_WE = bram_we;
    assign BRAM_ADDR = bram_addr;
    assign BRAM_WRDATA = bram_wrdata;

    // Arithmetic operation helper
    reg [LOG2_DIM*2:0] read_addr;
    reg [LOG2_DIM-1:0] read_col, read_row;
    reg signed [7:0] t0, t1, t2, t3;

    //
    // At rising edge
    //
    always @(posedge S_AXI_ACLK) begin
        // Advance state
        state = next_state;
        counter = next_counter;

        bram_en = 0;
        bram_we = 4'b0000;
        bram_addr = 0;
        bram_wrdata = 0;
        case (state)
            S_LOAD_V: begin
                if (counter < DIM/4) begin
                    // Read vector
                    bram_en = 1;
                    bram_addr = counter*4;
                end
                if (counter >= 2) begin
                    // Delayed vector read result

                    // Setup variables
                    read_addr = (counter - 2) << 2;

                    // Store vector
                    vector[read_addr + 0] = BRAM_RDDATA[ 7: 0];
                    vector[read_addr + 1] = BRAM_RDDATA[15: 8];
                    vector[read_addr + 2] = BRAM_RDDATA[23:16];
                    vector[read_addr + 3] = BRAM_RDDATA[31:24];
                    // Initialize result array
                    result[read_addr + 0] = 0;
                    result[read_addr + 1] = 0;
                    result[read_addr + 2] = 0;
                    result[read_addr + 3] = 0;
                end
            end
            S_READ_M: begin
                if (counter < DIM*DIM/4) begin
                    // Read matrix
                    bram_en = 1;
                    bram_addr = DIM + counter*4;
                end
                if (counter >= 2) begin
                    // Delayed matrix read result

                    // Setup variables
                    read_addr = (counter - 2) << 2;
                    read_col = read_addr[LOG2_DIM-1:0];
                    read_row = read_addr[LOG2_DIM*2-1:LOG2_DIM];
                    t0 = BRAM_RDDATA[ 7: 0];
                    t1 = BRAM_RDDATA[15: 8];
                    t2 = BRAM_RDDATA[23:16];
                    t3 = BRAM_RDDATA[31:24];

                    // Signed 8bit int multiply-accumulate
                    result[read_row] = result[read_row] +
                        vector[read_col + 0] * t0 +
                        vector[read_col + 1] * t1 +
                        vector[read_col + 2] * t2 +
                        vector[read_col + 3] * t3;
                end
            end
            S_STORE: begin
                // Store the calculation output
                // `BRAM_WE` is 4'b1111 in here
                bram_en = 1;
                bram_we = 4'b1111;
                bram_addr = counter << 2;
                bram_wrdata = {result[2*counter + 1], result[2*counter]};
            end
        endcase
    end
endmodule
