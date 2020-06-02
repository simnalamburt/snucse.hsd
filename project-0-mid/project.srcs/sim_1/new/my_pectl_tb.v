`timescale 1ns / 1ps

module my_pectl_tb();
    // testbench data
    //
    // 000..255: Matrix with 16*16 elements
    //   000..015: row 1
    //   016..031: row 2
    //   032..047: row 3
    //   (cont)
    // 256..271: Vector with 16 elements
    reg [31:0] data[0:271];

    // clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // PE controller
    reg start, reset;
    wire done;
    wire [8:0] rdaddr;
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
        $display("\n\nResult of vector inner product: 0x%8x", wrdata);
        $display("Expected output: 0x4b035180\n");
        #50;

        // S_IDLE
        #50;

        $finish;
    end
endmodule
