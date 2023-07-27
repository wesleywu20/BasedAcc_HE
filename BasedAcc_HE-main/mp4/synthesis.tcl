set target_library [getenv STD_CELL_LIB]
set synthetic_library [list dw_foundation.sldb]
set link_library   [list "*" $target_library $synthetic_library]
set symbol_library [list generic.sdb]

set design_clock_pin clk
set design_reset_pin rst

suppress_message LINT-31
suppress_message LINT-52
suppress_message LINT-28
suppress_message LINT-29
suppress_message LINT-32
suppress_message LINT-33
suppress_message LINT-28
suppress_message LINT-1
suppress_message LINT-99
suppress_message LINT-2

set modules [glob -nocomplain ../pkg/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/fetch/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/execution/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/caches_arbiter_mainmem/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/caches_arbiter_mainmem/d_cache/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}

set modules [glob -nocomplain ../cpu/caches_arbiter_mainmem/i_cache/*.sv]
foreach module $modules {
    puts "analyzing $module"
    analyze -library WORK -format sverilog "${module}"
}


#set clk_name $design_clock_pin
#create_clock -period 10 -name my_clk $clk_name
#set_dont_touch_network [get_clocks my_clk]
#set_fix_hold [get_clocks my_clk]
#set_clock_uncertainty 0.1 [get_clocks my_clk]
#set_ideal_network [get_ports clk]

#set_input_delay 1 [all_inputs] -clock my_clk
#set_output_delay 1 [all_outputs] -clock my_clk
#set_load 0.1 [all_outputs]
#set_max_fanout 1 [all_inputs]
#set_fanout_load 8 [all_outputs]

#link
#compile

#current_design based_cpu

#report_area > area.rpt
#report_timing > timing.rpt

#report_area
#report_timing

elaborate based_cpu
current_design based_cpu
check_design

read_saif -input ../sim/dump.fsdb.saif -instance mp4_tb/dut

set_max_area 500000 -ignore_tns
set clk_name $design_clock_pin
create_clock -period 6.06 -name my_clk $clk_name
set_dont_touch_network [get_clocks my_clk]
set_fix_hold [get_clocks my_clk]
set_clock_uncertainty 0.1 [get_clocks my_clk]
set_ideal_network [get_ports clk]

set_input_delay 1 [all_inputs] -clock my_clk
set_output_delay 1 [all_outputs] -clock my_clk
set_load 0.1 [all_outputs]
set_max_fanout 1 [all_inputs]
set_fanout_load 8 [all_outputs]

link
compile_ultra -no_autoungroup -gate_clock 

current_design based_cpu

report_area -hier > reports/area.rpt
report_timing > reports/timing.rpt
check_design > reports/check.rpt
report_power -analysis_effort high -hierarchy > reports/power.rpt

write_file -format ddc -hierarchy -output synth.ddc
exit




