`include "he_headers.sv"

module datapath(
                input logic clk,
                input logic rst
                );

   // State tracking
   logic [1:0]              iter; // TODO -> what's the max value?

   // Stage 1: Polynomial Multiplication
   logic                    c_ready, poly_mult_done;

   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] a_inputs;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] b_inputs;
   logic [2*(`TILE_N-1):0][`BIT_WIDTH-1:0] outputs;

   poly_mult_top
     #(
       .POLY_A_WIDTH(`DEGREE_N),
       .POLY_B_WIDTH(`DEGREE_N),
       .POLY_A_TILE_WIDTH(`TILE_N),
       .POLY_B_TILE_WIDTH(`TILE_N),
       .DATA_WIDTH(`BIT_WIDTH)
      ) poly_mult_top
       (
        .clk(clk),
        .rst(rst),
        .inputs_ready_signal(1'b1),
        .tile_a(a_inputs),
        .tile_b(b_inputs),
        .c_value_outputs(outputs),
        .outputs_ready_signal(c_ready),
        .done(poly_mult_done)
        );

   // Output collection
   logic                                   multi_fifo_valid_i, multi_fifo_valid_o, multi_fifo_ready_o;
   logic                                   multi_fifo_yumi_i;
   logic [`BIT_WIDTH-1:0]                  multi_fifo_data_o;


   assign multi_fifo_valid_i = c_ready;
   // Packed -> Unpacked TODO

   fifo_synch_1rnw
     #(
       .width_p(`BIT_WIDTH),
       .ptr_width_p($clog2(2*`DEGREE_N))
       ) multi_fifo
       (
        .clk_i(clk),
        .reset_n_i(rst),
        .data_i(outputs),
        .valid_i(multi_fifo_valid_i),
        .ready_o(multi_fifo_ready_o),
        .valid_o(multi_fifo_valid_o),
        .data_o(multi_fifo_data_o),
        .next_data_o(),
        .yumi_i(multi_fifo_yumi_i)
        );

   // Poly-Mod Unit
   always @(posedge clk) assign multi_fifo_yumi_i = multi_fifo_ready_o; // TODO sketchy
   logic                                   poly_mod_valid_o;
   logic [`BIT_WIDTH-1:0]                  poly_mod_coeff_o;

   poly_mod poly_mult_mod
     (
      .clk(clk),
      .rst(rst),
      .q(`BIT_WIDTH'h05),
      .coeff_i(multi_fifo_data_o),
      .valid_i(multi_fifo_valid_o), // TODO add output signal to indicate enqueueing
      .coeff_o(poly_mod_coeff_o),
      .valid_o(poly_mod_valid_o) // TODO probably care about ready_o???
      );

   logic                                   recon_fifo_ready_o, recon_fifo_valid_o;

   fifo_synch_1r1w
     #(
       .width_p(`BIT_WIDTH),
       .ptr_width_p($clog2(`DEGREE_N))
       ) recon_fifo
       (
        .clk_i(clk),
        .reset_n_i(rst),
        .data_i(poly_mod_coeff_o),
        .valid_i(poly_mod_valid_o),
        .ready_o(recon_fifo_ready_o),
        .valid_o(recon_fifo_valid_o),
        .data_o(),
        .next_data_o(),
        .yumi_i()
        );

   // Stage 2: Recon Unit

   // Output pipe for re-lin

   // Stage 3: Relinearization Unit

   always_ff @(posedge clk) begin
      if(rst) iter = 0;
      else if(iter) iter += 1; // 0 = stopped state
   end

endmodule
