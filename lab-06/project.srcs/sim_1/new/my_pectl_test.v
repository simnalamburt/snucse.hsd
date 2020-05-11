`timescale 1ns / 1ps

module my_pectl_test();
    // clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // PE controller
    reg start;
    reg [31:0] rddata;
    wire done, addr, wrdata; // TODO
    my_pectl UUT(
        .start(start),
        .aclk(clk),
        .aresetn(1),
        .rddata(rddata),
        .done(done),
        .addr(addr),
        .wrdata(wrdata)
    );

    initial begin
        // S_IDLE
        start = 0;
        rddata = 0;
        #20;

        start = 1;
        #10;

        // S_LOAD
        // TODO: $readmemh("din.txt", some register); 로 대체하기
        rddata = 32'h00000000; #10;
        rddata = 32'h3f800000; #10;
        rddata = 32'h40000000; #10;
        rddata = 32'h40400000; #10;
        rddata = 32'h40800000; #10;
        rddata = 32'h40a00000; #10;
        rddata = 32'h40c00000; #10;
        rddata = 32'h40e00000; #10;
        rddata = 32'h41000000; #10;
        rddata = 32'h41100000; #10;
        rddata = 32'h41200000; #10;
        rddata = 32'h41300000; #10;
        rddata = 32'h41400000; #10;
        rddata = 32'h41500000; #10;
        rddata = 32'h41600000; #10;
        rddata = 32'h41700000; #10;
        rddata = 32'h41800000; #10;
        rddata = 32'h41880000; #10;
        rddata = 32'h41900000; #10;
        rddata = 32'h41980000; #10;
        rddata = 32'h41a00000; #10;
        rddata = 32'h41a80000; #10;
        rddata = 32'h41b00000; #10;
        rddata = 32'h41b80000; #10;
        rddata = 32'h41c00000; #10;
        rddata = 32'h41c80000; #10;
        rddata = 32'h41d00000; #10;
        rddata = 32'h41d80000; #10;
        rddata = 32'h41e00000; #10;
        rddata = 32'h41e80000; #10;
        rddata = 32'h41f00000; #10;
        rddata = 32'h41f80000; #10;
        rddata = 0;

        // S_CALC
        // TODO
        #200;
        $finish;
    end
endmodule
