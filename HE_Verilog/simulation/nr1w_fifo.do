transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set path [pwd]

vlog -reportprogress 300 -work work $path/../hdl/fifo/fifo_types.sv
vlog -reportprogress 300 -work work $path/../hdl/fifo/*.sv

vlog -reportprogress 300 -work work $path/../hvl/nr1w_fifo_tb.sv

vsim -t 1ps -gui -L rtl_work -L work nr1w_fifo_tb

run -all
