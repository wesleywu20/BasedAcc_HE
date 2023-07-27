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

vlog -reportprogress 300 -work work $path/../hdl/polynomial_multiplier/*.sv
vlog -reportprogress 300 -work work $path/../hdl/fifo/fifo_types.sv
vlog -reportprogress 300 -work work $path/../hdl/fifo/*.sv

vlog -reportprogress 300 -work work $path/../hdl/*.sv

vlog -reportprogress 300 -work work $path/../hvl/relin_tb.sv

vsim -t 1ps -gui -L rtl_work -L work relin_tb

add wave -group {Top} -radix hexadecimal sim:/relin_tb/*
add wave -group {Relin Unit} -radix hexadecimal sim:/relin_tb/dut/*
add wave -group {c0} -radix hexadecimal sim:/relin_tb/dut/relin_unit_c0/*
add wave -group {c1} -radix hexadecimal sim:/relin_tb/dut/relin_unit_c1/*

run -all
