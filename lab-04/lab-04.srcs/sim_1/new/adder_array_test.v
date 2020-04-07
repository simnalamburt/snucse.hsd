`timescale 1ns / 1ps

module adder_array_test();
    // Test input
    reg [2:0] cmd;
    reg [31:0] a[3:0], b[3:0];
    wire [31:0] d_out[3:0];
    wire [3:0] overflow_out;

    adder_array UUT(
        .cmd(cmd),
        .ain0(a[0]),
        .ain1(a[1]),
        .ain2(a[2]),
        .ain3(a[3]),
        .bin0(b[0]),
        .bin1(b[1]),
        .bin2(b[2]),
        .bin3(b[3]),
        .dout0(d_out[0]),
        .dout1(d_out[1]),
        .dout2(d_out[2]),
        .dout3(d_out[3]),
        .overflow(overflow_out)
    );

    // Define test suites
    integer i, j, k;
    initial begin
        for (i = 0; i < 5; i = i + 1) begin
            cmd = i;
            for (j = 0; j < 4; j = j + 1) begin
                for (k = 0; k < 4; k = k + 1) begin
                    a[k] = $urandom;
                    b[k] = $urandom;
                end
                #5;
            end
        end
        $finish;
    end
endmodule
