`timescale 1ns / 1ps

module my_bram #(
    parameter integer BRAM_ADDR_WIDTH = 15, // 2**15 = 4 x 8192
    parameter INIT_FILE = "input.txt",
    parameter OUT_FILE = "output.txt"
) (
    input wire [BRAM_ADDR_WIDTH-1:0] BRAM_ADDR,
    input wire BRAM_CLK,
    input wire [31:0] BRAM_WRDATA,
    output reg [31:0] BRAM_RDDATA,
    input wire BRAM_EN,
    input wire BRAM_RST,
    input wire [3:0] BRAM_WE,
    input wire done
);
    // BRAM Internal Storage
    reg [31:0] mem[0:(1<<(BRAM_ADDR_WIDTH-2))-1];

    // Each external address of which size is 15 bits (i.e., BRAM_ADDR) is
    // associated with 1 byte of data. Last two bits are masked and assigned to
    // internal address of which size is 13 bits (i.e., addr). It is associated
    // with each entry of mem(i.e. it is associated with 4 bytes of data).
    wire [BRAM_ADDR_WIDTH-3:0] addr = BRAM_ADDR[BRAM_ADDR_WIDTH-1:2];

    // TODO
    reg [31:0] dout;

    // code for reading & writing
    integer file;
    initial begin
        if (INIT_FILE != "") begin
            // read data from `INIT_FILE` and store them into `mem`
            $readmemh(INIT_FILE, mem);
        end

        // done == 1, write data stored in mem into `OUT_FILE`
        wait (done) begin
            // write data stored in `mem` into `OUT_FILE`
            $writememh(OUT_FILE, mem);
        end
    end

    // code for BRAM implementation
    always @(posedge BRAM_CLK) begin
        // BRAM_RST == 1, BRAM_RDDATA should print 0
        if (BRAM_RST == 1) begin
            BRAM_RDDATA = 0;
        end

        if (BRAM_EN == 0) begin
            // BRAM_EN == 0, do nothing
        end else begin
            // BRAM_EN == 1, BRAM is available for read or write
            if (BRAM_WE == 0) begin
                // Read mem[addr] into BRAM_RDDATA
                BRAM_RDDATA = mem[addr];

                // TODO: BRAM costs 2 cycles for read (i.e., BRAM returns value
                // after next cycle when you assign address to read data)
            end else begin
                // BRAM_WE[i] == 1, store given data into mem
                if (BRAM_WE[0] == 1) mem[addr][8*(0+1)-1:8*0] = BRAM_WRDATA[8*(0+1)-1:8*0];
                if (BRAM_WE[1] == 1) mem[addr][8*(1+1)-1:8*1] = BRAM_WRDATA[8*(1+1)-1:8*1];
                if (BRAM_WE[2] == 1) mem[addr][8*(2+1)-1:8*2] = BRAM_WRDATA[8*(2+1)-1:8*2];
                if (BRAM_WE[3] == 1) mem[addr][8*(3+1)-1:8*3] = BRAM_WRDATA[8*(3+1)-1:8*3];

                // TODO: BRAM costs 1 cycle for write
            end
        end
    end
endmodule
