sh mkdir -p Netlist
sh mkdir -p Report



read_verilog core.v
read_verilog CHIP.v
read_verilog memory.v

set DESIGN "CHIP"
current_design [get_designs $DESIGN]

#You may modified the clock constraints 
#or add more constraints for your design
####################################################
set cycle  2.62
####################################################

#The following are design spec. for synthesis
#You can NOT modify this seciton 
#####################################################
create_clock -name CLK -period $cycle [get_ports clk]
set_fix_hold                          [get_clocks CLK]
set_dont_touch_network                [get_clocks CLK]
set_ideal_network                     [get_ports clk]
set_clock_uncertainty            0.1  [get_clocks CLK] 
set_clock_latency                0.5  [get_clocks CLK] 

set_max_fanout 6 [all_inputs] 


set_operating_conditions -min_library fast -min fast -max_library slow -max slow
set_wire_load_model -name tsmc13_wl10 -library slow  
set_drive        1     [all_inputs]
# set_load         1     [all_outputs]
set t_in  0.1
# set_dont_touch mem_I
# set_dont_touch mem_D
set_dont_touch [get_designs memory]
set_input_delay  $t_in  -clock CLK [get_ports rst_n]
# set_output_delay $t_out -clock CLK [all_outputs]

#####################################################


#Compile and save files
#You may modified setting of compile 


# # 2.52
# set_ungroup [get_cells core0] false
# compile_ultra -timing_high_effort_script

# # 2.83
# compile 
compile_ultra -no_autoungroup
#####################################################
set bus_inference_style {%s[%d]}
set bus_naming_style    {%s[%d]}
set hdlout_internal_buses  true
change_names    -hierarchy  -rule verilog
define_name_rules name_rule -allowed {a-z A-Z 0-9 _}    -max_length 255 -type cell
define_name_rules name_rule -allowed {a-z A-Z 0-9 _[]}  -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
define_name_rules name_rule -case_insensitive
change_names    -hierarchy  -rules name_rule
set verilogout_no_tri   true

report_area         -hierarchy
report_timing       -delay min  -max_path 5
report_timing       -delay max  -max_path 5
report_area         -hierarchy              > ./Report/${DESIGN}_syn.area
report_timing       -delay min  -max_path 5 > ./Report/${DESIGN}_syn.timing_min
report_timing       -delay max  -max_path 5 > ./Report/${DESIGN}_syn.timing_max


set verilogout_higher_designs_first true
write   -f ddc      -hierarchy  -output ./Netlist/${DESIGN}_syn.ddc
write   -f verilog  -hierarchy  -output ./Netlist/${DESIGN}_syn.v
write_sdf   -version 2.1                ./Netlist/${DESIGN}_syn.sdf
write_sdc   -version 1.8                ./Netlist/${DESIGN}_syn.sdc


#####################################################
# in the TB, we directly access the memory.mem
# to avoid dc from outputting unformatted memory module, we need to remove_design
# when simulation, we read the original memory.v as the memory module inference
remove_design memory
write   -f verilog  -hierarchy  -output ./Netlist/${DESIGN}_syn.v
#####################################################  

# restore the memory design for further improvement if needed (remember to remove the memory design before writing verilog)
read_ddc ./Netlist/${DESIGN}_syn.ddc









