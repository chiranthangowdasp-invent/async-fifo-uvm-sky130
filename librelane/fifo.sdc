create_clock -name wclk -period 10.0 [get_ports wclk]
create_clock -name rclk -period 13.0 [get_ports rclk]

set_clock_groups -asynchronous -group [get_clocks wclk] -group [get_clocks rclk]

set_input_delay  2.0 -clock [get_clocks wclk] [get_ports {winc wdata[*] wrst_n}]
set_input_delay  2.0 -clock [get_clocks rclk] [get_ports {rinc rrst_n}]
set_output_delay 2.0 -clock [get_clocks wclk] [get_ports wfull]
set_output_delay 2.0 -clock [get_clocks rclk] [get_ports {rdata[*] rempty}]
