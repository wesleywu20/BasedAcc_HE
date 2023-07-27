/*`include "he_headers.sv"

module functional
  (
   input logic                                  clk,
   input logic                                  rst,
   input logic [`BIT_WIDTH-1:0]                 t,
   input logic [`BIT_WIDTH-1:0]                 q,
   input logic                                  start_i,
   input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]  ct00,
   input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]  ct01,
   input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]  ct10,
   input logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0]  ct11,
   output logic                                 valid_o,
   output logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] res [1:0]
   );

   enum {
         ready,
         poly_mul,
         poly_mod,
         recon,
         base_T,
         done
         } state, next_state;


   int                                       a, b;
   always_comb begin : state_logic
      unique case(state)
        ready:
          begin
             if(start_i) next_state = poly_mul;
             else next_state = ready;
          end
        poly_mul:
          begin
             if(b == `DEGREE_N) next_state = poly_mod;
             else next_state = poly_mul;
          end
        poly_mod: next_state = recon;
        recon: next_state = base_T;
        base_T: next_state = done;
        done: next_state = ready;
      endcase // unique case (state)

      if(~rst) next_state = ready;
   end

   // Functional verification of computation
   logic [2*`DEGREE_N-1:0][`BIT_WIDTH-1:0] pm0, pm1, pm2; // Need extra int of padding
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] pr0, pr1, pr2;
   logic [`DEGREE_N-1:0][`L_:0][`BIT_WIDTH-1:0] d_T;

   always_ff @(posedge clk) begin
      state = next_state;
   end

   always_ff @(posedge clk) begin : computation
      unique case(state)
        ready:
          begin
             valid_o = 1'b0;
             for(int i = 0; i <= 2*`DEGREE_N-1; ++i) begin
                pm0[i] = 0;
                pm1[i] = 0;
                pm2[i] = 0;
             end
             a = 0;
             b = 0;
          end
        poly_mul:
          begin
             pm0[a+b] = pm0[a+b] + ct00[a]*ct10[b];
             pm1[a+b] = pm1[a+b] + ct00[a]*ct11[b] + ct01[a]*ct10[b];
             pm2[a+b] = pm2[a+b] + ct01[a]*ct11[b];

             if(a == `DEGREE_N-1) begin
                a = 0;
                b++;
             end else a++;
          end
        poly_mod:
          begin
             for(int i = 0; i < `DEGREE_N; ++i) begin
                pr0[i] = pm0[i] - pm0[i + `DEGREE_N];
                pr1[i] = pm1[i] - pm1[i + `DEGREE_N];
                pr2[i] = pm2[i] - pm2[i + `DEGREE_N];
             end
          end
        recon:
          begin
             for(int i = 0; i < `DEGREE_N; ++i) begin
                pr0[i] = (((($signed(pr0[i])*$signed(t)) / $signed(q)) % $signed(q)) + $signed(q)) % $signed(q);
                pr1[i] = (((($signed(pr1[i])*$signed(t)) / $signed(q)) % $signed(q)) + $signed(q)) % $signed(q);
                pr2[i] = (((($signed(pr2[i])*$signed(t)) / $signed(q)) % $signed(q)) + $signed(q)) % $signed(q);
             end
          end
        base_T:
          begin
             for(int i = 0; i <= `_L; ++i)
                for(int j = 0; j < `DEGREE_N; ++j) begin
                   d_T[i][j] = (pr0[j] / `_T**i) % `_T;
                end
             $display("%d", d_T);
          end
        done: valid_o = 1'b1;
      endcase // unique case (state)
   end

   always_ff @(posedge clk) begin
      if(valid_o) begin
         $display("----- pm -----");
         for(int i = 0; i <= 2*(`DEGREE_N-1); ++i) $write("%x ", pm0[i]);
         $write("\n");
         for(int i = 0; i <= 2*(`DEGREE_N-1); ++i) $write("%x ", pm1[i]);
         $write("\n");
         for(int i = 0; i <= 2*(`DEGREE_N-1); ++i) $write("%x ", pm2[i]);
         $write("\n");
         $display("----- pr -----");
         for(int i = 0; i <= (`DEGREE_N-1); ++i) $write("%d ", $signed(pr0[i]));
         $write("\n");
         for(int i = 0; i <= (`DEGREE_N-1); ++i) $write("%d ", $signed(pr1[i]));
         $write("\n");
         for(int i = 0; i <= (`DEGREE_N-1); ++i) $write("%d ", $signed(pr2[i]));
         $write("\n");
      end
   end

endmodule // functional
*/
