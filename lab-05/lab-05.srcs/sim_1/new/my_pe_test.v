`timescale 1ns / 1ps

module my_pe_test();
    // Clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    parameter RAM_SIZE = 4;
    reg reset;
    reg [31:0] float_in;
    reg [RAM_SIZE-1:0] addr;
    reg we;
    reg valid;
    wire dvalid;
    wire [31:0] dout;

    my_pe UUT(
        .aclk(clk),
        .aresetn(~reset),
        .ain(float_in),
        .din(float_in),
        .addr(addr),
        .we(we),
        .valid(valid),
        .dvalid(dvalid),
        .dout(dout)
    );
    defparam UUT.L_RAM_SIZE = RAM_SIZE;

    integer i;
    initial begin
        reset = 1;
        float_in = 0;
        addr = 0;
        we = 0;
        valid = 0;

        #10;

        reset = 0;
        we = 1;
        for (i = 0; i < 16; i = i + 1) begin
            float_in = $urandom;
            float_in = {7'b0100000, float_in[24:0]};
            addr = i;
            #10;
        end
        float_in = 0;
        addr = 0;
        we = 0;

        #30;

        for (i = 0; i < 16; i = i + 1) begin
            float_in = $urandom;
            float_in = {7'b0100000, float_in[24:0]};
            addr = i;
            valid = 1;
            #10;

            float_in = 0;
            addr = 0;
            valid = 0;
            wait (dvalid);
            #5;
        end

        $finish;
    end
endmodule
