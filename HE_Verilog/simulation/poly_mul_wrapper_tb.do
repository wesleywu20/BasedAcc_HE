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

vlog -reportprogress 300 -work work $path/../hvl/poly_mul_wrapper_tb.sv

vsim -t 1ps -gui -L rtl_work -L work poly_mul_wrapper_tb

add wave -group {Top} -radix hexadecimal sim:/poly_mul_wrapper_tb/*
add wave -group {Datapath} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/*
add wave -group {Multi FIFO} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/poly_mul_output/*
add wave -group {Recon} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/recon_unit/*
add wave -group {Poly Mod} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/poly_mod/*
add wave -group {Poly Mod} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/relin_input_fifo/*
add wave -group {Poly Mod} -radix hexadecimal sim:/poly_mul_wrapper_tb/dut/relin_unit/*

run -all
