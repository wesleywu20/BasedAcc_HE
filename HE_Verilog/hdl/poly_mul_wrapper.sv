
`include "he_headers.sv"

module poly_mul_wrapper
  (
   input logic                                           clk,
   input logic                                           rst,
   input logic                                           rst_poly_mul,
   input logic                                           start,
   output logic                                          ready_o,
   input logic [1:0][7:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file,
   input logic [`TILE_N-1:0][`BIT_WIDTH-1:0]             as,
   input logic [`TILE_N-1:0][`BIT_WIDTH-1:0]             bs,
   output logic [`TILE_N-1:0][`BIT_WIDTH-1:0]            cs,
   output logic                                          outputs_ready,
   output logic                                          poly_mul_done,
   output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]          c0_reg_o,
   output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]          c1_reg_o,
   output logic                                          done
   );

   enum {s_c00, s_c01, s_c10, s_c11} mul_state, next_mul_state;

   always_comb begin

   end

   poly_mult_top #(.POLY_A_WIDTH(`DEGREE_N), .POLY_B_WIDTH(`DEGREE_N),
                   .POLY_A_TILE_WIDTH(`TILE_N), .POLY_B_TILE_WIDTH(`TILE_N),
                   .DATA_WIDTH(`BIT_WIDTH))
   poly_mul
     (
      .clk(clk),
      .rst(rst & rst_poly_mul),
      .inputs_ready_signal(start),
      .tile_a(as),
      .tile_b(bs),
      .c_value_outputs(cs),
      .outputs_ready_signal(outputs_ready),
      .done(poly_mul_done),
      .ready_for_tile(ready_o)
      );

   logic poly_mul_output_valid_o, poly_mul_output_yumi_i;
   logic [`BIT_WIDTH-1:0] coeff_o;

   // width_p(`BIT_WIDTH), .ptr_width_p($clog2(`DEGREE_N) + 1))
   param_fifo #(.WIDTH(`BIT_WIDTH), .WRITE_SIZE(`TILE_N), .READ_SIZE(1), .PTR_WIDTH(4*$clog2(`DEGREE_N)+1))
   poly_mul_output // TODO skipping when wraparound
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(cs),
      .valid_i(outputs_ready),
      .ready_o(), // We must size this such that we can always enqueue if needed
      .valid_o(poly_mul_output_valid_o),
      .data_o(coeff_o),
      .next_data_o(), // IGNORE
      .yumi_i(poly_mul_output_yumi_i)
      );

   logic                  recon_unit_valid_i, recon_unit_ready_o, recon_unit_done_o;
   logic [`BIT_WIDTH-1:0] recon_unit_data_i, recon_unit_data_o;

   assign recon_unit_data_i = coeff_o;
   assign recon_unit_valid_i = poly_mul_output_valid_o & recon_unit_ready_o;
   assign poly_mul_output_yumi_i = recon_unit_valid_i;

   processor recon_unit
     (
      .clk(clk),
      .rst(rst),
      .t(`BIT_WIDTH'd`_t),
      .q(`BIT_WIDTH'd`_Q),
      .data_i(recon_unit_data_i),
      .valid_i(recon_unit_valid_i),
      .ready_o(recon_unit_ready_o),
      .data_o(recon_unit_data_o),
      .done_o(recon_unit_done_o)
      );

   enum {c0, c1_0, c1_1, c2} ctxt_ip, next_ctxt_ip;
   enum {c0_o, c1_o, c2_o} ctxt_op, next_ctxt_op;
   int coeff_i_ip, coeff_i_op;

   logic [2*`DEGREE_N-1:0][`BIT_WIDTH-1:0] ct_reg;
   logic [`BIT_WIDTH-1:0] ct_coeff, poly_mod_coeff_i, poly_mod_coeff_o;
   logic                  poly_mod_valid_i, poly_mod_valid_o;

   always_ff @(posedge clk) begin
      if(~rst) begin
         coeff_i_ip = 0;
         coeff_i_op = 0;
      end

      if(coeff_i_ip == 2*`DEGREE_N) coeff_i_ip = 0;
      else if(recon_unit_done_o) coeff_i_ip += 1;

      if(coeff_i_op == `DEGREE_N) coeff_i_op = 0;
      else if(poly_mod_valid_o) coeff_i_op += 1;

      ctxt_ip = next_ctxt_ip;
      ctxt_op = next_ctxt_op;
   end

   always_comb begin : state_logic // c2 -> c1_1 -> c1_0 -> c0
      unique case(ctxt_ip)
        c0:
          if(coeff_i_ip == 2*(`DEGREE_N)) next_ctxt_ip = c0;
          else next_ctxt_ip = c0;
        c1_0:
          if(coeff_i_ip == 2*(`DEGREE_N)) next_ctxt_ip = c0;
          else next_ctxt_ip = c1_0;
        c1_1:
          if(coeff_i_ip == 2*(`DEGREE_N)) next_ctxt_ip = c1_0;
          else next_ctxt_ip = c1_1;
        c2:
          if(coeff_i_ip == 2*(`DEGREE_N)) next_ctxt_ip = c1_1;
          else next_ctxt_ip = c2;
      endcase // unique case (ctxt_ip)

      unique case(ctxt_op)
        c0_o:
          if(coeff_i_op == (`DEGREE_N)) next_ctxt_op = c0_o;
          else next_ctxt_op = c0_o;
        c1_o:
          if(coeff_i_op == (`DEGREE_N)) next_ctxt_op = c0_o;
          else next_ctxt_op = c1_o;
        c2_o:
          if(coeff_i_op == (`DEGREE_N)) next_ctxt_op = c1_o;
          else next_ctxt_op = c2_o;
      endcase // unique case (ctxt_op)

      if(~rst) begin
         next_ctxt_ip = c2;
         next_ctxt_op = c2_o;
      end
   end

   // TODO state machine sits here


   always_ff @(posedge clk) begin : ctxt_routing
      // Default signals
      poly_mod_valid_i = 1'b0;
      poly_mod_coeff_i = ct_reg[coeff_i_ip-1];

      unique case(ctxt_ip)
        c0:
           if(recon_unit_done_o) begin
              poly_mod_valid_i = 1'b1;
              ct_reg[coeff_i_ip-1] = recon_unit_data_o;
           end else if(~|coeff_i_ip) poly_mod_coeff_i = ct_reg[2*`DEGREE_N-1];
        c1_0:
          if(recon_unit_done_o) begin
             ct_reg[coeff_i_ip-1] = ct_reg[coeff_i_ip-1] + recon_unit_data_o;
             poly_mod_valid_i = 1'b1;
          end
        c1_1:
          if(recon_unit_done_o) ct_reg[coeff_i_ip-1] = recon_unit_data_o;
          else if(~|coeff_i_ip) poly_mod_coeff_i = ct_reg[2*`DEGREE_N-1];
        c2:
          if(recon_unit_done_o) begin
             poly_mod_valid_i = 1'b1;
             ct_reg[coeff_i_ip-1] = recon_unit_data_o;
          end
      endcase // unique case (ctxt_ip)
   end

   poly_mod poly_mod
     (
      .clk(clk),
      .rst(rst),
      .q(`BIT_WIDTH'd`_Q),
      .coeff_i(poly_mod_coeff_i),
      .valid_i(poly_mod_valid_i),
      .coeff_o(poly_mod_coeff_o),
      .valid_o(poly_mod_valid_o)
      );

   logic relin_input_fifo_valid_i, relin_input_fifo_valid_o, relin_input_fifo_yumi_i;
   logic [`BIT_WIDTH-1:0] relin_input_fifo_data_i;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] relin_input_fifo_data_o;

   logic                               c0_fifo_valid_i, c0_fifo_valid_o, c0_fifo_yumi_i;
   logic [`BIT_WIDTH-1:0]              c0_fifo_data_i, c0_fifo_data_o;
   logic                               c1_fifo_valid_i, c1_fifo_valid_o, c1_fifo_yumi_i;
   logic [`BIT_WIDTH-1:0]              c1_fifo_data_i, c1_fifo_data_o;

   always_comb begin : poly_mod_output_routing
      relin_input_fifo_valid_i = 1'b0;
      c0_fifo_valid_i = 1'b0;
      // c0_fifo_yumi_i = 1'b0;

      c1_fifo_valid_i = 1'b0;
      // c1_fifo_yumi_i = 1'b0;

      unique case(ctxt_op)
        c0_o: if(poly_mod_valid_o) c0_fifo_valid_i = 1'b1;
        c1_o: if(poly_mod_valid_o) c1_fifo_valid_i = 1'b1;
        c2_o: if(poly_mod_valid_o) relin_input_fifo_valid_i = 1'b1;
      endcase // unique case (ctxt_op)
   end

   assign relin_input_fifo_data_i = poly_mod_coeff_o;
   param_fifo #(.WIDTH(`BIT_WIDTH), .WRITE_SIZE(1), .READ_SIZE(`TILE_N), .PTR_WIDTH($clog2(`DEGREE_N)+1))
   relin_input_fifo
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(relin_input_fifo_data_i),
      .valid_i(relin_input_fifo_valid_i),
      .ready_o(), // Must always be able to enqueue -> not useful
      .valid_o(relin_input_fifo_valid_o),
      .data_o(relin_input_fifo_data_o),
      .next_data_o(), // IGNORE
      .yumi_i(relin_input_fifo_yumi_i)
      );

   assign c0_fifo_data_i = poly_mod_coeff_o;
   fifo_synch_1r1w #(.width_p(`BIT_WIDTH), .ptr_width_p($clog2(`DEGREE_N)+1))
   c0_fifo
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(c0_fifo_data_i),
      .valid_i(c0_fifo_valid_i),
      .ready_o(),
      .valid_o(c0_fifo_valid_o),
      .data_o(c0_fifo_data_o),
      .next_data_o(), // IGNORE
      .yumi_i(c0_fifo_yumi_i)
      );

   assign c1_fifo_data_i = poly_mod_coeff_o;
   fifo_synch_1r1w #(.width_p(`BIT_WIDTH), .ptr_width_p($clog2(`DEGREE_N)+1))
   c1_fifo
     (
      .clk_i(clk),
      .reset_n_i(rst),
      .data_i(c1_fifo_data_i),
      .valid_i(c1_fifo_valid_i),
      .ready_o(),
      .valid_o(c1_fifo_valid_o),
      .data_o(c1_fifo_data_o),
      .next_data_o(), // IGNORE
      .yumi_i(c1_fifo_yumi_i)
      );

   logic relin_unit_valid_i, relin_unit_ready_o, relin_unit_valid_o, relin_unit_done_o, key_select;
   logic [`TILE_N-1:0][`BIT_WIDTH-1:0] relin_unit_coeff_i, relin_unit_c0_coeff_o, relin_unit_c1_coeff_o;

   assign relin_unit_coeff_i = relin_input_fifo_data_o;
   assign relin_unit_valid_i = relin_input_fifo_valid_o & ~relin_input_fifo_valid_i;
   assign relin_input_fifo_yumi_i = relin_unit_ready_o;

