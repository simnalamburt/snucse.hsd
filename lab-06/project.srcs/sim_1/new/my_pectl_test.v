`timescale 1ns / 1ps

module my_pectl_test();
    // TODO
    wire done, addr, wrdata;
    my_pectl UUT(
        .start(0),
        .aclk(0),
        .aresetn(0),
        .rddata(0),
        .done(done),
        .addr(addr),
        .wrdata(wrdata)
    );

    initial begin
        // TODO
    end
endmodule
