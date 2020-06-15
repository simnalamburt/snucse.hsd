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
    output done,

    // If done == 1, wrdata means result of vector inner product
    // TODO: wrdata를 여러개 두지 말고 배열에다가 쓰는 방식으로 바꿔야함
    output [31:0]
        wrdata0, wrdata1, wrdata2, wrdata3,
        wrdata4, wrdata5, wrdata6, wrdata7,
        wrdata8, wrdata9, wrdataA, wrdataB,
        wrdataC, wrdataD, wrdataE, wrdataF
);
    //
    // Global BRAM
    //
    (* ram_style = "block" *) reg [31:0] global_bram[0:2**LOG2_DIM - 1];


    //
    // FSM
    //
    localparam S_IDLE        = 3'b000;
    localparam S_LOAD_PE     = 3'b001;
    localparam S_LOAD_SHARED = 3'b010;
    localparam S_CALC_READY  = 3'b011;
    localparam S_CALC_WAIT   = 3'b100;
    localparam S_DONE        = 3'b101;

    reg [2:0] state;
    reg [LOG2_DIM - 1:0] state_counter, state_pe_load;

    wire [2*LOG2_DIM + 3 - 1:0] next_all;
    wire [2:0] next_state;
    wire [LOG2_DIM - 1:0] next_state_counter, next_state_pe_load;

    assign next_all = next(state, state_counter, state_pe_load, aresetn, start, pe_ready);
    assign next_state = next_all[3 - 1:0];
    assign next_state_counter = next_all[LOG2_DIM + 3 - 1:3];
    assign next_state_pe_load = next_all[2*LOG2_DIM + 3 - 1:LOG2_DIM + 3];

    function [2*LOG2_DIM + 3 - 1:0] next(
        input [2:0] state,
        input [LOG2_DIM - 1:0] state_counter, state_pe_load,
        input aresetn, start, pe_ready
    );
        if (!aresetn) begin
            next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_IDLE};
        end else begin
            case (state)
                S_IDLE: begin
                    if (!start) begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_IDLE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_LOAD_PE};
                    end
                end
                S_LOAD_PE: begin
                    if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {state_pe_load, state_counter + 1'b1, S_LOAD_PE};
                    end else if (state_pe_load < (1<<LOG2_DIM) - 1) begin
                        next = {state_pe_load + 1, {LOG2_DIM{1'b0}}, S_LOAD_PE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_LOAD_SHARED};
                    end
                end
                S_LOAD_SHARED: begin
                    if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {{LOG2_DIM{1'b0}}, state_counter + 1, S_LOAD_SHARED};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_CALC_READY};
                    end
                end
                S_CALC_READY: begin
                    next = {{LOG2_DIM{1'b0}}, state_counter, S_CALC_WAIT};
                end
                S_CALC_WAIT: begin
                    if (!pe_ready) begin
                        next = {{LOG2_DIM{1'b0}}, state_counter, S_CALC_WAIT};
                    end else if (state_counter < (1<<LOG2_DIM) - 1) begin
                        next = {{LOG2_DIM{1'b0}}, state_counter + 1, S_CALC_READY};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_DONE};
                    end
                end
                S_DONE: begin
                    if (state_counter < 5) begin
                        next = {{LOG2_DIM{1'b0}}, state_counter + 1, S_DONE};
                    end else begin
                        next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_IDLE};
                    end
                end
                default: begin
                    // NOTE: Error!
                    next = {{LOG2_DIM{1'b0}}, {LOG2_DIM{1'b0}}, S_IDLE};
                end
            endcase
        end
    endfunction


    //
    // PE
    //
    wire pe_aresetn;
    reg [31:0] pe_ain, pe_din;
    reg [LOG2_DIM-1:0] pe_addr;
    reg [(1<<LOG2_DIM)-1:0] pe_we;
    reg pe_valid;
    wire [LOG2_DIM-1:0] pe_dvalid;

    // TODO: wrdata를 여러개 두지 말고 배열에다가 쓰는 방식으로 바꿔야함
    wire [31:0] wrdata [(1<<LOG2_DIM)-1:0];
    assign wrdata0 = wrdata['h0];
    assign wrdata1 = wrdata['h1];
    assign wrdata2 = wrdata['h2];
    assign wrdata3 = wrdata['h3];
    assign wrdata4 = wrdata['h4];
    assign wrdata5 = wrdata['h5];
    assign wrdata6 = wrdata['h6];
    assign wrdata7 = wrdata['h7];
    assign wrdata8 = wrdata['h8];
    assign wrdata9 = wrdata['h9];
    assign wrdataA = wrdata['hA];
    assign wrdataB = wrdata['hB];
    assign wrdataC = wrdata['hC];
    assign wrdataD = wrdata['hD];
    assign wrdataE = wrdata['hE];
    assign wrdataF = wrdata['hF];

    // NOTE: Clock has been negated to avoid timing issue
    genvar i;
    generate
        for (i = 0; i < 1<<LOG2_DIM; i = i+1) begin
            my_pe #(.L_RAM_SIZE(LOG2_DIM)) pe(
                .aclk(~aclk),
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
    reg pe_ready;
    always @(negedge aclk) begin
        pe_ready = &pe_dvalid;
    end


    //
    // Output
    //
    assign pe_aresetn = aresetn && state != S_IDLE;
    assign done = state == S_DONE;


    //
    // Output (rising edge)
    //
    always @(posedge aclk) begin
        // Advance state
        state = next_state;
        state_counter = next_state_counter;
        state_pe_load = next_state_pe_load;

        // TODO: output 결정하는 combinational logic 분리하기
        case (state)
            S_IDLE: begin
                pe_we = 0;
                pe_valid = 0;
            end
            S_LOAD_PE: begin
                pe_din = rddata;
                pe_addr = state_counter;
                pe_we = 0;
                pe_we[state_pe_load] = 1;
                // TODO: 더 빠르게 로딩할 수 없을까?
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
    end

    //
    // Output (falling edge)
    //
    always @(negedge aclk) begin
        case (state)
            S_LOAD_PE: rdaddr = (1<<(LOG2_DIM))*state_pe_load + state_counter + 1;
            S_LOAD_SHARED: rdaddr = (1<<(LOG2_DIM*2)) + state_counter + 1;
            default: rdaddr = 0;
        endcase
    end
endmodule
