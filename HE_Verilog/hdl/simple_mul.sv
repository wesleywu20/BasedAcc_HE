`include "he_headers.sv"

module mu
  (
   input logic                    clk,
   input logic                    rst,
   input logic                    start,
   input logic [`BIT_WIDTH-1:0]    a,
   input logic [`BIT_WIDTH-1:0]    b,
   output logic [2*`BIT_WIDTH-1:0] c,
   output logic                   done
   );

   enum {
         READY,
         CALC,
         DONE
         } next_state, state;

   logic [`BIT_WIDTH-1:0] save_a, save_b;

   always_comb begin : state_logic
      if(start & (state == READY)) next_state = CALC;
      else if(state == CALC) next_state = DONE;
      else next_state = READY;

      if(~rst) next_state = READY;

   end

   always_ff @(posedge clk) begin
      state = next_state;

      if(state == CALC) begin
         save_a = a;
         save_b = b;
      end

      c = save_a * save_b;

      done = 0;
      if(state == DONE) done = 1'b1;
   end

   always_ff @(posedge clk) begin
      // if(start) $display("starting mul");
      // if(done) $display("done");

      // $display("c = %x", c);
   end


endmodule : mu
