`timescale 1ns / 1ps

module my_pectl(
    input start,
    input reset,
    input clk,
    // TODO
    input rddata,
    // TODO
    output rdaddr,
    // TODO
    output out
);
    // TODO
    my_pe PE(
        .aclk(0),
        .aresetn(0),
        .ain(0),
        .din(0),
        .addr(0),
        .we(0),
        .valid(0),
        .dvalid(0),
        .dout(0)
    );
endmodule
