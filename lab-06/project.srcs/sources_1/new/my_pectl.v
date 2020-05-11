`timescale 1ns / 1ps

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
    reg [31:0] din;
    reg [L_RAM_SIZE-1:0] pe_addr;
    reg we;
    initial we = 0;
    wire dvalid, dout; // TODO: use this
    my_pe PE(
        .aclk(~aclk), // NOTE: Clock has been negated to avoid timing issue
        .aresetn(aresetn),
        .ain(0), // TODO
        .din(din),
        .addr(pe_addr),
        .we(we),
        .valid(0), // TODO
        .dvalid(dvalid),
        .dout(dout)
    );
    defparam PE.L_RAM_SIZE = L_RAM_SIZE;

    //
    // Global BRAM
    //
    (* ram_style = "block" *) reg [31:0] global_bram[0:2**L_RAM_SIZE - 1];

    //
    // Counter
    // Value range: [-1, 2**(L_RAM_SIZE+1)]
    //
    // TODO: 비트 크기 조절 필요할것임
    reg [L_RAM_SIZE+1:0] counter;
    initial counter = 0;
    always @(negedge aclk) counter = counter + 1;

    //
    // FSM
    //
    localparam [1:0] S_IDLE = 0, S_LOAD = 1, S_CALC = 2, S_DONE = 3;
    reg [1:0] state;
    initial state = S_IDLE;
    always @(posedge aclk) begin
        case (state)
            S_IDLE: begin
                // state == S_IDLE && start: go to S_LOAD
                if (start) begin
                    state = S_LOAD;
                    counter = -1;
                end
            end

            S_LOAD: begin
                if (counter < 2**L_RAM_SIZE) begin
                    // If L_RAM_SIZE = 4:
                    // Load 16 data into local buffer in PE
                    we = 1;
                    din = rddata;
                    pe_addr = counter;
                end else if (counter < 2**(L_RAM_SIZE+1)) begin
                    // If L_RAM_SIZE = 4:
                    // Load 16 data into global BRAM
                    we = 0;
                    global_bram[counter & (2**L_RAM_SIZE - 1)] = rddata;

                    // state == S_LOAD && counter == 31: go to S_CALC
                    if (counter == 31) begin
                        state = S_CALC;
                        counter = -1;
                    end
                end
            end

            S_CALC: begin
                // TODO: 이 시점에 peram이랑 global_bram에 데이터가 다 차있어야 함

                // TODO: 구현하기
            end

            // TODO
            S_DONE: begin
            end
        endcase
    end
endmodule
