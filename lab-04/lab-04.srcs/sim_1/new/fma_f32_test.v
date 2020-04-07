`timescale 1ns / 1ps

module fma_f32_test();
    // Test input
    reg [31:0] a, b, c;
    reg reset;
    wire [31:0] d_out;
    wire d_valid;

    // Define clock
    reg clock;
    initial clock = 0;
    always #5 clock = ~clock;

    fma_f32 UUT(
        .aclk(clock),
        .aresetn(~reset),
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(a),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(b),
        .s_axis_c_tvalid(1'b1),
        .s_axis_c_tdata(c),
        .m_axis_result_tvalid(d_valid),
        .m_axis_result_tdata(d_out)
    );

    // Define test suites
    integer i;
    initial begin
        a = 0;
        b = 0;
        c = 0;
        reset = 0;

        for (i = 0; i < 32; i = i + 1) begin
            a = $urandom;
            b = $urandom;
            c = $urandom;
            #20;
        end

        $finish;
    end
endmodule
