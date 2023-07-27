`include "he_headers.sv"

module poly_mod(
                input logic                   clk,
                input logic                   rst,
                input logic [`BIT_WIDTH-1:0]  q,
                input logic [`BIT_WIDTH-1:0]  coeff_i,
                input logic                   valid_i,
                output logic [`BIT_WIDTH-1:0] coeff_o,
                output logic                  valid_o
               );

   logic                                     upper_full_o, upper_valid_o, upper_enqueue_i;
   logic                                     lower_full_o, lower_valid_o, lower_enqueue_i;
   logic                                     sub_result_valid, mod_result_valid, pair_ready;
   logic                                     yumi_i;


   logic[`BIT_WIDTH-1:0] sub_a, sub_b, sub_c, mod_i, mod_o;

   assign valid_o = mod_result_valid;
   assign coeff_o = mod_o;

   fifo_synch_1r1w
     #(
       .width_p(`BIT_WIDTH),
       .ptr_width_p($clog2(`DEGREE_N))
       ) lower_fifo
       (
        .clk_i(clk),
        .reset_n_i(rst),
        .data_i(coeff_i),
        .valid_i(lower_enqueue_i),
        .ready_o(lower_full_o),
        .valid_o(lower_valid_o),
        .next_data_o(), // Don't use
        .yumi_i(yumi_i),
        .data_o(sub_a)
        ); // Contains lower coeff of poly

   fifo_synch_1r1w
     # (
        .width_p(`BIT_WIDTH),
        .ptr_width_p($clog2(`DEGREE_N))
        ) upper_fifo
       (
        .clk_i(clk),
        .reset_n_i(rst),
        .data_i(coeff_i),
        .valid_i(upper_enqueue_i),
        .ready_o(upper_full_o),
        .valid_o(upper_valid_o),
        .next_data_o(), // Don't use
        .yumi_i(yumi_i),
        .data_o(sub_b)
        ); // Contains upper coeff of poly

   enum {
         LOWER,
         UPPER
         } state;

   logic [$clog2(`DEGREE_N):0] e_count;

   assign yumi_i = pair_ready;

   always_comb begin
      sub_c = sub_a - sub_b;

      if($signed(mod_i) < 0) mod_o = mod_i + q; // mod is just + here due to constraints
      else mod_o = mod_i;

      pair_ready = upper_valid_o & lower_valid_o; // must dequeue 2 at a time
   end

   always_ff @(posedge clk) begin
      if(valid_i) begin
         if(state == UPPER) begin // TODO not gonna work, need state machine
            upper_enqueue_i = 1'b1;
            lower_enqueue_i = 1'b0;
            e_count += 1;
         end else begin
            upper_enqueue_i = 1'b0;
            lower_enqueue_i = 1'b1;
            e_count += 1;
         end
      end else begin
         upper_enqueue_i = 1'b0;
         lower_enqueue_i = 1'b0;
      end // else: !if(LOWER)

      mod_i = sub_c; // clock to avoid long critical path
      sub_result_valid = pair_ready;
      mod_result_valid = sub_result_valid;

      if(e_count == `DEGREE_N) begin
         state = (state == LOWER)?UPPER:LOWER;
         e_count = 0;
      end

      if(~rst) begin
         state = LOWER;
         e_count = 0;
      end
   end

   always_ff @(posedge clk) begin
      if(`DEBUG) begin
         // if(valid_i) $write("%x ", coeff_i);
         // if(pair_ready) $display("%d %d", sub_a, sub_b);
         // if(pair_ready) $display("%d - %d = %d", sub_a, sub_b, $signed(sub_c));
         // if(valid_o) $write("%d ", $signed(coeff_o));
      end
   end


endmodule // polymod
