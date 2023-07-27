

`resetall
`timescale 1ns/10ps

module poly_mult_top #(
    parameter POLY_A_WIDTH = 128,
    parameter POLY_B_WIDTH = 128,
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    parameter POLY_A_TILE_WIDTH = 8,
    parameter POLY_B_TILE_WIDTH = 8, 
    parameter DATA_WIDTH = 64
)
(
    input logic                                             clk,
    input logic                                             rst,
    input logic                                             inputs_ready_signal,
    input logic [POLY_A_TILE_WIDTH-1:0][DATA_WIDTH-1:0]     tile_a,
    input logic [POLY_B_TILE_WIDTH-1:0][DATA_WIDTH-1:0]     tile_b,
    output logic [ POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] c_value_outputs, //finished c values
    output logic                                            outputs_ready_signal, //high when c_value_outputs has valid values to output
    output logic                                            done,
    output logic                                            ready_for_tile,
    output logic                                            relin_done,
    output logic [$clog2(POLY_A_WIDTH + POLY_B_WIDTH)-1:0] output_value_index
);

  logic intermediate_outputs_ready;
  logic [POLY_A_TILE_WIDTH+POLY_B_TILE_WIDTH-1-1:0][DATA_WIDTH-1:0]intermediate_outputs ;

   polynomial_multiplier #(
      .MULTIPLIER_WIDTH(POLY_A_TILE_WIDTH),
      .INPUT_WIDTH(DATA_WIDTH)
  ) ac (
      .clk(clk),
      .reset(rst),
      .start(inputs_ready_signal),
      .as(tile_a),
      .bs(tile_b),
      .carry(),
      .cs(intermediate_outputs),
      .done(intermediate_outputs_ready)

  );

   assign ready_for_tile = intermediate_outputs_ready;

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
   .tile_ready(intermediate_outputs_ready),
   .adder_tree_outputs(intermediate_outputs),
   .c_value_outputs(c_value_outputs),
   .ready_signal(outputs_ready_signal),
   .done(done),
   .relin_done(relin_done),
   .output_value_index(output_value_index)
);
endmodule