//    assign relin_unit_valid_o = 1'b1;

   relin_wrapper relin_unit
     (
      .clk(clk),
      .rst(rst),
      .valid_i(relin_input_fifo_valid_o), // TODO
      .coeff_i(relin_unit_coeff_i),
      .relin_key_register_file(relin_key_register_file),
      .c0_coeff_o(relin_unit_c0_coeff_o),
      .c1_coeff_o(relin_unit_c1_coeff_o), // TODO
      .valid_o(relin_unit_valid_o),
      .ready_o(relin_unit_ready_o)
      );

   enum {relin_c0, relin_c1, relin_done} relin_ctxt;
   int  relin_ctxt_counter, c0_counter, c1_counter;

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c0_reg, c1_reg;
   always_ff @(posedge clk) begin

   end
  assign key_select = ((relin_ctxt==relin_c0)? 0:1);
   always_ff @(posedge clk) begin
      if(relin_unit_valid_o) begin
             for(int i = 0; i < `TILE_N; ++i) c0_reg[relin_ctxt_counter+i] += relin_unit_c0_coeff_o[i];
             for(int i = 0; i < `TILE_N; ++i) c1_reg[relin_ctxt_counter+i] += relin_unit_c1_coeff_o[i];
      end

      if(relin_unit_valid_o) relin_ctxt_counter += `TILE_N;

      if(relin_ctxt_counter == `DEGREE_N) begin
         relin_ctxt_counter = 0;

         if(relin_ctxt == relin_c0) relin_ctxt = relin_done;
         else relin_ctxt = relin_done;
      end

      if(c0_fifo_yumi_i) c0_counter += 1;
      if(c1_fifo_yumi_i) c1_counter += 1;

      if(~rst) begin
        for(int i = 0; i < `DEGREE_N; ++i) begin
            c0_reg[i] = 0;
            c1_reg[i] = 0;
        end

         relin_ctxt_counter = 0;
         relin_ctxt = relin_c0;

         c0_counter = 0;
         c1_counter = 0;
      end

      if(c0_fifo_yumi_i) c0_reg[c0_counter-1] += c0_fifo_data_o;
      if(c1_fifo_yumi_i) c1_reg[c1_counter-1] += c1_fifo_data_o;
   end

   assign c0_fifo_yumi_i = c0_fifo_valid_o & ~relin_unit_valid_o;
   assign c1_fifo_yumi_i = c1_fifo_valid_o & ~relin_unit_valid_o;

   assign done = (relin_ctxt == relin_done) & (c0_counter == `DEGREE_N) & (c1_counter == `DEGREE_N);
   assign c0_reg_o = c0_reg;
   assign c1_reg_o = c1_reg;

   always_ff @(posedge clk) begin
      // if(relin_unit_valid_o) $display("%x: %x ", relin_ctxt_counter, relin_unit_coeff_o);
      // if(relin_unit_valid_o) $display("%x: %x ", relin_ctxt_counter, relin_unit_coeff_o);
      // if(c0_fifo_yumi_i) $display("%x: %x ", c0_counter, c0_fifo_data_o);
   end

endmodule // poly_mul_wrapper
