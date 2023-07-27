`include "../he_headers.sv"

import fifo_types::*;

module alt_multi_fifo #(
    /***************************** Param Declarations ****************************/
    // Width of words (in bits) stored in queue
    parameter width_p = `BIT_WIDTH,
    // FIFO's don't use shift registers, rather, they use pointers
    // which address to the "read" (dequeue) and "write" (enqueue)
    // ports of the FIFO's memory
    parameter ptr_width_p = $clog2(`DEGREE_N)+1,
    parameter enqueue_n = `N_WRITE
) (
    input logic clk_i,
    input logic reset_n_i,

    // valid-ready input protocol
    input [enqueue_n-1:0][width_p-1:0] data_i, // TODO reverse causing issues
    input logic valid_i,
    output logic ready_o,

    // valid-yumi output protocol
    output logic valid_o,
    output [width_p-1:0] data_o,
    output [width_p-1:0] next_data_o,
    input logic yumi_i
);

   enum         {ready, eq_ip} state, next_state;
   int          counter;

   logic        fifo_valid_i;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] data;
   logic [`BIT_WIDTH-1:0] fifo_data_i;

   fifo_synch_1r1w #(.width_p(width_p), .ptr_width_p(ptr_width_p))
   fifo
     (
      .clk_i(clk_i),
      .reset_n_i(reset_n_i),
      .data_i(fifo_data_i),
      .valid_i(fifo_valid_i),
      .ready_o(ready_o),
      .valid_o(valid_o),
      .data_o(data_o),
      .next_data_o(next_data_o),
      .yumi_i(yumi_i)
      );

   always_comb begin : state_logic
      unique case(state)
        ready:
          if(valid_i) next_state = eq_ip;
          else next_state = ready;
        eq_ip:
          if(counter == `N_WRITE-1) next_state = ready;
          else next_state = eq_ip;
      endcase // unique case (state)

      if(~reset_n_i) next_state = ready;
   end // block: state_logic

   always_comb begin : fifo_inputs
      fifo_valid_i = (state == eq_ip);
      fifo_data_i = data[counter];
   end // block: fifo_inputs

   always_ff @(posedge clk_i) begin
      state <= next_state;


      if(state == ready) begin
         counter = 0;
         data = data_i;
      end else counter++;
   end

endmodule : alt_multi_fifo
