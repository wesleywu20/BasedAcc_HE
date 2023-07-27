/*
A simple test case
*/

`timescale 1ns / 1ps

module relin_tb #(
    parameter DATA_WIDTH = 64,
    parameter POLY_A_TILE_WIDTH = 8,
    parameter POLY_B_TILE_WIDTH = 8,
    parameter POLY_A_WIDTH = 512,
    parameter POLY_B_WIDTH = 512
    )();

  logic clk, reset, inputs_ready, done, outputs_ready_signal;
  logic [POLY_A_TILE_WIDTH-1:0][DATA_WIDTH-1:0]inputs ;
  logic [POLY_A_TILE_WIDTH+POLY_B_TILE_WIDTH-1-1:0][DATA_WIDTH-1:0]outputs ;
  logic [POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0] c_value_outputs ;
  logic [7:0][ POLY_B_TILE_WIDTH - 1:0][DATA_WIDTH-1:0]finished_c_intermediates, c_value_outputs_segment;
  logic [ POLY_B_TILE_WIDTH - 1:0][7:0][DATA_WIDTH-1:0] tree_value_inputs;
  logic [64:0] fifo_scale ;
  logic dequeue;
  initial begin
    #0 clk = 1'b0;
    forever #2.5 clk = ~clk;
  end

  initial begin
    #0 reset = 1'b1;
    #10 reset = 1'b0;
    #15 reset = 1'b1;
    // #20    inputs = {16'd33, 16'd2, 16'd8, 16'd14, 16'd19, 16'd5, 16'd4, 16'd7};
    #20 inputs_ready = 1;
    #5 inputs_ready = 0;
    #80 inputs_ready = 1;
    // #5 inputs_ready = 0;
    // #520 inputs_ready = 1;
    // #5 inputs_ready = 0;
    #40000 $stop;
    // #40000 reset = 1'b1;
    // #10 reset = 1'b0;
    // #15 reset = 1'b1;
  end



  // Module under test ==========================================================



relin_unit #(
    .NUMBER_OF_RELIN_KEYS(POLY_A_WIDTH),
    .C2_WIDTH(POLY_B_WIDTH),
    // POLY_A_TILE_WIDTH and POLY_B_TILE_WIDTH need to be divisible by each other
    .RELIN_KEYS_TILE_WIDTH(POLY_A_TILE_WIDTH),
    .C2_TILE_WIDTH(POLY_B_TILE_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH),
    .NUM_RELIN_KEYS(8)
) base_t_decomp_unit
(
    .clk(clk),
    .rst(reset),
    .inputs_ready_signal(inputs_ready),
    .c1_or_c0(0),
    .poly_mult_outputs(inputs),
    .output_value(),
    .outputs_ready_signal(),
    .dequeue(dequeue),
    .done()
);

    genvar c_value;
    generate
        for ( c_value = 0; c_value < POLY_A_TILE_WIDTH; c_value = c_value + 1 )
            begin  
                assign inputs[c_value] = fifo_scale * c_value +1;
            end
    endgenerate

    always_ff@(posedge clk, negedge reset) begin
        if (~reset) begin
            fifo_scale <= 1;
        end
        else if (dequeue) begin
            fifo_scale <= fifo_scale + 1;
        end else begin
            fifo_scale <= fifo_scale;
        end
    end

// relin_key_loader #(
//     .RELIN_KEY_TILE_WIDTH(8),
//     .RELIN_KEY_LENGTH(64),
//     .NUM_MULTIPLIERS(8)
// ) relin (
//     .clk(clk),
//     .reset(reset),
//     .request_signal(inputs_ready),
//     .c1_or_c0(0),
//     .valid_address(),
//     .address(),
//     .request_new_input(),
//     .relin_key()
// );



endmodule