`timescale 1ns / 1ps

// NOTE: Latch가 synth 되는거 신경쓰지 않았음.
// 최적화할때엔 Latch 안생기도록 막아야함. 수업 PPT 참고.

module my_pectl #(
    parameter L_RAM_SIZE = 4
) (
    // On S_IDLE state, start == 1 moves states to S_LOAD
    input start,

    // clock signal
    input aclk,

    // Negetive reset. aresetn == 0 means that reset is activated
    input aresetn,

    // If rdaddr is set, user should input data[rdaddr] as rddata
    output reg [L_RAM_SIZE:0] rdaddr,

    // On S_LOAD state, rddata will be stored into peram and global_bram
    input [31:0] rddata,

    // done == 1 if and only if internal state is S_DONE
    output done,

    // TODO: meaning
    output [31:0] wrdata
);
    //
    // Global BRAM
    //
    (* ram_style = "block" *) reg [31:0] global_bram[0:2**L_RAM_SIZE - 1];


    //
    // FSM
    //
    reg [L_RAM_SIZE+2:0] state;
    // S_IDLE               : state == 0
    // S_LOAD (peram)       : 1 <= state < 1 + (1<<L_RAM_SIZE)
    //                        counter = state - 1
    localparam S_LOAD_peram_bound = 1 + (1<<L_RAM_SIZE);
    // S_LOAD (global_dram) : 1 + (1<<L_RAM_SIZE) <= state < 1 + (1<<(L_RAM_SIZE+1))
    //                        counter = state - S_LOAD_peram_bound
    localparam S_LOAD_global_dram_bound = 1 + (1<<(L_RAM_SIZE+1));
    // S_CALC               : 1 + (1<<(L_RAM_SIZE+1)) <= state < 1 + (1<<(L_RAM_SIZE+2))
    //                        counter = (state - S_LOAD_global_dram_bound)>>1
    localparam S_CALC_bound = 1 + (1<<(L_RAM_SIZE+2));
    // S_DONE               : 1 + (1<<(L_RAM_SIZE+2)) <= state < 6 + (1<<(L_RAM_SIZE+2))
    //                        counter = state - S_CALC_bound


    //
    // PE
    //
    reg [31:0] pe_ain, pe_din;
    reg [L_RAM_SIZE-1:0] pe_addr;
    reg pe_we, pe_valid;
    wire pe_dvalid;
    wire [31:0] pe_dout;
    my_pe PE(
        .aclk(~aclk), // NOTE: Clock has been negated to avoid timing issue
        .aresetn(aresetn && state != 0),
        .ain(pe_ain),
        .din(pe_din),
        .addr(pe_addr),
        .we(pe_we),
        .valid(pe_valid),
        .dvalid(pe_dvalid),
        .dout(pe_dout)
    );
    defparam PE.L_RAM_SIZE = L_RAM_SIZE;

    // pe_ready: Is PE ready for next MAC input?
    reg pe_ready;
    always @(negedge aclk) begin
        pe_ready = pe_dvalid;
    end


    //
    // Next state
    //
    wire [L_RAM_SIZE+2:0] next_state;
    assign next_state = next(state, aresetn, start, pe_ready);
    function [L_RAM_SIZE+2:0] next(input [L_RAM_SIZE+2:0] state, input aresetn, start, pe_ready);
        if (!aresetn) begin
            next = 0;
        end else begin
            if (state == 0) begin
                // S_IDLE
                next = start;

            end else if (state < S_LOAD_global_dram_bound) begin
                // S_LOAD
                next = state + 1;

            end else if (state < S_CALC_bound) begin
                // S_CALC
                if (!((state - S_LOAD_global_dram_bound)&1)) begin
                    // Go to the wait state
                    next = state + 1;
                end else begin
                    // Finish wait only at pe_ready
                    next = state + pe_ready;
                end

            end else begin
                // S_DONE
                if (state - S_CALC_bound < 4) begin
                    next = state + 1;
                end else begin
                    next = 0;
                end

            end
        end
    endfunction


    //
    // Output
    //
    assign done = S_CALC_bound <= state;


    //
    // Output (rising edge)
    //
    always @(posedge aclk) begin
        if (state == 0) begin
            // S_IDLE: Do nothing
            pe_we = 0;
            pe_valid = 0;

        end else if (state < S_LOAD_peram_bound) begin
            // S_LOAD, store data into peram
            pe_din = rddata;
            pe_addr = state - 1;
            pe_we = 1;
            pe_valid = 0;

        end else if (state < S_LOAD_global_dram_bound) begin
            // S_LOAD, store data into global_bram
            pe_we = 0;
            pe_valid = 0;

            global_bram[state - S_LOAD_peram_bound] = rddata;

        end else if (state < S_CALC_bound) begin
            // S_CALC
            if (!((state - S_LOAD_global_dram_bound)&1)) begin
                // Perform MAC
                pe_ain = global_bram[(state - S_LOAD_global_dram_bound)>>1];
                pe_addr = (state - S_LOAD_global_dram_bound)>>1;
                pe_we = 0;
                pe_valid = 1;
            end else begin
                // Wait
                pe_we = 0;
                pe_valid = 0;
            end

        end else begin
            // S_DONE
            pe_we = 0;
            pe_valid = 0;
        end

        // Advance state
        state = next_state;
    end

    //
    // Output (falling edge)
    //
    always @(negedge aclk) begin
        if (0 < state && state < S_LOAD_global_dram_bound) begin
            // S_LOAD
            rdaddr = state - 1;
        end
    end
endmodule
