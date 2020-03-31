`timescale 1ns / 1ps

module tb_add();
    // Test input
    parameter BITWIDTH = 32;
    reg [BITWIDTH-1:0] ain;
    reg [BITWIDTH-1:0] bin;

    // My adder
    wire [BITWIDTH-1:0] dout;
    wire overflow;
    my_add #(BITWIDTH) MY_ADDER(
        .ain(ain),
        .bin(bin),
        .dout(dout),
        .overflow(overflow)
    );

    // Expected output
    wire [BITWIDTH-1:0] dout_expected;
    wire overflow_expected;
    assign {overflow_expected, dout_expected} = ain + bin;

    // Test wire
    // If is_ok is true, my_adder is working fine.
    // Otherwise, my_adder is malfunctioning.
    wire is_ok;
    assign is_ok = (overflow == overflow_expected) && (dout == dout_expected);

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
            // Use range [0, 2**31)
            ain = $urandom_range(2**31 - 1, 0);
            bin = $urandom_range(2**31 - 1, 0);
            #10;
        end
        // Test overflow
        for (i = 0; i < 10; i = i + 1) begin
            // Use range [2**31, 2**32)
            ain = $urandom_range(2**32 - 1, 2**31);
            bin = $urandom_range(2**32 - 1, 2**31);
            #10;
        end
    end
endmodule
