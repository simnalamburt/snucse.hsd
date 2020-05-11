`timescale 1ns / 1ps

module my_pectl_test();
    // clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // PE controller
    reg start;
    // TODO
    wire done, addr, wrdata;
    my_pectl UUT(
        .start(start),
        .aclk(clk),
        .aresetn(1),
        // TODO
        .rddata(0),
        .done(done),
        .addr(addr),
        .wrdata(wrdata)
    );

    initial begin
        // S_IDLE
        start = 0;
        #20;
        start = 1;
        #10;

        // S_LOAD
        #320;

        // S_CALC
        #200;
        $finish;

        // TODO
        // $readmemh("din.txt", some register);
    end
endmodule
