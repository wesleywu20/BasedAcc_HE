transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set path [pwd]

vlog -reportprogress 300 -work work $path/../hdl/simple_sub.sv

vlog -reportprogress 300 -work work $path/../hvl/su_tb.sv

vsim -t 1ps -gui -L rtl_work -L work su_tb

run -all
