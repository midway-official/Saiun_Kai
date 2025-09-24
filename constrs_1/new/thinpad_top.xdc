
#-----------------------差分系统时钟引脚约束-------------------
set_property PACKAGE_PIN T25 [get_ports c0_sys_clk_p]
set_property PACKAGE_PIN U25 [get_ports c0_sys_clk_n]
set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_p]
set_property IOSTANDARD DIFF_SSTL12 [get_ports c0_sys_clk_n]

#-----------------------RESET--------------------------------
set_property PACKAGE_PIN M25 [get_ports reset_btn_n]
set_property IOSTANDARD LVCMOS12 [get_ports reset_btn_n]

#-----------------------UART串口-----------------------------
set_property PACKAGE_PIN A10 [get_ports txd]
set_property PACKAGE_PIN A9 [get_ports rxd]
set_property IOSTANDARD LVCMOS33 [get_ports txd]
set_property IOSTANDARD LVCMOS33 [get_ports rxd]
