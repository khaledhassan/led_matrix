## Generated SDC file "matrix_driver.sdc"

## Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 16.0.0 Build 211 04/27/2016 SJ Lite Edition"

## DATE    "Sat Jun 04 20:39:07 2016"

##
## DEVICE  "EP4CE22F17C6"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_osc} -period 20.000 -waveform { 0.000 5.000 } [get_ports {clk_osc}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {clocks_pll_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 1 -master_clock {clk_osc} [get_pins {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {clocks_pll_inst|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50/1 -multiply_by 1 -divide_by 5 -master_clock {clk_osc} [get_pins {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {clocks_pll_inst|altpll_component|auto_generated|pll1|clk[0]}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************



#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

