`include "he_headers.sv"

module relin_passthrough
  (
   input logic                                             clk,
   input logic                                             rst,
   input logic [1:0][`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] relin_key_register_file,
   input logic                                             valid_i,
   output logic                                            ready_o,
   input logic [`TILE_N-1:0][`BIT_WIDTH-1:0]               coeff_i,
   output logic                                            valid_o,
   output logic                                            key_select_o,
   output logic [`TILE_N-1:0][`BIT_WIDTH-1:0]              coeff_o
   );

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]                   c2;
   logic [`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0]            c2_base_t;

   logic [`L_:0][2*`DEGREE_N-1:0][`BIT_WIDTH-1:0]          c0_relin_long, c1_relin_long;
   logic [`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0]            c0_relin, c1_relin;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]                   c0_final, c1_final;

   enum {READY, DATA_IN, BASE_T_DECOMP, POLY_MULT, POLY_MOD, POLY_ADD, DONE} state, next_state;
   int  data_counter;
   logic pm_done, pa_done, op_done;

   task poly_mul(input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] a_i, b_i,
                 output logic [2*`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_o);

      for(int i = 0; i < 2*`DEGREE_N; ++i) c_o[i] = 0;

      for(int i = 0; i < `DEGREE_N; ++i) begin
         for(int j = 0; j < `DEGREE_N; ++j) begin
            @(posedge clk) c_o[i+j] = (c_o[i+j] + a_i[i]*b_i[j]);
         end
      end
   endtask // poly_mul

   function poly_mod(input logic [2*`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_i,
                     output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_o);
      for(int i = 0; i < `DEGREE_N; ++i) begin
        if(c_i[i] < c_i[i + `DEGREE_N]) c_o[i] = ($signed(c_i[i] - c_i[i + `DEGREE_N]) % `_Q) + `_Q;
        else c_o[i] = (c_i[i] - c_i[i + `DEGREE_N]) % `_Q;
      end
   endfunction // poly_mod

   task poly_add(input logic [`L_:0][`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_i,
                 output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_o);
      for(int i = 0; i < `DEGREE_N; ++i) c_o[i] = 0;

      for(int j = 0; j < `DEGREE_N; ++j)
        for(int i = 0; i <= `L_; ++i)
          @(posedge clk) c_o[j] = c_o[j] + c_i[i][j];
   endtask // poly_add

   task output_values(input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] c_i,
                      output logic [`TILE_N-1:0][`BIT_WIDTH-1:0] tile_o);
      for(int i = 0; i < `DEGREE_N / `TILE_N; ++i) begin
         @(posedge clk) tile_o[`TILE_N-1:0] = c_i[(i*`TILE_N)+:`TILE_N]; // $display("%x", tile_o);
      end
   endtask // output_values

   always_comb begin
      unique case (state)
        READY:
          if(valid_i) next_state = DATA_IN;
          else next_state = READY;
        DATA_IN:
          if(data_counter == `TILE_N) next_state = BASE_T_DECOMP;
          else next_state = DATA_IN;
        BASE_T_DECOMP: next_state = POLY_MULT;
        POLY_MULT:
          if(pm_done) next_state = POLY_MOD;
          else next_state = POLY_MULT;
        POLY_MOD: next_state = POLY_ADD;
        POLY_ADD:
          if(pa_done) next_state = DONE;
          else next_state = POLY_ADD;
        DONE:
          if(op_done) next_state = READY;
          else next_state = DONE;
      endcase // unique case (state)

      if(~rst) next_state = READY;
   end

   always_comb begin : signals
      valid_o = 1'b0;
      ready_o = 1'b0;

      if(~key_select_o) coeff_o = c0_final[(data_counter*`TILE_N)+:`TILE_N];
      else coeff_o = c1_final[(data_counter*`TILE_N)+:`TILE_N];

      unique case (state)
        READY: ready_o = 1'b1;
        DATA_IN: ready_o = 1'b1;
        BASE_T_DECOMP:;
        POLY_MULT:;
        POLY_MOD:;
        POLY_ADD:;
        DONE: valid_o = 1'b1;
      endcase // unique case (state)
   end


   always_ff @(posedge clk) begin
      state = next_state;

      unique case (state)
        READY: data_counter = 0;
        DATA_IN:
          if(valid_i) begin
             c2[(data_counter*`TILE_N)+:`TILE_N] = coeff_i;
             data_counter += 1;
          end
        BASE_T_DECOMP:
           begin
              for(int i = 0; i <= `L_; ++i)
                for(int j = 0; j < `DEGREE_N; ++j)
                  c2_base_t[i][j] = (c2[j] / (`T_**i)) % `T_;
              data_counter = 0;
           end
        POLY_MULT:
          begin
             for(int i = 0; i <= `L_; ++i) begin
                poly_mul(c2_base_t[i], relin_key_register_file[0][i], c0_relin_long[i]);
                poly_mul(c2_base_t[i], relin_key_register_file[1][i], c1_relin_long[i]);
             end
             pm_done = 1'b1;
          end
        POLY_MOD:
          for(int i = 0; i <= `L_; ++i) begin
             poly_mod(c0_relin_long[i], c0_relin[i]);
             poly_mod(c1_relin_long[i], c1_relin[i]);
          end
        POLY_ADD:
          begin
             poly_add(c0_relin, c0_final);
             poly_add(c1_relin, c1_final);
             pa_done = 1'b1;
          end
        DONE:
          begin
             data_counter = 0;
             key_select_o = 1'b0;
             repeat(`DEGREE_N / `TILE_N) @(posedge clk) data_counter += 1;
             data_counter = 0;
             key_select_o = 1'b1;
             repeat(`DEGREE_N / `TILE_N) @(posedge clk) data_counter += 1;
             op_done = 1'b1;
          end
      endcase // unique case (state)

      if(~rst) begin
         c2_base_t = 0;
         pm_done = 0;
         pa_done = 0;
         op_done = 0;
         key_select_o = 0;
      end
   end

endmodule // relin_passthrough
