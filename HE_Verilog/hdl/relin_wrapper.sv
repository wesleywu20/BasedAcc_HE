`include "he_headers.sv"

module relin_wrapper
  (
   input logic                                             clk,
   input logic                                             rst,
   input logic                                             valid_i,
   input logic [`TILE_N-1:0][`BIT_WIDTH-1:0]               coeff_i,
   input logic [1:0][`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file,
   output logic [`TILE_N-1:0][`BIT_WIDTH-1:0]              c0_coeff_o,
   output logic [`TILE_N-1:0][`BIT_WIDTH-1:0]              c1_coeff_o,
   output logic                                            valid_o,
   output logic                                            ready_o
   );

   logic                                                   c0_valid_o, c0_ready_o, c1_valid_o, c1_ready_o;
   assign valid_o = c0_valid_o | c1_valid_o;
   assign ready_o = c0_ready_o & c1_ready_o;

    relin_unit #(.DATA_WIDTH(`BIT_WIDTH), .RELIN_KEYS_TILE_WIDTH(`TILE_N), .C2_TILE_WIDTH(`TILE_N),
                 .DEGREE_OF_RELIN_KEYS(`DEGREE_N), .C2_WIDTH(`DEGREE_N), .NUM_RELIN_KEYS(`L_+1), .MOD_VALUE(`_Q))
    relin_unit_c0
        (
        .clk(clk),
        .rst(rst),
        .valid_i(valid_i),
        .key_select_i(1'b0),
        .coeff_i(coeff_i),
        .relin_key_register_file(relin_key_register_file),
        .coeff_o(c0_coeff_o),
        .valid_o(c0_valid_o),
        .ready_o(c0_ready_o),
        .done()
        );

   relin_unit #(.DATA_WIDTH(`BIT_WIDTH), .RELIN_KEYS_TILE_WIDTH(`TILE_N), .C2_TILE_WIDTH(`TILE_N),
                .DEGREE_OF_RELIN_KEYS(`DEGREE_N), .C2_WIDTH(`DEGREE_N), .NUM_RELIN_KEYS(`L_+1), .MOD_VALUE(`_Q))
   relin_unit_c1
     (
      .clk(clk),
      .rst(rst),
      .valid_i(valid_i),
      .key_select_i(1'b1),
      .coeff_i(coeff_i),
      .relin_key_register_file(relin_key_register_file),
      .coeff_o(c1_coeff_o),
      .valid_o(c1_valid_o),
      .ready_o(c1_ready_o),
      .done()
      );



  //   relin_passthrough 
  //   relin_unit_c0
  //       (
  //       .clk(clk),
  //       .rst(rst),
  //       .valid_i(valid_i),
  //       .coeff_i(coeff_i),
  //       .key_select_i(1'b0),
  //       .relin_key_register_file(relin_key_register_file),
  //       .coeff_o(c0_coeff_o),
  //       .valid_o(c0_valid_o),
  //       .ready_o(c0_ready_o)
  //       );

  //  relin_passthrough
  //  relin_unit_c1
  //    (
  //     .clk(clk),
  //     .rst(rst),
  //     .valid_i(valid_i),
  //     .key_select_i(1'b1),
  //     .coeff_i(coeff_i),
  //     .relin_key_register_file(relin_key_register_file),
  //     .coeff_o(c1_coeff_o),
  //     .valid_o(c1_valid_o),
  //     .ready_o(c1_ready_o)
  //     );
endmodule // relin_wrapper
