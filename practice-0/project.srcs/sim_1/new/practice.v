`timescale 1ns / 1ps

module practice();
    reg clk, rstn;
    wire clk_output;

    signal_generator UUT(
        .clk(clk),
        .rstn(rstn),
        .clk_output(clk_output)
    );

    initial begin
        clk = 0;
        rstn = 0;
        #7.5;
        rstn = 1;

        #112.5;
        $finish;
    end

    always #5 clk = ~clk;
endmodule

module signal_generator(
    input clk,
    input rstn,
    output clk_output
);
    reg [7:0] posedge_cnt;
    reg rise_pulse_reg, neg_pulse_reg;

    always @(posedge clk or negedge rstn)
        if(!rstn) posedge_cnt <= {8{1'b0}};
        else if(posedge_cnt == 3'b100) posedge_cnt <= {8{1'b0}};
        else posedge_cnt <= posedge_cnt+1;

    always @(posedge clk or negedge rstn)
        if(!rstn) rise_pulse_reg <= 1'b0;
        else if(posedge_cnt == 2'b10) rise_pulse_reg <= 1'b1;
        else if(posedge_cnt == 3'b100) rise_pulse_reg <= 1'b0;

    always @(negedge clk or negedge rstn)
        if(!rstn) neg_pulse_reg <= 1'b0;
        else neg_pulse_reg <= rise_pulse_reg;

    assign clk_output = rise_pulse_reg | neg_pulse_reg;
endmodule
