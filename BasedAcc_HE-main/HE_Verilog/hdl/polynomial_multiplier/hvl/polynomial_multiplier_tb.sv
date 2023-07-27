/*
A simple test case
*/

`timescale 1ns / 1ps

module polynomial_multiplier_tb #(
    parameter DATA_WIDTH = 64,
    parameter POLY_A_TILE_WIDTH = 4,
    parameter POLY_B_TILE_WIDTH = 4,
    parameter POLY_A_WIDTH = 16,
    parameter POLY_B_WIDTH = 16
    )();

  logic clk, reset, inputs_ready, done, outputs_ready_signal;
  logic [POLY_A_TILE_WIDTH-1:0][DATA_WIDTH-1:0]inputs ;
  logic [POLY_A_TILE_WIDTH+POLY_B_TILE_WIDTH-1-1:0][DATA_WIDTH-1:0]outputs ;
  logic [POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] c_value_outputs ;
  logic [7:0][ POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0]finished_c_intermediates, c_value_outputs_segment;
  logic [ POLY_B_TILE_WIDTH - 1:0][7:0][DATA_WIDTH-1:0] tree_value_inputs;
  initial begin
    #0 clk = 1'b0;
    forever #2.5 clk = ~clk;
  end

  initial begin
    #0 reset = 1'b1;
    #10 reset = 1'b0;
    #15 reset = 1'b1;

    // #20    inputs = {16'd33, 16'd2, 16'd8, 16'd14, 16'd19, 16'd5, 16'd4, 16'd7};
    #20    inputs = {64'd1, 64'd1, 64'd1, 64'd1, 64'd1, 64'd1, 64'd1, 64'd1};
    inputs_ready = 1;
    // #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    // #0 reset = 1'b1;
    // #10 reset = 1'b0;
    // #15 reset = 1'b1;
    
    // #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
 
    #5 inputs_ready = 0;
    #12.5 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;


    // #30 inputs_ready = 1;
    // #5 inputs_ready = 0;



    // #50 inputs_ready = 1;
    // #5 inputs_ready = 0;
    //     #50 inputs_ready = 1;
    // #5 inputs_ready = 0;


  
    // #20 inputs_ready = 1;
    // #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    // #5 inputs_ready = 0;

    // #30 inputs_ready = 1;
    // #5 inputs_ready = 0;



    // #50 inputs_ready = 1;
    // #5 inputs_ready = 0;
    //     #50 inputs_ready = 1;
    // #5 inputs_ready = 0;

<<<<<<< HEAD
    #30 inputs_ready = 1;
        #20 inputs_ready = 1;

    
    #5 inputs_ready = 0;
    #20 inputs_ready = 1;
 
    #5 inputs_ready = 0;
    #12.5 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;

    #30 inputs_ready = 1;
    #5 inputs_ready = 0;



    #50 inputs_ready = 1;
    #5 inputs_ready = 0;
        #50 inputs_ready = 1;
    #5 inputs_ready = 0;


  
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
        #5 inputs_ready = 0;
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;

    #30 inputs_ready = 1;
    #5 inputs_ready = 0;



    #50 inputs_ready = 1;
    #5 inputs_ready = 0;
        #50 inputs_ready = 1;
    #5 inputs_ready = 0;

    #30 inputs_ready = 1;
=======
    // #30 inputs_ready = 1;
    //     #20 inputs_ready = 1;

    
    // #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
 
    // #5 inputs_ready = 0;
    // #12.5 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    // #5 inputs_ready = 0;

    // #30 inputs_ready = 1;
    // #5 inputs_ready = 0;



    // #50 inputs_ready = 1;
    // #5 inputs_ready = 0;
    //     #50 inputs_ready = 1;
    // #5 inputs_ready = 0;


  
    // #20 inputs_ready = 1;
    // #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    //     #5 inputs_ready = 0;
    // #20 inputs_ready = 1;
    // #5 inputs_ready = 0;

    // #30 inputs_ready = 1;
    // #5 inputs_ready = 0;



    // #50 inputs_ready = 1;
    // #5 inputs_ready = 0;
    //     #50 inputs_ready = 1;
    // #5 inputs_ready = 0;

    // #30 inputs_ready = 1;
>>>>>>> main
    #1400 $stop;
  end



  // Module under test ==========================================================


poly_mult_top #(
    .POLY_A_WIDTH(POLY_A_WIDTH),
    .POLY_B_WIDTH(POLY_B_WIDTH),
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    .POLY_A_TILE_WIDTH(POLY_A_TILE_WIDTH),
    .POLY_B_TILE_WIDTH(POLY_B_TILE_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH)
) mult
(
    .clk(clk),
    .rst(reset),
    .inputs_ready_signal(inputs_ready),
    .tile_a(inputs),
    .tile_b(inputs),
   .c_value_outputs(c_value_outputs),
   .outputs_ready_signal(outputs_ready_signal),
   .done()
);






endmodule
