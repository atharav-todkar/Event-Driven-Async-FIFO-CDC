`timescale 1ns/1ps

module cdc_stress_tb;

reg wr_clk = 0;
reg rd_clk = 0;
reg rst = 1;

reg wr_en = 0;
reg rd_en = 0;
reg [7:0] data_in;

wire [7:0] data_out;
wire full, empty;

// DUT
async_fifo_top dut (
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .rst(rst),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .full(full),
    .empty(empty)
);

// Asynchronous clocks
always #5 wr_clk = ~wr_clk;   // 100 MHz
always #7 rd_clk = ~rd_clk;   // ~71 MHz

// Test logic
integer i;
integer error_count = 0;

initial begin
    $display("Starting CDC Stress Test...");
    
    #20 rst = 0;

    for (i = 0; i < 50; i = i + 1) begin
        @(posedge wr_clk);
        wr_en = $random % 2;
        data_in = $random;

        @(posedge rd_clk);
        rd_en = $random % 2;
    end

    #100;

    $display("Test completed");
    $display("Errors: %0d", error_count);

    $finish;
end

endmodule
