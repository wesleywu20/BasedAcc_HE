transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

set path [pwd]

vlog -reportprogress 300 -work work $path/../hdl/he_params.sv
vlog -reportprogress 300 -work work $path/../hdl/he_types.sv
vlog -reportprogress 300 -work work $path/../hdl/he_headers.sv

vlog -reportprogress 300 -work work $path/../hdl/fifo/fifo_types.sv
vlog -reportprogress 300 -work work $path/../hdl/fifo/*.sv

vlog -reportprogress 300 -work work $path/../hdl/*.sv

vlog -reportprogress 300 -work work $path/../hvl/poly_mod_tb.sv

vsim -t 1ps -gui -L rtl_work -L work poly_mod_tb

add wave -group {Top} -radix hexadecimal sim:/poly_mod_tb/*
add wave -group {Poly Mod} -radix hexadecimal sim:/poly_mod_tb/dut/*

run -all
