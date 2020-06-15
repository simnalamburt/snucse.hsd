`timescale 1ns / 1ps

module my_pectl_tb();
    // testbench data
    //
    // 000..255: Input matrix with 16*16 elements
    //   000..015: row 1
    //   016..031: row 2
    //   032..047: row 3
    //   (cont)
    // 256..271: Input vector with 16 elements
    // 272..287: Output vector with 16 elements
    reg [31:0] data[0:287];

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
        $display("");
        $display("Expected result : 0x46f9b000 0x47c22c00 0x4822f600 0x4864d600 0x48935b00 0x48b44b00 0x48d53b00 0x48f62b00 0x490b8d80 0x491c0580 0x492c7d80 0x493cf580 0x494d6d80 0x495de580 0x496e5d80 0x497ed580");
        $display("Actual result   : 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x",
            data[272], data[273], data[274], data[275],
            data[276], data[277], data[278], data[279],
            data[280], data[281], data[282], data[283],
            data[284], data[285], data[286], data[287]);
        $display("Finished at     : %d", $time);
        $display("");
        #50;

        // S_IDLE
        #50;

        $finish;
    end
endmodule
