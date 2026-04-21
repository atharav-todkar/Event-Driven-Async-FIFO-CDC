module wr_ptr_ctrl #(
    parameter ADDR_WIDTH = 3
)(
    input  wire                wr_clk,
    input  wire                wr_rst,
    input  wire                wr_en,
    input  wire [ADDR_WIDTH:0] rd_gray_sync,
    output reg  [ADDR_WIDTH:0] wr_bin,
    output reg  [ADDR_WIDTH:0] wr_gray,
    output wire                full
);
    wire [ADDR_WIDTH:0] wr_bin_next;
    wire [ADDR_WIDTH:0] wr_gray_next;

    assign wr_bin_next  = wr_bin + (wr_en & ~full);
    assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;

    assign full = (wr_gray_next ==
                  {~rd_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                    rd_gray_sync[ADDR_WIDTH-2:0]});

    always @(posedge wr_clk or posedge wr_rst) begin
        if (wr_rst) begin
            wr_bin  <= 0;
            wr_gray <= 0;
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

endmodule
