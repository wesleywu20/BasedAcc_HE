/*
A simple test case
*/

`timescale 1ns / 1ps

module polynomial_output_loader_tb #(
    parameter DATA_WIDTH = 16,
    parameter POLY_A_TILE_WIDTH = 3,
    parameter POLY_B_TILE_WIDTH = 9,
    parameter POLY_A_WIDTH = 27,
    parameter POLY_B_WIDTH = 27
    )();

    logic clk, rst, tile_ready;
    logic [ (POLY_A_TILE_WIDTH + POLY_B_TILE_WIDTH - 1) - 1 :0][DATA_WIDTH-1:0] adder_tree_outputs;

    initial begin
      #0 clk = 1'b0;
      forever #2.5 clk = ~clk;
    end

  initial begin
    #0 rst = 1'b1;
    #10 rst = 1'b0;
    #15 rst = 1'b1;
   #15 adder_tree_outputs = {{DATA_WIDTH'(1)},{DATA_WIDTH'(2)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(3)},{DATA_WIDTH'(2)},{DATA_WIDTH'(1)}};

   //#15 adder_tree_outputs = {{DATA_WIDTH'(1)},{DATA_WIDTH'(2)},{DATA_WIDTH'(3)},{DATA_WIDTH'(4)},{DATA_WIDTH'(5)},{DATA_WIDTH'(6)},{DATA_WIDTH'(7)},{DATA_WIDTH'(8)},{DATA_WIDTH'(9)},{DATA_WIDTH'(8)},{DATA_WIDTH'(7)},{DATA_WIDTH'(6)},{DATA_WIDTH'(5)},{DATA_WIDTH'(4)},{DATA_WIDTH'(3)},{DATA_WIDTH'(2)},{DATA_WIDTH'(1)}};
   tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

   #15   tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

         #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

         #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;


      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

      #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
     #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;

  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
     #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;
  #15 tile_ready = 1'b1;
   #15 tile_ready = 1'b0;









    #150 $stop;
  end



  // Module under test ==========================================================



polynomial_output_loader #(
    .POLY_A_WIDTH(POLY_A_WIDTH),
    .POLY_B_WIDTH(POLY_B_WIDTH),
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    .POLY_A_TILE_WIDTH(POLY_A_TILE_WIDTH),
    .POLY_B_TILE_WIDTH(POLY_B_TILE_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH)
) loader (
   .clk(clk),
   .rst(rst),
   .tile_ready(tile_ready),
   .adder_tree_outputs(adder_tree_outputs),
   .c_value_outputs(),
   .ready_signal()
);


endmodule
