`timescale 1ns / 1ps

module my_pectl #(
    parameter L_RAM_SIZE = 5
) (
    // TODO: meaning
    input start,

    // clock signal
    input aclk,

    // Negetive reset. aresetn == 0 means that reset is activated
    input aresetn,

    // TODO: meaning
    input [31:0] rddata,

    // TODO: meaning
    output done,

    // TODO: meaning
    output [L_RAM_SIZE-1:0] addr,

    // TODO: meaning
    output [31:0] wrdata
);
    //
    // Counter, [-1, 32]
    //
    // TODO: reduce unused bits
    reg [7:0] counter;
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
                if (start) begin
                    state = S_LOAD;
                    counter = -1;
                end
            end

            S_LOAD: begin
                if (counter < 16) begin
                    // TODO: Load 16 data into local buffer in PE
                end else if (counter < 32) begin
                    // TODO: Load 16 data into global BRAM

                    if (counter == 31) begin
                        state = S_CALC;
                        counter = -1;
                    end
                end
            end

            // TODO
            S_CALC: begin
            end

            // TODO
            S_DONE: begin
            end
        endcase
    end

    // PE
    // TODO: 핀에 입력 넣기, L_RAM_SIZE 바꾸기
    wire dvalid, dout;
    my_pe PE(
        .aclk(0),
        .aresetn(0),
        .ain(0),
        .din(0),
        .addr(0),
        .we(0),
        .valid(0),
        .dvalid(dvalid),
        .dout(dout)
    );

    // TODO: Global BRAM
    // NOTE: (* ram_style = "block" *) 만 있고 딜레이는 없음
endmodule
