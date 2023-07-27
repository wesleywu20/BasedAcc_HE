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

vlog -reportprogress 300 -work work $path/../hvl/datapath_verification_tb.sv

vsim -t 1ps -gui -L rtl_work -L work datapath_verification_tb

add wave -group {Top} -radix hexadecimal sim:/datapath_verification_tb/*
add wave -group {Datapath} -radix hexadecimal sim:/datapath_verification_tb/dut/*
add wave -group {Relin Unit} -radix hexadecimal sim:/datapath_verification_tb/dut/relin_unit/*

run -all
