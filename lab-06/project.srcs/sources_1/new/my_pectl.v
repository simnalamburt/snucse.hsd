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

    // TODO: FSM

    // TODO: GLobal BRAM
endmodule
