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
    wire [31:0] wrdata [15:0];
    my_pectl UUT(
        .start(start),
        .aclk(clk),
        .aresetn(~reset),
        .rddata(data[rdaddr]),
        .done(done),
        .rdaddr(rdaddr),
        .wrdata0(wrdata['h0]), .wrdata1(wrdata['h1]), .wrdata2(wrdata['h2]), .wrdata3(wrdata['h3]),
        .wrdata4(wrdata['h4]), .wrdata5(wrdata['h5]), .wrdata6(wrdata['h6]), .wrdata7(wrdata['h7]),
        .wrdata8(wrdata['h8]), .wrdata9(wrdata['h9]), .wrdataA(wrdata['hA]), .wrdataB(wrdata['hB]),
        .wrdataC(wrdata['hC]), .wrdataD(wrdata['hD]), .wrdataE(wrdata['hE]), .wrdataF(wrdata['hF])
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
        $display("Expected result : 46f9b000 47c22c00 4822f600 4864d600 48935b00 48b44b00 48d53b00 48f62b00 490b8d80 491c0580 492c7d80 493cf580 494d6d80 495de580 496e5d80 497ed580");
        $display("Actual result   : 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x 0x%8x",
            wrdata['h0], wrdata['h1], wrdata['h2], wrdata['h3],
            wrdata['h4], wrdata['h5], wrdata['h6], wrdata['h7],
            wrdata['h8], wrdata['h9], wrdata['hA], wrdata['hB],
            wrdata['hC], wrdata['hD], wrdata['hE], wrdata['hF]);
        $display("Finished at     : %d", $time);
        $display("");
        #50;

        // S_IDLE
        #50;

        $finish;
    end
endmodule
