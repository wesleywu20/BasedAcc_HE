transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set path [pwd]

vlog -reportprogress 300 -work work $path/../hdl/rv32i_mux_types.sv
vlog -reportprogress 300 -work work $path/../hdl/rv32i_types.sv

vlog -reportprogress 300 -work work $path/../hdl/he_params.sv
vlog -reportprogress 300 -work work $path/../hdl/he_types.sv
vlog -reportprogress 300 -work work $path/../hdl/he_headers.sv

vlog -reportprogress 300 -work work $path/../hdl/*.sv

vlog -reportprogress 300 -work work $path/../hvl/accel_tb.sv

vsim -t 1ps -gui -L rtl_work -L work accel_tb

run -all
