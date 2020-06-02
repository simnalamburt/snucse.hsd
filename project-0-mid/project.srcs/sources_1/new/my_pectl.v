`timescale 1ns / 1ps

// NOTE: Latch가 synth 되는거 신경쓰지 않았음.
// 최적화할때엔 Latch 안생기도록 막아야함. 수업 PPT 참고.

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
    output done,

    // If done == 1, wrdata means result of vector inner product
    output [31:0] wrdata
);
    //
    // Global BRAM
    //
    (* ram_style = "block" *) reg [31:0] global_bram[0:2**LOG2_DIM - 1];


    //
    // FSM
    //
    // TODO 3: oldstate 삭제
    localparam S_IDLE        = 3'b000;
    localparam S_LOAD_PE     = 3'b001;
    localparam S_LOAD_SHARED = 3'b010;
    localparam S_CALC_READY  = 3'b011;
    localparam S_CALC_WAIT   = 3'b100;
    localparam S_DONE        = 3'b101;

    reg [2:0] state;
    reg [LOG2_DIM - 1:0] state_counter;

    wire [LOG2_DIM - 1 + 3:0] next_all;
    wire [2:0] next_state;
    wire [LOG2_DIM - 1:0] next_state_counter;

    assign next_all = next(state, state_counter, aresetn, start, pe_ready);
    assign next_state = next_all[2:0];
    assign next_state_counter = next_all[LOG2_DIM - 1 + 3:3];

    function [LOG2_DIM - 1 + 3:0] next(
        input [2:0] state, input [LOG2_DIM - 1:0] state_counter,
        input aresetn, start, pe_ready
    );
        if (!aresetn) begin
            next = {{LOG2_DIM{1'b0}}, S_IDLE};
        end else begin
            case (state)
                S_IDLE: begin
                    if (!start) begin
                        next = {{LOG2_DIM{1'b0}}, S_IDLE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, S_LOAD_PE};
                    end
                end
                S_LOAD_PE: begin
                    if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {state_counter + 1, S_LOAD_PE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, S_LOAD_SHARED};
                    end
                end
                S_LOAD_SHARED: begin
                    if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {state_counter + 1, S_LOAD_SHARED};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, S_CALC_READY};
                    end
                end
                S_CALC_READY: begin
                    next = {state_counter, S_CALC_WAIT};
                end
                S_CALC_WAIT: begin
                    if (!pe_ready) begin
                        next = {state_counter, S_CALC_WAIT};
                    end else if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {state_counter + 1, S_CALC_READY};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, S_DONE};
                    end
                end
                S_DONE: begin
                    if (state_counter < 5) begin
                        next = {state_counter + 1, S_DONE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, S_IDLE};
                    end
                end
                default: begin
                    // NOTE: Error!
                    next = {{LOG2_DIM{1'b0}}, S_IDLE};
                end
            endcase
        end
    endfunction


    // Old FSM
    // TODO: Remove me
    reg [LOG2_DIM+2:0] oldstate;
    localparam S_LOAD_peram_bound = 1 + (1<<LOG2_DIM);
    localparam S_LOAD_global_dram_bound = 1 + (1<<(LOG2_DIM+1));
    localparam S_CALC_bound = 1 + (1<<(LOG2_DIM+2));


    //
    // PE
    //
    reg [31:0] pe_ain, pe_din;
    reg [LOG2_DIM-1:0] pe_addr;
    reg pe_we, pe_valid;
    wire pe_dvalid;
    my_pe PE(
        .aclk(~aclk), // NOTE: Clock has been negated to avoid timing issue
        .aresetn(aresetn && state != S_IDLE),
        .ain(pe_ain),
        .din(pe_din),
        .addr(pe_addr),
        .we(pe_we),
        .valid(pe_valid),
        .dvalid(pe_dvalid),
        .dout(wrdata)
    );
    defparam PE.L_RAM_SIZE = LOG2_DIM;

    // pe_ready: Is PE ready for next MAC input?
    reg pe_ready;
    always @(negedge aclk) begin
        pe_ready = pe_dvalid;
    end


    // Next oldstate
    // TODO: Remove me
    wire [LOG2_DIM+2:0] next_oldstate;
    assign next_oldstate = next_old(oldstate, aresetn, start, pe_ready);
    function [LOG2_DIM+2:0] next_old(input [LOG2_DIM+2:0] oldstate, input aresetn, start, pe_ready);
        if (!aresetn) begin
            next_old = 0;
        end else begin
            if (oldstate == 0) begin
                // S_IDLE
                next_old = start;

            end else if (oldstate < S_LOAD_global_dram_bound) begin
                // S_LOAD
                next_old = oldstate + 1;

            end else if (oldstate < S_CALC_bound) begin
                // S_CALC
                if (!((oldstate - S_LOAD_global_dram_bound)&1)) begin
                    // Go to the wait oldstate
                    next_old = oldstate + 1;
                end else begin
                    // Finish wait only at pe_ready
                    next_old = oldstate + pe_ready;
                end

            end else begin
                // S_DONE
                if (oldstate - S_CALC_bound < 4) begin
                    next_old = oldstate + 1;
                end else begin
                    next_old = 0;
                end

            end
        end
    endfunction


    //
    // Output
    //
    assign done = state == S_DONE;


    //
    // Output (rising edge)
    //
    always @(posedge aclk) begin
        case (state)
            S_IDLE: begin
                pe_we = 0;
                pe_valid = 0;
            end
            S_LOAD_PE: begin
                pe_din = rddata;
                pe_addr = state_counter;
                pe_we = 1;
                pe_valid = 0;
            end
            S_LOAD_SHARED: begin
                pe_we = 0;
                pe_valid = 0;
                global_bram[state_counter] = rddata;
            end
            S_CALC_READY: begin
                pe_ain = global_bram[state_counter];
                pe_addr = state_counter;
                pe_we = 0;
                pe_valid = 1;
            end
            S_CALC_WAIT: begin
                pe_we = 0;
                pe_valid = 0;
            end
            S_DONE: begin
                pe_we = 0;
                pe_valid = 0;
            end
        endcase

        // Advance oldstate
        oldstate = next_oldstate; // TODO: Remove
        state = next_state;
        state_counter = next_state_counter;
    end

    //
    // Output (falling edge)
    //
    always @(negedge aclk) begin
        if (state == S_LOAD_PE) begin
            rdaddr = state_counter;
        end else if (state == S_LOAD_SHARED) begin
            // TODO: Use me
            // rdaddr = (1<<(LOG2_DIM*2)) + state_counter;
            rdaddr = (1<<(LOG2_DIM)) + state_counter;
        end
    end
endmodule
