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


    //
    // PE
    //
    reg [31:0] pe_ain, pe_din;
    reg [LOG2_DIM-1:0] pe_addr;
    reg pe_we, pe_valid;
    wire [LOG2_DIM-1:0] pe_dvalid;

    // NOTE: Clock has been negated to avoid timing issue
    // TODO: generate 문으로 바꾸기
    my_pe pe0(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h0]), .dout(wrdata0));
    my_pe pe1(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h1]), .dout(wrdata1));
    my_pe pe2(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h2]), .dout(wrdata2));
    my_pe pe3(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h3]), .dout(wrdata3));
    my_pe pe4(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h4]), .dout(wrdata4));
    my_pe pe5(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h5]), .dout(wrdata5));
    my_pe pe6(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h6]), .dout(wrdata6));
    my_pe pe7(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h7]), .dout(wrdata7));
    my_pe pe8(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h8]), .dout(wrdata8));
    my_pe pe9(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['h9]), .dout(wrdata9));
    my_pe peA(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hA]), .dout(wrdataA));
    my_pe peB(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hB]), .dout(wrdataB));
    my_pe peC(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hC]), .dout(wrdataC));
    my_pe peD(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hD]), .dout(wrdataD));
    my_pe peE(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hE]), .dout(wrdataE));
    my_pe peF(.aclk(~aclk), .aresetn(aresetn && state != S_IDLE), .ain(pe_ain), .din(pe_din), .addr(pe_addr), .we(pe_we), .valid(pe_valid), .dvalid(pe_dvalid['hF]), .dout(wrdataF));
    defparam pe0.L_RAM_SIZE = LOG2_DIM;
    defparam pe1.L_RAM_SIZE = LOG2_DIM;
    defparam pe2.L_RAM_SIZE = LOG2_DIM;
    defparam pe3.L_RAM_SIZE = LOG2_DIM;
    defparam pe4.L_RAM_SIZE = LOG2_DIM;
    defparam pe5.L_RAM_SIZE = LOG2_DIM;
    defparam pe6.L_RAM_SIZE = LOG2_DIM;
    defparam pe7.L_RAM_SIZE = LOG2_DIM;
    defparam pe8.L_RAM_SIZE = LOG2_DIM;
    defparam pe9.L_RAM_SIZE = LOG2_DIM;
    defparam peA.L_RAM_SIZE = LOG2_DIM;
    defparam peB.L_RAM_SIZE = LOG2_DIM;
    defparam peC.L_RAM_SIZE = LOG2_DIM;
    defparam peD.L_RAM_SIZE = LOG2_DIM;
    defparam peE.L_RAM_SIZE = LOG2_DIM;
    defparam peF.L_RAM_SIZE = LOG2_DIM;

    // pe_ready: Is PE ready for next MAC input?
    reg pe_ready;
    always @(negedge aclk) begin
        pe_ready = &pe_dvalid;
    end


    //
    // Output
    //
    assign done = state == S_DONE;


    //
    // Output (rising edge)
    //
    always @(posedge aclk) begin
        // Advance state
        state = next_state;
        state_counter = next_state_counter;

        // TODO: output 결정하는 combinational logic 분리하기
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
    end

    //
    // Output (falling edge)
    //
    always @(negedge aclk) begin
        case (state)
            S_LOAD_PE: rdaddr = state_counter + 1;
            // S_LOAD_SHARED: rdaddr = (1<<(LOG2_DIM*2)) + state_counter + 1;
            S_LOAD_SHARED: rdaddr = (1<<(LOG2_DIM)) + state_counter + 1;
            default: rdaddr = 0;
        endcase
    end
endmodule
