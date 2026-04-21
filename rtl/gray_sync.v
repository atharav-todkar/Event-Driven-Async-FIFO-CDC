module gray_sync #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire [WIDTH-1:0] gray_in,
    output reg  [WIDTH-1:0] gray_out
);
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync1;
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] sync2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync1    <= {WIDTH{1'b0}};
            sync2    <= {WIDTH{1'b0}};
            gray_out <= {WIDTH{1'b0}};
        end else begin
            sync1    <= gray_in;
            sync2    <= sync1;
            gray_out <= sync2;
        end
    end

endmodule
