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

    // Each external address of which size is 15 bits (i.e., BRAM_ADDR) is
    // associated with 1 byte of data. Last two bits are masked and assigned to
    // internal address of which size is 13 bits (i.e., addr). It is associated
    // with each entry of mem(i.e. it is associated with 4 bytes of data).
    wire [BRAM_ADDR_WIDTH-3:0] addr = BRAM_ADDR[BRAM_ADDR_WIDTH-1:2];

    // Read Queue of length 2. Oldest: 0, Newest: 1
    //
    // BRAM costs 2 cycles for read (i.e., BRAM returns value after
    // next cycle when you assign address to read data)
    reg [31:0] read_q[0:1];

    // Write Queue of length 1
    //
    // BRAM costs 1 cycle for write
    reg [3:0] write_q_enable;
    reg [BRAM_ADDR_WIDTH-3:0] write_q_addr;
    reg [7:0] write_q_part[0:3];

    // code for BRAM implementation
    always @(posedge BRAM_CLK) begin
        // BRAM_RST == 1, BRAM_RDDATA should print 0
        if (BRAM_RST == 1) begin
            BRAM_RDDATA = 0;
        end

        // Process delayed read: Read mem[addr] into BRAM_RDDATA
        BRAM_RDDATA = read_q[0];
        // Process delayed write: Store given data into mem
        if (write_q_enable[0] == 1) mem[write_q_addr][8*1 - 1:8*0] = write_q_part[0];
        if (write_q_enable[1] == 1) mem[write_q_addr][8*2 - 1:8*1] = write_q_part[1];
        if (write_q_enable[2] == 1) mem[write_q_addr][8*3 - 1:8*2] = write_q_part[2];
        if (write_q_enable[3] == 1) mem[write_q_addr][8*4 - 1:8*3] = write_q_part[3];

        // Advance read queue
        read_q[0] = read_q[1];
        // Advance write queue (nothing to do)

        // Enqueue new command if BRAM_EN is true
        if (BRAM_EN) begin
            if (BRAM_WE == 0) begin
                read_q[1] = mem[addr];
            end else begin
                write_q_enable = BRAM_WE;
                write_q_addr = addr;
                write_q_part[0] = BRAM_WRDATA[8*1 - 1:8*0];
                write_q_part[1] = BRAM_WRDATA[8*2 - 1:8*1];
                write_q_part[2] = BRAM_WRDATA[8*3 - 1:8*2];
                write_q_part[3] = BRAM_WRDATA[8*4 - 1:8*3];
            end
        end
    end
endmodule
