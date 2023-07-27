`ifndef polymult_tb
`define polymult_tb

`timescale 1ns / 1ps

module polymult_tb #(
    parameter DATA_WIDTH = 64,
    parameter POLY_A_TILE_WIDTH = 8,
    parameter POLY_B_TILE_WIDTH = 8,
    parameter POLY_A_WIDTH = 64,
    parameter POLY_B_WIDTH = 64
) (polymult_itf.testbench itf);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, polymult_tb, "+all");
end

// Design under test ==========================================================
poly_mult_top #(
    .POLY_A_WIDTH(POLY_A_WIDTH),
    .POLY_B_WIDTH(POLY_B_WIDTH),
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    .POLY_A_TILE_WIDTH(POLY_A_TILE_WIDTH),
    .POLY_B_TILE_WIDTH(POLY_B_TILE_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH)
) dut
(
    .clk(itf.clk),
    .rst(itf.rst),
    .inputs_ready_signal(itf.inputs_ready_signal),
    .tile_a(itf.tile_a),
    .tile_b(itf.tile_b),
    .c_value_outputs(itf.c_value_outputs),
    .outputs_ready_signal(itf.outputs_ready_signal),
    .done()
);

default clocking tb_clk @(negedge itf.clk); endclocking

  initial begin
    ##(0); 
    itf.rst <= 1'b1;
    ##(10); 
    itf.rst <= 1'b0;
    ##(15); 
    itf.rst <= 1'b1;

    // ##20    inputs = {16'd33, 16'd2, 16'd8, 16'd14, 16'd19, 16'd5, 16'd4, 16'd7};
    ##(20);    
    itf.tile_a <= {64'd1,64'd1,64'd1,64'd1,64'd1,64'd1,64'd1,64'd1};
    itf.tile_b <= {64'd1,64'd1,64'd1,64'd1,64'd1,64'd1,64'd1,64'd1};
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
    ##(0); 
    itf.rst <= 1'b1;
    ##(10); 
    itf.rst <= 1'b0;
    ##(15); 
    itf.rst <= 1'b1;
    
    ##(5); 
    itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
 
    ##(5); 
    itf.inputs_ready_signal <= 0;
    ##(12.5); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
    ##(0); 
    itf.rst <= 1'b1;
    ##(10); 
    itf.rst <= 1'b0;
    ##(15); 
    itf.rst <= 1'b1;

    ##(30); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;

    ##(50); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
        ##(50); 
        itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
  
    ##(20); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
        ##(5); 
        itf.inputs_ready_signal <= 0;
    ##(20); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;

    ##(30); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;

    ##(50); 
    itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;
        ##(50); 
        itf.inputs_ready_signal <= 1;
    ##(5); 
    itf.inputs_ready_signal <= 0;

    ##(30); 
    itf.inputs_ready_signal <= 1;
    itf.finish();
  end

endmodule : polymult_tb
`endif