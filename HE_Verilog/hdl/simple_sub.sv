`include "he_headers.sv"

module su(
             input logic                  clk,
             input logic                  rst,
             input logic                  start,
             input logic [`BIT_WIDTH-1:0]  a,
             input logic [`BIT_WIDTH-1:0]  b,
             output logic                 done,
             output logic [`BIT_WIDTH-1:0] c
          );

   enum {
         READY,
         CALC,
         DONE
         } state;

   always_ff @(posedge clk) begin
      if(~rst) state = READY;
      else if(start & (state == READY)) state = CALC;
      else if(state == CALC) state = DONE;
      else state = READY;
   end

   always_comb begin
      done = 1'b0;
      if(state == DONE) done = 1'b1;

      c = a - b;
   end

endmodule // su
