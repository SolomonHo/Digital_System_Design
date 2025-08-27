set DESIGN "cache_dm"
current_design [get_designs $DESIGN]

read_file -format verilog ${DESIGN}.v
source cache_syn.sdc

compile

#####################################################

report_area         -hierarchy
report_timing       -delay min  -max_path 5
report_timing       -delay max  -max_path 5
report_area         -hierarchy              > ${DESIGN}_syn.area
report_timing       -delay min  -max_path 5 > ${DESIGN}_syn.timing_min
report_timing       -delay max  -max_path 5 > ${DESIGN}_syn.timing_max


write_sdf   -version 2.1            ${DESIGN}_syn.sdf
write -format verilog -hier -output ${DESIGN}_syn.v
write -format ddc -hier -output     ${DESIGN}_syn.ddc










