`timescale 1ns / 1ps

module my_bram_test();
    // Clock
    reg clk;
    initial clk = 0;
    always #5 clk = ~clk;

    reg [14:0] addr1;
    reg en1, done1;
    wire [31:0] result1;

    my_bram BRAM1(
        .BRAM_ADDR(addr1),
        .BRAM_CLK(clk),
        .BRAM_WRDATA(0),
        .BRAM_RDDATA(result1),
        .BRAM_EN(en1),
        .BRAM_RST(1'b0),
        .BRAM_WE(4'b0000),
        .done(done1)
    );
    defparam BRAM1.OUT_FILE = "output1.txt";

    reg [14:0] addr2;
    reg en2, done2;

    my_bram BRAM2(
        .BRAM_ADDR(addr2),
        .BRAM_CLK(clk),
        .BRAM_WRDATA(result1),
        //.BRAM_RDDATA(),
        .BRAM_EN(en2),
        .BRAM_RST(1'b0),
        .BRAM_WE(4'b1111),
        .done(done2)
    );
    defparam BRAM2.INIT_FILE = "";
    defparam BRAM2.OUT_FILE = "output2.txt";

    initial begin
        en1 = 1;
        done1 = 0;
        for (addr1 = 0; addr1 < 8192; addr1 = addr1 + 4) begin
            #10; // Pass 1 cycle
        end
        en1 = 0;
        #20; // Pass 2 cycle
        done1 = 1;
    end

    initial begin
        en2 = 0;
        done2 = 0;
        #20; // Pass 2 cycle
        en2 = 1;
        for (addr2 = 0; addr2 < 8192; addr2 = addr2 + 4) begin
            #10; // Pass 1 cycle
        end
        en2 = 0;
        #10; // Pass 1 cycle
        done2 = 1;

        #50; // Pass 5 cycle
        $finish;
    end
endmodule
