`timescale 1ns / 1ps

module my_fusedmult #(
    parameter BITWIDTH = 32
) (
    input [BITWIDTH-1:0] ain,
    input [BITWIDTH-1:0] bin,
    input en,
    input clk,
    output [2*BITWIDTH-1:0] dout
);
    reg [2*BITWIDTH-1:0] accum;
    initial accum = 0;

    wire [2*BITWIDTH-1:0] multiplied;
    my_mul #(BITWIDTH) multiplier(
        .ain(ain),
        .bin(bin),
        .dout(multiplied)
    );

    wire [2*BITWIDTH-1:0] multiplied_added;
    my_add #(2*BITWIDTH) adder(
        .ain(accum),
        .bin(multiplied),
        .dout(multiplied_added)
        // Discard 'overflow'
    );

    always @(posedge clk) accum = en == 0 ? 0 : multiplied_added;
    assign dout = accum;
endmodule
