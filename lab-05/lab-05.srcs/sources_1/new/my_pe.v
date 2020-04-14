`timescale 1ns / 1ps

module my_pe #(
    parameter L_RAM_SIZE = 6
) (
    // clock signal
    input aclk,

    // Negetive reset. aresetn == 0 means that reset is activated
    input aresetn,

    // port A, directly connected to MAC
    input [31:0] ain,

    // peram-> port B, connected to local register
    input [31:0] din,
    input [L_RAM_SIZE-1:0] addr,
    // we == 1, `din` is stored to `peram[addr]`
    // we == 0, `peram[addr]` is assigned to one of inputs of MAC
    input we,

    // integrated valid signal
    // valid == 1, MAC gets inputs from its input ports and starts computation
    input valid,

    // computation result
    // dvalid == 1, result data from MAC is valid
    output dvalid,
    output [31:0] dout
);
    // local register
    (* ram_style = "block" *) reg [31:0] peram[0:2**L_RAM_SIZE - 1];

    // psum
    reg [31:0] psum;
    initial psum = 0;

    // A*B + C
    floating_point_0 FMA(
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_a_tvalid(valid),
        .s_axis_a_tdata(ain),
        .s_axis_b_tvalid(valid),
        .s_axis_b_tdata(peram[addr]),
        .s_axis_c_tvalid(valid),
        .s_axis_c_tdata(psum),
        .m_axis_result_tvalid(dvalid),
        .m_axis_result_tdata(dout)
    );

    always @(posedge aclk) begin
        if (we) begin
            // we == 1, `din` is stored to `peram[addr]`
            peram[addr] = din;
        end

        if (aresetn == 0) begin
            psum = 0;
        end

        if (dvalid) begin
            psum = psum + dout;
        end
    end
endmodule
