`timescale 1ns / 1ps

module tb_mul();
    // Test input
    parameter BITWIDTH = 32;
    reg [BITWIDTH-1:0] ain;
    reg [BITWIDTH-1:0] bin;

    // My multiplier
    wire [2*BITWIDTH-1:0] dout;
    my_mul #(BITWIDTH) MY_MUL(
        .ain(ain),
        .bin(bin),
        .dout(dout)
    );

    // Expected output
    wire [2*BITWIDTH-1:0] dout_expected;
    assign dout_expected = ain * bin;

    // If is_ok is true, my_adder is working fine.
    // Otherwise, my_adder is malfunctioning.
    wire is_ok;
    assign is_ok = dout == dout_expected;

    // Define test suites
    integer i;
    initial begin
        // Test small numbers
        for (i = 0; i < 10; i = i + 1) begin
            ain = $urandom_range(100, 0);
            bin = $urandom_range(100, 0);
            #10;
        end
        // Test big random numbers
        for (i = 0; i < 20; i = i + 1) begin
            // Use range [0, 2**32)
            ain = $urandom;
            bin = $urandom;
            #10;
        end
    end
endmodule
