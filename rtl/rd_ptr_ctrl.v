module rd_ptr_ctrl #(
    parameter ADDR_WIDTH = 3
)(
    input  wire                rd_clk,
    input  wire                rd_rst,
    input  wire                rd_en,
    input  wire [ADDR_WIDTH:0] wr_gray_sync,
    output reg  [ADDR_WIDTH:0] rd_bin,
    output reg  [ADDR_WIDTH:0] rd_gray,
    output wire                empty
);
    wire [ADDR_WIDTH:0] rd_bin_next;
    wire [ADDR_WIDTH:0] rd_gray_next;

    assign rd_bin_next  = rd_bin + (rd_en & ~empty);
    assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    assign empty = (rd_gray_next == wr_gray_sync);

    always @(posedge rd_clk or posedge rd_rst) begin
        if (rd_rst) begin
            rd_bin  <= 0;
            rd_gray <= 0;
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
        end
    end

endmodule
