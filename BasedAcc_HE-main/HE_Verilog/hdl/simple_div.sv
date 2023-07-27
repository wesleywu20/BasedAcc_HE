`include "he_headers.sv"

module du
  (
   input logic                   clk,
   input logic                   rst,
   input logic                   start,
   input logic [2*`BIT_WIDTH-1:0] dividend,
   input logic [`BIT_WIDTH-1:0]   divisor,
   output logic [`BIT_WIDTH-1:0]  quotient,
   output logic [`BIT_WIDTH-1:0]  remainder,
   output logic                  done
   );

   enum {
         READY,
         CALC,
         DONE
         } next_state, state;

   logic [`BIT_WIDTH-1:0] save_dividend, save_divisor;

   always_comb begin : state_logic
      if(start & (state == READY)) next_state = CALC;
      else if(state == CALC) next_state = DONE;
      else next_state = READY;

      if(~rst) next_state = READY;
   end

   always_ff @(posedge clk) begin
      state = next_state;

      if(state == CALC) begin
         save_dividend = dividend;
         save_divisor = divisor;
      end

   end

   always_comb begin
      done = 1'b0;
      if(state == DONE) done = 1'b1;

      quotient = save_dividend / save_divisor; // won't synthesize, just for testing
      remainder = save_dividend % save_divisor;
   end

endmodule : du
