`timescale 1ns / 1ps

module one_sec_checker(
    input GCLK, // 100MHz
    input BTNC, // Centor Button
    output [7:0] LD
);
    reg [7:0] seconds;
    initial seconds = 0;

    reg [27:0] ten_nanoseconds;
    initial ten_nanoseconds = 0;

    always @(posedge GCLK) begin
        if (BTNC) begin
            // Reset enabled
            seconds = 0;
            ten_nanoseconds = 0;

        end else begin
            // No reset
            ten_nanoseconds = ten_nanoseconds + 1;
            if (ten_nanoseconds == 100_000_000) begin
                ten_nanoseconds = 0;
                seconds = seconds + 1;
            end
        end
    end

    assign LD = seconds;
endmodule
