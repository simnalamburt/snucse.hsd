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
    // TODO: aresetn = 0 으로 한다고 pe와 pectl 안에있는 state가 모두 초기화되지 않음
    input aresetn,

    // On S_LOAD state, rddata will be stored into peram and global_bram
    input [31:0] rddata,

    // TODO: meaning
    output done,

    // TODO: meaning
    output [L_RAM_SIZE-1:0] addr,

    // TODO: meaning
    output [31:0] wrdata
);
    //
    // PE
    //
    reg [31:0] pe_ain, pe_din;
    reg [L_RAM_SIZE-1:0] pe_addr;
    reg pe_we, pe_valid;
    wire pe_dvalid, pe_dout; // TODO: use this
    my_pe PE(
        .aclk(~aclk), // NOTE: Clock has been negated to avoid timing issue
        .aresetn(aresetn),
        .ain(pe_ain),
        .din(pe_din),
        .addr(pe_addr),
        .we(pe_we),
        .valid(pe_valid),
        .dvalid(pe_dvalid),
        .dout(pe_dout)
    );
    defparam PE.L_RAM_SIZE = L_RAM_SIZE;

    //
    // Global BRAM
    //
    (* ram_style = "block" *) reg [31:0] global_bram[0:2**L_RAM_SIZE - 1];

    //
    // FSM
    //
    // S_IDLE: state == 0
    // S_LOAD: 1 <= state < 1 + (1<<(L_RAM_SIZE+1))
    // S_CALC: 1 + (1<<(L_RAM_SIZE+1)) <= state < 1 + (1<<(L_RAM_SIZE+1)) + (1<<(L_RAM_SIZE))
    // S_DONE: otherwise
    //
    reg [L_RAM_SIZE+1:0] state;
    wire [L_RAM_SIZE+1:0] next_state;
    assign next_state = next(state, aresetn, start);
    function [L_RAM_SIZE+1:0] next(input [L_RAM_SIZE+1:0] state, input aresetn, start);
        if (!aresetn) begin
            next = 0;
        end else begin
            if (state == 0) begin
                // S_IDLE
                next = start;
            end else if (state < 1 + (1<<(L_RAM_SIZE+1))) begin
                // S_LOAD
                next = next + 1;
            end else if (state < 1 + (1<<(L_RAM_SIZE+1)) + (1<<(L_RAM_SIZE))) begin
                // S_CALC
                // TODO
                next = next;
            end else begin
                // S_DONE
                // TODO
                next = next;
            end
        end
    endfunction

    always @(posedge aclk) begin
        // Advance state
        state = next_state;

        // TODO: comb logic으로 떼기
        if (state == 0) begin
            // S_IDLE: Do nothing
            pe_we = 0;
            pe_valid = 0;

        end else if (state < 1 + (1<<L_RAM_SIZE)) begin
            // S_LOAD, store data into peram
            pe_din = rddata;
            pe_addr = state - 1;
            pe_we = 1;
            pe_valid = 0;

        end else if (state < 1 + (1<<(L_RAM_SIZE+1))) begin
            // S_LOAD, store data into global_bram
            pe_we = 0;
            pe_valid = 0;

            global_bram[state - (1 + (1<<L_RAM_SIZE))] = rddata;

        end else if (state < 1 + (1<<(L_RAM_SIZE+1)) + (1<<(L_RAM_SIZE))) begin
            // S_CALC
            // TODO: 1. ON RISING EDGE: 데이터 받아서 PE에 선입력시키기
            if (0) begin
                pe_ain = global_bram[state - (1 + (1<<(L_RAM_SIZE+1)))];
                pe_addr = state - (1 + (1<<(L_RAM_SIZE+1)));
                pe_we = 0;
                pe_valid = 1;
            end

            // TODO: 2. NEXT RISING EDGE: valid 꺼서 입력 종료시키기
            if (0) begin
                pe_we = 0;
                pe_valid = 0;
            end
        end else begin
            // S_DONE
            // TODO: 구현
        end
    end

    always @(negedge aclk) begin
        // TODO: comb logic으로 떼기
        if (state < 1 + (1<<(L_RAM_SIZE+1))) begin
            // S_IDLE, S_LOAD: Do nothing
        end else if (state < 1 + (1<<(L_RAM_SIZE+1)) + (1<<(L_RAM_SIZE))) begin
            // S_CALC
            // TODO: 3. ON FALLING EDGE: dvalid 1인지 체크, 1일경우 counter 1 증가시키고 다음 값 세팅할 준비
            // TODO: 3a. dvalid가 1이면서 counter가 끝까지 올라갔을경우 S_DONE으로 넘어가기
        end else begin
            // S_DONE: Do nothing
        end
    end
endmodule
