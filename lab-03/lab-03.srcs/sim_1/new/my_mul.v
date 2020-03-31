`timescale 1ns / 1ps

module my_mul #(
    parameter BITWIDTH = 32
) (
    input [BITWIDTH-1:0] ain,
    input [BITWIDTH-1:0] bin,
    output [2*BITWIDTH-1:0] dout
);
    // NOTE: Intentionally won't use the simple form below:
    //
    //    assign dout = ain * bin;

    wire [BITWIDTH-1:0] carry [BITWIDTH-1:0];
    genvar i;
    generate
        for (i = 0; i < BITWIDTH; i = i + 1) begin
            if (i == 0) begin
                assign {carry[i], dout[i]} = bin[i] ? ain : 0;
            end else begin
                wire [BITWIDTH:0] sum;
                my_add adder(.ain(ain), .bin(carry[i - 1]), .dout(sum[BITWIDTH - 1:0]), .overflow(sum[BITWIDTH]));
                assign {carry[i], dout[i]} = bin[i] ? sum : carry[i - 1];
            end
        end
    endgenerate

    // The last carry should be output
    assign dout[2*BITWIDTH - 1:BITWIDTH] = carry[BITWIDTH-1];
endmodule
