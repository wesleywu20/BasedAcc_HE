`include "../he_headers.sv"

import fifo_types::*;

module param_fifo
  #(
    parameter WIDTH = `BIT_WIDTH,
    parameter READ_SIZE = `READ_SIZE,
    parameter WRITE_SIZE = `WRITE_SIZE,
    parameter PTR_WIDTH = 8
    )
   (
    input logic                       clk_i,
    input logic                       reset_n_i,

    // valid-ready input protocol
    input [WRITE_SIZE-1:0][WIDTH-1:0] data_i,
    input logic                       valid_i,
    output logic                      ready_o,

    // valid-yumi output protocol
    output logic                      valid_o,
    output [READ_SIZE-1:0][WIDTH-1:0] data_o,
    output [READ_SIZE-1:0][WIDTH-1:0] next_data_o,
    input logic                       yumi_i
    );

   // The number of words stored in the FIFO
   parameter int         cap_p = 1 << PTR_WIDTH;
   typedef logic [WIDTH-1:0] word_t;
   typedef logic [PTR_WIDTH:0] ptr_t;

/******************************** Declarations *******************************/
// Need memory to hold queued data
   logic [cap_p-1:0][WIDTH-1:0]        queue;

// Pointers which point to the read and write ends of the queue
ptr_t read_ptr, write_ptr, read_ptr_next, write_ptr_next, ptr_delta;

// Helper logic
logic empty, full, ptr_eq, ptr_ineq, sign_match;
logic  enqueue, dequeue;

// We always know what the next data which will be dequeued is.
// Thus it only makes sense to register it in an output buffer
logic [READ_SIZE-1:0][WIDTH-1:0] output_buffer_r;
/*****************************************************************************/

/***************************** Output Assignments ****************************/
assign ready_o = ~full;
assign valid_o = ~empty;
assign data_o = output_buffer_r;
/*****************************************************************************/

/******************************** Assignments ********************************/
assign full = ptr_eq & (~sign_match);
assign ptr_eq = |(read_ptr[PTR_WIDTH-1:0] == write_ptr[PTR_WIDTH-1:0]);
assign ptr_ineq = (read_ptr_next[PTR_WIDTH-1:0] > write_ptr[PTR_WIDTH-1:0]);
assign sign_match = read_ptr[PTR_WIDTH] == write_ptr[PTR_WIDTH];
assign empty = ptr_ineq & sign_match;
assign enqueue = ready_o & valid_i;
assign dequeue = valid_o & yumi_i;
assign write_ptr_next = write_ptr + WRITE_SIZE;
assign read_ptr_next = read_ptr + READ_SIZE;
assign ptr_delta = read_ptr_next - write_ptr;
/*****************************************************************************/

// Manually added
//assign next_data_o = queue[read_ptr];
assign next_data_o = queue[read_ptr[PTR_WIDTH-1:0]];

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i, negedge reset_n_i) begin
    // The `n` in the `reset_n_i` means the reset signal is active low
    if (~reset_n_i) begin
        read_ptr  <= 0;
        write_ptr <= 0;
    end
    else begin
        case ({enqueue, dequeue})
            2'b00: ;
            2'b01: begin : dequeue_case
               for(int i = 0; i < READ_SIZE; ++i)
                 output_buffer_r[i] <= queue[read_ptr_next[PTR_WIDTH-1:0]+i]; // I think this is OK
               read_ptr <= read_ptr_next;
            end
            2'b10: begin : enqueue_case
               for(int i = 0; i < WRITE_SIZE; ++i)
                 queue[write_ptr[PTR_WIDTH-1:0]+i] <= data_i[i];
               write_ptr <= write_ptr_next;

               if (empty)
                 for(int i = 0; i < WRITE_SIZE; ++i)
                   if(~(ptr_delta-(READ_SIZE-i) >> WIDTH-1))
                     output_buffer_r[READ_SIZE-(ptr_delta-i)] <= data_i[i];
            end
            // When enqueing and dequeing simultaneously, we must be careful
            // to place proper data into output buffer.
            // If there is only one item in the queue, then the input data
            // Should be copied directly into the output buffer
            2'b11: begin : dequeue_and_enqueue_case
                // Dequeue portion
                // TODO check if will be empty
               if(ptr_delta == READ_SIZE) output_buffer_r = data_i;
               else if(ptr_delta < READ_SIZE) begin
                  $display("Maybe????");
                  for(int i = 0; i < WRITE_SIZE; ++i) begin
                     $write("ptr_delta: %x\t", ptr_delta);
                     $display(i - ptr_delta);
                     output_buffer_r[i-ptr_delta] <= data_i[i];
                  end
               end else for(int i = 0; i < READ_SIZE; ++i)
                 output_buffer_r[i] <= queue[read_ptr_next[PTR_WIDTH-1:0]+i];

/*                output_buffer_r <= read_ptr_next[PTR_WIDTH-1:0] ==
                                     write_ptr[PTR_WIDTH-1:0] ?
                                        data_i :
                                        queue[read_ptr_next[PTR_WIDTH-1:0]];*/
                read_ptr <= read_ptr_next;

               // Enqueue portion
               for(int i = 0; i < WRITE_SIZE; ++i)
                 queue[write_ptr[PTR_WIDTH-1:0]+i] <= data_i[i];
               write_ptr <= write_ptr_next;
            end
        endcase
    end
/*****************************************************************************/
end

endmodule : param_fifo
