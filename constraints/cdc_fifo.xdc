# Write clock (100 MHz)
create_clock -name wr_clk -period 10 [get_ports wr_clk]

# Read clock (~71 MHz)
create_clock -name rd_clk -period 14 [get_ports rd_clk]

# Declare asynchronous clock domains (VERY IMPORTANT)
set_clock_groups -asynchronous \
-group [get_clocks wr_clk] \
-group [get_clocks rd_clk]
