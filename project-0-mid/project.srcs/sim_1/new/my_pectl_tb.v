`timescale 1ns / 1ps

module my_pectl_tb();
    // testbench data
    //
    // 000..015: Input vector with 16 elements
    // 016..271: Input matrix with 16*16 elements
    //   016..031: row 1
    //   032..047: row 2
    //   (cont)
    reg [31:0] data[0:271];

    // clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    // PE controller
    reg start, reset;
    wire done;
    wire [8:0] rdaddr;
    my_pectl UUT(
        .start(start),
        .aclk(clk),
        .aresetn(~reset),
        .rddata(data[rdaddr]),
        .done(done),
        .rdaddr(rdaddr)
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
        $display("");
        $display("Expected result : 0x46f9b000 0x47c22c00 0x4822f600 0x4864d600 0x48935b00 0x48b44b00 0x48d53b00 0x48f62b00 0x490b8d80 0x491c0580 0x492c7d80 0x493cf580 0x494d6d80 0x495de580 0x496e5d80 0x497ed580");
        $display("Finished at     : %d", $time);
        $display("");
        #50;

        // S_IDLE
        #50;

        $finish;
    end
endmodule
