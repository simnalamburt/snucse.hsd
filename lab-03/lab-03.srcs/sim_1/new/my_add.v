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
