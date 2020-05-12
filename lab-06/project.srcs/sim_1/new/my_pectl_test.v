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
        // TODO: $readmemh("din.txt", some register); 로 대체하기
        data[00] = 32'h00000000;
        data[01] = 32'h3f800000;
        data[02] = 32'h40000000;
        data[03] = 32'h40400000;
        data[04] = 32'h40800000;
        data[05] = 32'h40a00000;
        data[06] = 32'h40c00000;
        data[07] = 32'h40e00000;
        data[08] = 32'h41000000;
        data[09] = 32'h41100000;
        data[10] = 32'h41200000;
        data[11] = 32'h41300000;
        data[12] = 32'h41400000;
        data[13] = 32'h41500000;
        data[14] = 32'h41600000;
        data[15] = 32'h41700000;
        data[16] = 32'h41800000;
        data[17] = 32'h41880000;
        data[18] = 32'h41900000;
        data[19] = 32'h41980000;
        data[20] = 32'h41a00000;
        data[21] = 32'h41a80000;
        data[22] = 32'h41b00000;
        data[23] = 32'h41b80000;
        data[24] = 32'h41c00000;
        data[25] = 32'h41c80000;
        data[26] = 32'h41d00000;
        data[27] = 32'h41d80000;
        data[28] = 32'h41e00000;
        data[29] = 32'h41e80000;
        data[30] = 32'h41f00000;
        data[31] = 32'h41f80000;


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
