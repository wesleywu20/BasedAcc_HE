`include "he_headers.sv"

module test_datapath
  (
   input logic                                  clk,
   input logic                                  rst,
   input logic [`BIT_WIDTH-1:0]                 t,
   input logic [`BIT_WIDTH-1:0]                 q,
   input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]  coeff_i,
   input logic                                  coeff_ready_i,
   output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] coeff_o,
   output logic                                 coeff_ready_o
   );

   // Multipliers
   logic [2*(`DEGREE_N-1):0][`BIT_WIDTH-1:0]    poly_mul_00_cs;
   logic                                        poly_mul_00_done;

   polynomial_multiplier #(.MULTIPLIER_WIDTH(`DEGREE_N), .INPUT_WIDTH(`DEGREE_N)) poly_mul_00
     (
      .clk(clk),
      .reset(rst),
      .start(1'b1), // IGNORE
      .as(coeff_i),
      .bs(coeff_i),
      .carry(), // IGNORE
      .cs(poly_mul_00_cs),
      .done(poly_mul_00_done)
      );

   // Multiplication Output Queue
   logic                        poly_mul_output_valid_i, poly_mul_output_ready_o;
   logic                        poly_mul_output_valid_o, poly_mul_output_yumi_i;

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] poly_mul_output_data_i;
   logic [`BIT_WIDTH-1:0]                poly_mul_output_data_o;

   assign poly_mul_output_data_i = coeff_i;
   assign poly_mul_output_valid_i = coeff_ready_i;

   fifo_synch_1rnw #(.width_p(`BIT_WIDTH), .ptr_width_p($clog2(`DEGREE_N))) poly_mul_output
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(poly_mul_output_data_i),
      .valid_i(poly_mul_output_valid_i),
      .ready_o(poly_mul_output_ready_o),
      .valid_o(poly_mul_output_valid_o),
      .data_o(poly_mul_output_data_o),
      .next_data_o(), // IGNORE
      .yumi_i(poly_mul_output_yumi_i)
      );

   // Recontextualization
   logic                        recon_unit_valid_i, recon_unit_ready_o, recon_unit_done_o;
   logic [`BIT_WIDTH-1:0]       recon_unit_coeff_i, recon_unit_coeff_o;

   assign recon_unit_coeff_i = poly_mul_output_data_o;
   assign poly_mul_output_yumi_i = poly_mul_output_valid_o & recon_unit_ready_o;
   assign recon_unit_valid_i = poly_mul_output_yumi_i;

   processor recon_unit
     (
      .clk(clk),
      .rst(rst),
      .t(t),
      .q(q),
      .data_i(poly_mul_output_data_o),
      .valid_i(recon_unit_valid_i),
      .ready_o(recon_unit_ready_o),
      .data_o(recon_unit_coeff_o),
      .done_o(recon_unit_done_o)
      );

   // Poly Modulation
   logic                        poly_mod_valid_i, poly_mod_valid_o;
   logic [`BIT_WIDTH-1:0]       poly_mod_coeff_i, poly_mod_coeff_o;

   assign poly_mod_valid_i = recon_unit_done_o;
   assign poly_mod_coeff_i = recon_unit_coeff_o;

   poly_mod poly_mod
     (
      .clk(clk),
      .rst(rst),
      .q(q),
      .coeff_i(poly_mod_coeff_i),
      .valid_i(poly_mod_valid_i),
      .coeff_o(poly_mod_coeff_o),
      .valid_o(poly_mod_valid_o)
      );

   // Output to nr1w FIFO
   logic                        poly_mod_output_valid_i, poly_mod_output_valid_o, poly_mod_output_yumi_i;
   logic [`BIT_WIDTH-1:0]       poly_mod_output_data_i, poly_mod_output_data_o;

   assign poly_mod_output_data_i = poly_mod_coeff_o;
   assign poly_mod_output_valid_i = poly_mod_valid_o;

   fifo_synch_1r1w #(.width_p(`BIT_WIDTH), .ptr_width_p($clog2(`DEGREE_N))) poly_mod_output
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(poly_mod_output_data_i),
      .valid_i(poly_mod_valid_o),
      .ready_o(), // IGNORE
      .valid_o(poly_mod_output_valid_o),
      .data_o(poly_mod_output_data_o),
      .next_data_o(), // IGNORE
      .yumi_i(poly_mod_output_yumi_i)
      );

   // Relinearization Phase
   logic                        relin_ready_i, relin_ready_o;
   logic [`BIT_WIDTH-1:0]       relin_coeff_i, relin_coeff_o;

   assign relin_ready_i = poly_mod_output_valid_o;
   assign poly_mod_output_yumi_i = relin_ready_i;
   assign relin_coeff_i = poly_mod_output_data_o;

   relinearizer relin
     (
      .clk(clk),
      .rst(rst),
      .ready_i(relin_ready_i),
      .coeff_i(relin_coeff_i),
      .ready_o(relin_ready_o),
      .coeff_o(relin_coeff_o)
      );

   // Final output
   // assign coeff_ready_o = poly_mod_valid_i;
   assign coeff_ready_o = relin_ready_o;
   assign coeff_o = poly_mod_coeff_i;


endmodule
