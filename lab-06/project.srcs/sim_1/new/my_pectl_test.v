`timescale 1ns / 1ps

module my_pectl_test();
    // testbench data
    reg [31:0] data[0:(1<<5) - 1];

    // clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // PE controller
    reg start, reset;
    wire done;
    wire [4:0] rdaddr;
    wire [31:0] wrdata;
    my_pectl UUT(
        .start(start),
        .aclk(clk),
        .aresetn(~reset),
        .rddata(data[rdaddr]),
        .done(done),
        .rdaddr(rdaddr),
        .wrdata(wrdata)
    );

    initial begin
        $readmemh("data-input.txt", data);

        // Uninitialized state
        reset = 0;
        #20;

        // Reset states
        reset = 1;
        start = 0;
        #10;
        reset = 0;

        // S_IDLE
        #30;
        start = 1;
        #10;
        start = 0;

        // S_LOAD, S_CALC
        wait (done);

        // S_DONE
        $display("\n\nResult of vector inner product: %8x\n\n", wrdata);
        #50;

        // S_IDLE
        #50;

        $finish;
    end
endmodule
