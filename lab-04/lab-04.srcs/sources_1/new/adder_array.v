`timescale 1ns / 1ps

module adder_array(
    input [2:0] cmd,
    input [31:0] ain0, ain1, ain2, ain3, bin0, bin1, bin2, bin3,
    output [31:0] dout0, dout1, dout2, dout3,
    output [3:0] overflow
);
    parameter BITWIDTH = 32;
    wire [31:0] ain[3:0], bin[3:0], dout[3:0], unmasked_dout[3:0];
    assign {ain[0], ain[1], ain[2], ain[3]} = {ain0, ain1, ain2, ain3};
    assign {bin[0], bin[1], bin[2], bin[3]} = {bin0, bin1, bin2, bin3};
    assign {dout0, dout1, dout2, dout3} = {dout[0], dout[1], dout[2], dout[3]};

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin
            my_add #(BITWIDTH) adder(
                .ain(ain[i]),
                .bin(bin[i]),
                .dout(unmasked_dout[i]),
                .overflow(overflow[i])
            );
            assign dout[i] = (cmd == i || cmd == 4) ? unmasked_dout[i] : 0;
        end
    endgenerate
endmodule

module my_add #(
    parameter BITWIDTH = 32
) (
    input [BITWIDTH-1:0] ain,
    input [BITWIDTH-1:0] bin,
    output [BITWIDTH-1:0] dout,
    output overflow
);
    // NOTE: Intentionally won't use the simple form below:
    //
    //    assign {overflow, dout} = ain + bin;

    // Carry of `ain[i] + bin[i]` will be stored to `carry[i]`
    wire [BITWIDTH-1:0] carry;

    // Automatically implement multiple adder
    genvar i;
    generate
        for (i = 0; i < BITWIDTH; i = i + 1) begin
            if (i == 0) begin
                // First adder does not have carry_in
                half_adder adder(.a(ain[i]), .b(bin[i]), .s(dout[i]), .carry_out(carry[i]));
            end else begin
                // The other adders do have carry_in. Use full_adder
                full_adder adder(.a(ain[i]), .b(bin[i]), .carry_in(carry[i - 1]), .s(dout[i]), .carry_out(carry[i]));
            end
        end
    endgenerate

    // The last carry `carry[BITWIDTH-1]` should be wired to `overflow`
    assign overflow = carry[BITWIDTH-1];
endmodule

// 1-bit full adder
module full_adder (
    input a, b, carry_in,
    output s, carry_out
);
    wire sum_intermediate;
    wire carry_intermediate_0;
    wire carry_intermediate_1;

    // 1-bit full adder is composition of two 1-bit half adder
    half_adder first_half(.a(a), .b(b), .s(sum_intermediate), .carry_out(carry_intermediate_0));
    half_adder second_half(.a(carry_in), .b(sum_intermediate), .s(s), .carry_out(carry_intermediate_1));
    assign carry_out = carry_intermediate_0 | carry_intermediate_1;
endmodule

// 1-bit half adder
module half_adder (
    input a, b,
    output s, carry_out
);
    assign s = a ^ b;
    assign carry_out = a & b;
endmodule
