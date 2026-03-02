current_design $::env(DESIGN_NAME)
set_units -time ns

set_max_fanout $::env(MAX_FANOUT_CONSTRAINT) [current_design]
if { [info exists ::env(MAX_TRANSITION_CONSTRAINT)] } {
    set_max_transition $::env(MAX_TRANSITION_CONSTRAINT) [current_design]
}
if { [info exists ::env(MAX_CAPACITANCE_CONSTRAINT)] } {
    set_max_capacitance $::env(MAX_CAPACITANCE_CONSTRAINT) [current_design]
}

##################
## Input Clocks ##
##################
puts "Clocks..."

# System Clock
set TCK_SYS 20.0
create_clock -name clk_sys -period $TCK_SYS [get_ports clk_i]

set input_clk_sys_delay_value [expr $TCK_SYS * $::env(IO_DELAY_CONSTRAINT) / 100]
set output_clk_sys_delay_value [expr $TCK_SYS * $::env(IO_DELAY_CONSTRAINT) / 100]
puts "\[INFO] Setting clk_sys output delay to: $input_clk_sys_delay_value"
puts "\[INFO] Setting clk_sys input delay to: $output_clk_sys_delay_value"

# JTAG Clock
set TCK_JTG 25.0
create_clock -name clk_jtg -period $TCK_JTG [get_ports jtag_inputs_PAD[0]]

set input_clk_jtg_delay_value [expr $TCK_JTG * $::env(IO_DELAY_CONSTRAINT) / 100]
set output_clk_jtg_delay_value [expr $TCK_JTG * $::env(IO_DELAY_CONSTRAINT) / 100]
puts "\[INFO] Setting clk_jtg output delay to: $input_clk_jtg_delay_value"
puts "\[INFO] Setting clk_jtg input delay to: $output_clk_jtg_delay_value"

# REF Clock
set TCK_RTC 50.0
create_clock -name clk_rtc -period $TCK_RTC [get_ports ref_clk_i]


##################################
## Clock Groups & Uncertainties ##
##################################

# Define which clocks are asynchronous to each other
# If you have added a clock it is a good idea to temporarily add -allow_paths.
# This means the paths between clocks (CDC) are timed and will show up as violations,
# making them very easy to find and write constraints for.
set_clock_groups -asynchronous -name clk_groups_async \
     -group {clk_rtc} \
     -group {clk_jtg} \
     -group {clk_sys}




#########
## RST ##
#########
puts "RST..."

# Input-only pads
set clk_rst_input_ports [get_ports { 
    rst_ni
}]

set_input_delay -min 0 -clock clk_sys $clk_rst_input_ports
set_input_delay -max $input_clk_sys_delay_value -clock clk_sys $clk_rst_input_ports

##########
## JTAG ##
##########
puts "JTAG..."

# Input-only pads
set clk_jtag_input_ports [get_ports { 
    jtag_inputs_PAD[1]
    jtag_inputs_PAD[2]
    jtag_inputs_PAD[3]
}]

set_input_delay -min 0 -clock clk_jtg $clk_jtag_input_ports
set_input_delay -max $input_clk_jtg_delay_value -clock clk_jtg $clk_jtag_input_ports

# Output-only pads
set clk_jtag_output_ports [get_ports { 
    jtag_tdo_o
}] 

set_output_delay $output_clk_jtg_delay_value -clock clk_jtg $clk_jtag_output_ports

##########
## GPIO ##
##########
puts "GPIO..."

# Input-only pads
set clk_core_input_ports [get_ports { 
    fetch_en_i
}] 

set_input_delay -min 0 -clock clk_sys $clk_core_input_ports
set_input_delay -max $input_clk_sys_delay_value -clock clk_sys $clk_core_input_ports

# Output-only pads
set clk_core_output_ports [get_ports { 
    status_o
    unused_o[*]
}] 

set_output_delay $output_clk_sys_delay_value -clock clk_sys $clk_core_output_ports

# Bidirectional pads
set clk_core_inout_ports [get_ports { 
    gpio_io[*]
}] 

set_input_delay -min 0 -clock clk_sys $clk_core_inout_ports
set_input_delay -max $input_clk_sys_delay_value -clock clk_sys $clk_core_inout_ports
set_output_delay $output_clk_sys_delay_value -clock clk_sys $clk_core_inout_ports

##########
## UART ##
##########
puts "UART..."

# Input-only pads
set clk_uart_input_ports [get_ports { 
    uart_rx_i
}] 

set_input_delay -min 0 -clock clk_sys $clk_uart_input_ports
set_input_delay -max $input_clk_sys_delay_value -clock clk_sys $clk_uart_input_ports

# Output-only pads
set clk_uart_output_ports [get_ports { 
    uart_tx_o
}] 

set_output_delay $output_clk_sys_delay_value -clock clk_sys $clk_uart_output_ports


##########
## LOAD ##
##########

set cap_load [expr $::env(OUTPUT_CAP_LOAD) / 1000.0]
puts "\[INFO] Setting load to: $cap_load"
set_load $cap_load [all_outputs]

puts "\[INFO] Setting clock uncertainty to: $::env(CLOCK_UNCERTAINTY_CONSTRAINT)"
set_clock_uncertainty $::env(CLOCK_UNCERTAINTY_CONSTRAINT) [all_clocks]

puts "\[INFO] Setting clock transition to: $::env(CLOCK_TRANSITION_CONSTRAINT)"
set_clock_transition $::env(CLOCK_TRANSITION_CONSTRAINT) [all_clocks]

puts "\[INFO] Setting timing derate to: $::env(TIME_DERATING_CONSTRAINT)%"
set_timing_derate -early [expr 1-[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]
set_timing_derate -late [expr 1+[expr $::env(TIME_DERATING_CONSTRAINT) / 100]]