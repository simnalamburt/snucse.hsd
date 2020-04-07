`timescale 1ns / 1ps

module fma_u32_test();
    // Test input
    reg [31:0] a, b, c;
    wire [31:0] d_out;
    wire [47:0] d_carry_out;

    fma_u32 UUT(
        .a(a),
        .b(b),
        .c(c),
        .subtract(1'b0),
        .p(d_out),
        .pcout(d_carry_out)
    );

    // Define test suites
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            a = $urandom;
            b = $urandom;
            c = $urandom;
            #20;
        end
        $finish;
    end
endmodule
