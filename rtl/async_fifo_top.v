module async_fifo_top #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  full,
    output wire                  empty
);
    wire [ADDR_WIDTH:0] wr_bin;
    wire [ADDR_WIDTH:0] wr_gray;
    wire [ADDR_WIDTH:0] rd_bin;
    wire [ADDR_WIDTH:0] rd_gray;
    wire [ADDR_WIDTH:0] wr_gray_sync;
    wire [ADDR_WIDTH:0] rd_gray_sync;

    wire wr_en_safe = wr_en & ~full;
    wire rd_en_safe = rd_en & ~empty;

    fifo_mem #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) fifo_memory (
        .wr_clk (wr_clk),
        .wr_en  (wr_en_safe),
        .wr_addr(wr_bin[ADDR_WIDTH-1:0]),
        .wr_data(wr_data),
        .rd_clk (rd_clk),
        .rd_addr(rd_bin[ADDR_WIDTH-1:0]),
        .rd_data(rd_data)
    );

    wr_ptr_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_ctrl (
        .wr_clk      (wr_clk),
        .wr_rst      (wr_rst),
        .wr_en       (wr_en_safe),
        .rd_gray_sync(rd_gray_sync),
        .wr_bin      (wr_bin),
        .wr_gray     (wr_gray),
        .full        (full)
    );

    rd_ptr_ctrl #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_ctrl (
        .rd_clk      (rd_clk),
        .rd_rst      (rd_rst),
        .rd_en       (rd_en_safe),
        .wr_gray_sync(wr_gray_sync),
        .rd_bin      (rd_bin),
        .rd_gray     (rd_gray),
        .empty       (empty)
    );

    gray_sync #(
        .WIDTH(ADDR_WIDTH+1)
    ) sync_wr_ptr (
        .clk     (rd_clk),
        .rst     (rd_rst),
        .gray_in (wr_gray),
        .gray_out(wr_gray_sync)
    );

    gray_sync #(
        .WIDTH(ADDR_WIDTH+1)
    ) sync_rd_ptr (
        .clk     (wr_clk),
        .rst     (wr_rst),
        .gray_in (rd_gray),
        .gray_out(rd_gray_sync)
    );

endmodule
