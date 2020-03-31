`timescale 1ns / 1ps

module tb_fusedmult();
    // Test input
    parameter BITWIDTH = 32;
    reg [BITWIDTH-1:0] ain;
    reg [BITWIDTH-1:0] bin;
    reg clk;
    reg en;

    // My fusedmult
    wire [2*BITWIDTH-1:0] dout;
    my_fusedmult #(BITWIDTH) MY_MAC(
        .ain(ain),
        .bin(bin),
        .en(en),
        .clk(clk),
        .dout(dout)
    );

    // Expected output
    reg [2*BITWIDTH-1:0] dout_expected;
    initial dout_expected = 0;
    always @(posedge clk) dout_expected = en == 0 ? 0 : dout_expected + ain * bin;

    // If is_ok is true, my_adder is working fine.
    // Otherwise, my_adder is malfunctioning.
    wire is_ok;
    assign is_ok = dout == dout_expected;

    // Define clock and test suites
    always #5 clk = ~clk;

    integer i;
    initial begin
        // Initialize registers
        clk = 0;
        en = 0;
        #30;

        // Test small inputs
        en = 1;
        for (i = 0; i < 10; i = i + 1) begin
            ain = $urandom_range(10, 0);
            bin = $urandom_range(10, 0);
            #10;
        end

        // Test reset
        en = 0;
        #30;

        // Test large inputs
        en = 1;
        for (i = 0; i < 30; i = i + 1) begin
            // Use range [0, 2**31)
            ain = $urandom_range(2**31 - 1, 0);
            bin = $urandom_range(2**31 - 1, 0);
            #10;
        end

        // Test reset
        en = 0;
    end
endmodule
