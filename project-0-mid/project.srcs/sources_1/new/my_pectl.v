`timescale 1ns / 1ps

// TODO: 실수로 synth되는 latch 없는지 검사하기

module my_pectl #(
    parameter LOG2_DIM = 4
) (
    // On S_IDLE state, start == 1 moves states to S_LOAD
    input start,

    // clock signal
    input aclk,

    // Negetive reset. aresetn == 0 means that reset is activated
    input aresetn,

    // If rdaddr is set, user should input data[rdaddr] as rddata
    output reg [2*LOG2_DIM:0] rdaddr,

    // On S_LOAD state, rddata will be stored into peram and global_bram
    input [31:0] rddata,

    // done == 1 if and only if internal state is S_DONE
    output done
);
    localparam DIM = 1 << LOG2_DIM;
    localparam ZERO_CTR = {(LOG2_DIM*2+1){1'b0}};
    localparam BRAM_ADDR_WIDTH = 32;
    localparam BRAM_DATA_WIDTH = 32;
    localparam BRAM_WE_WIDTH = 4;
    wire S_AXI_ACLK = aclk;
    wire S_AXI_ARESETN = aresetn;
    wire [BRAM_ADDR_WIDTH-1:0] BRAM_ADDR;
    wire BRAM_CLK = aclk;
    wire [BRAM_DATA_WIDTH-1:0] BRAM_WRDATA;
    wire BRAM_EN;
    wire BRAM_RST;
    wire [BRAM_WE_WIDTH-1:0] BRAM_WE;





    //
    // FSM
    //
    localparam S_IDLE       = 3'd0;
    localparam S_LOAD_V     = 3'd1;
    localparam S_LOAD_M     = 3'd2;
    localparam S_CALC_READY = 3'd3;
    localparam S_CALC_WAIT  = 3'd4;
    localparam S_STORE      = 3'd5;
    localparam S_DONE       = 3'd6;

    reg [2:0] state;
    reg [LOG2_DIM*2:0] counter;

    wire [LOG2_DIM*2 + 3:0] next_ = next(state, counter, S_AXI_ARESETN, start, pe_ready);
    wire [2:0] next_state = next_[2:0];
    wire [LOG2_DIM*2:0] next_counter = next_[LOG2_DIM*2 + 3:3];

    function [LOG2_DIM*2 + 3:0] next(
        input [2:0] state,
        input [LOG2_DIM*2:0] counter,
        input S_AXI_ARESETN, start, pe_ready
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
                    if (counter < DIM + 2 - 1) begin
                        next = {counter + 1, S_LOAD_V};
                    end else begin
                        next = {ZERO_CTR, S_LOAD_M};
                    end
                end
                S_LOAD_M: begin
                    if (counter < DIM*DIM + 2 - 1) begin
                        next = {counter + 1, S_LOAD_M};
                    end else begin
                        next = {ZERO_CTR, S_CALC_READY};
                    end
                end
                S_CALC_READY: begin
                    next = {counter, S_CALC_WAIT};
                end
                S_CALC_WAIT: begin
                    if (!pe_ready) begin
                        // Not ready, hold state
                        next = {counter, S_CALC_WAIT};
                    end else if (counter < DIM - 1) begin
                        next = {counter + 1, S_CALC_READY};
                    end else begin
                        next = {ZERO_CTR, S_STORE};
                    end
                end
                S_STORE: begin
                    if (counter < DIM - 1) begin
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
    // PE
    //
    wire pe_aresetn = S_AXI_ARESETN && state != S_IDLE;
    reg [31:0] pe_ain, pe_din;
    reg [LOG2_DIM-1:0] pe_addr;
    reg [DIM-1:0] pe_we;
    wire pe_valid = state == S_CALC_READY;
    wire [DIM-1:0] pe_dvalid;
    wire [31:0] wrdata [DIM-1:0];

    genvar i;
    generate
        for (i = 0; i < DIM; i = i+1) begin
            my_pe #(.L_RAM_SIZE(LOG2_DIM)) pe(
                .aclk(BRAM_CLK),
                .aresetn(pe_aresetn),
                .ain(pe_ain),
                .din(pe_din),
                .addr(pe_addr),
                .we(pe_we[i]),
                .valid(pe_valid),
                .dvalid(pe_dvalid[i]),
                .dout(wrdata[i])
            );
        end
    endgenerate

    // pe_ready: Is PE ready for next MAC input?
    // Assume that all PEs are finished at the same time
    wire pe_ready = pe_dvalid[0];

    //
    // Shared register
    //
    reg [31:0] vector[0:DIM - 1];

    //
    // Outputs
    //
    reg bram_en;
    reg [BRAM_ADDR_WIDTH-1:0] bram_addr, bram_wrdata;
    assign done = state == S_DONE;
    assign BRAM_EN = bram_en;
    assign BRAM_RST = 1'b0;
    assign BRAM_WE = state == S_STORE ? 4'b1111 : 4'b0000;
    assign BRAM_ADDR = bram_addr;
    assign BRAM_WRDATA = bram_wrdata;

    //
    // At rising edge
    //
    always @(posedge S_AXI_ACLK) begin
        // Advance state
        state = next_state;
        counter = next_counter;
        // TODO: debug
        //slv_reg1 = state;
        //slv_reg2 = counter;

        // TODO: Change to combinational logic
        pe_ain = 0;
        pe_din = 0;
        pe_addr = 0;
        pe_we = 0;
        bram_en = 0;
        bram_addr = 0;
        bram_wrdata = 0;
        case (state)
            S_LOAD_V: begin
                if (counter < DIM) begin
                    // Read vector
                    bram_en = 1;
                    bram_addr = counter << 2;
                end
                if (counter >= 2) begin
                    // Delayed vector read result
                    // TODO: debug
                    vector[counter - 2] = 32'h40000000; // BRAM_RDDATA;
                end
            end
            S_LOAD_M: begin
                if (counter < DIM*DIM) begin
                    // Read matrix
                    bram_en = 1;
                    bram_addr = (DIM + counter) << 2;
                end
                if (counter >= 2) begin
                    // Delayed matrix read result
                    // TODO: debug
                    pe_din = 32'h40400000; // BRAM_RDDATA;
                    pe_addr = (counter - 2) & {LOG2_DIM{1'b1}};
                    pe_we[(counter - 2) >> LOG2_DIM] = 1;
                end
            end
            S_CALC_READY: begin
                // `pe_valid` is 1'b1 in here
                pe_ain = vector[counter];
                pe_addr = counter;
            end
            S_STORE: begin
                // Store the calculation output
                // `BRAM_WE` is 4'b1111 in here
                bram_en = 1;
                bram_addr = counter << 2;
                bram_wrdata = wrdata[counter];
            end
        endcase
    end
endmodule
