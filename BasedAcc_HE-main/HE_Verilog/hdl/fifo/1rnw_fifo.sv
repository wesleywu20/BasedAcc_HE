`include "../he_headers.sv"

import fifo_types::*;

module fifo_synch_1rnw #(
    /***************************** Param Declarations ****************************/
    // Width of words (in bits) stored in queue
    parameter width_p = `BIT_WIDTH,
    // FIFO's don't use shift registers, rather, they use pointers
    // which address to the "read" (dequeue) and "write" (enqueue)
    // ports of the FIFO's memory
    parameter ptr_width_p = 8
) (
    input logic clk_i,
    input logic reset_n_i,

    // valid-ready input protocol
    input [`N_WRITE-1:0][width_p-1:0] data_i,
    input logic valid_i,
    output logic ready_o,

    // valid-yumi output protocol
    output logic valid_o,
    output [width_p-1:0] data_o,
    output [width_p-1:0] next_data_o,
    input logic yumi_i
);

// The number of words stored in the FIFO
parameter int cap_p = 1 << ptr_width_p;
typedef logic [width_p-1:0] word_t;
// Why is the ptr type a bit longer than the "ptr_width"? 
// Make sure you can answer this question by the end of the semester
typedef logic [ptr_width_p:0] ptr_t;

/******************************** Declarations *******************************/
// Need memory to hold queued data
logic [width_p-1:0] queue [cap_p-1:0];

// Pointers which point to the read and write ends of the queue
ptr_t read_ptr, write_ptr, read_ptr_next, write_ptr_next;

// Helper logic
logic empty, full, ptr_eq, sign_match;
logic  enqueue, dequeue;

// We always know what the next data which will be dequeued is.
// Thus it only makes sense to register it in an output buffer
logic [width_p-1:0] output_buffer_r;
/*****************************************************************************/

/***************************** Output Assignments ****************************/
assign ready_o = ~full;
assign valid_o = ~empty;
assign data_o = output_buffer_r;
/*****************************************************************************/

/******************************** Assignments ********************************/
assign full = ptr_eq & (~sign_match);
assign ptr_eq = |(read_ptr[ptr_width_p-1:0] == write_ptr[ptr_width_p-1:0]);
assign sign_match = read_ptr[ptr_width_p] == write_ptr[ptr_width_p];
assign empty = ptr_eq & sign_match;
assign enqueue = ready_o & valid_i;
assign dequeue = valid_o & yumi_i;
assign write_ptr_next = write_ptr + `N_WRITE;
assign read_ptr_next = read_ptr + 1;
/*****************************************************************************/

// Manually added
//assign next_data_o = queue[read_ptr];
assign next_data_o = queue[read_ptr[ptr_width_p-1:0]];

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
                output_buffer_r <= queue[read_ptr_next[ptr_width_p-1:0]];
                read_ptr <= read_ptr_next;
            end
            2'b10: begin : enqueue_case
               if(~empty) begin
                  for(int i = 0; i < `N_WRITE; ++i) begin
                     queue[write_ptr[ptr_width_p-1:0]+i] <= data_i[i];
                  end
               end else begin
                  output_buffer_r <= data_i[0];

                  for(int i = 0; i < `N_WRITE; ++i) begin
                     queue[write_ptr[ptr_width_p-1:0]+i] <= data_i[i];
                  end
               end
               write_ptr <= write_ptr_next;
            end
            // When enqueing and dequeing simultaneously, we must be careful
            // to place proper data into output buffer.
            // If there is only one item in the queue, then the input data
            // Should be copied directly into the output buffer
            2'b11: begin : dequeue_and_enqueue_case
                // Dequeue portion
                output_buffer_r <= read_ptr_next[ptr_width_p-1:0] ==
                                     write_ptr[ptr_width_p-1:0] ?
                                        data_i[0] :
                                        queue[read_ptr_next[ptr_width_p-1:0]];
                read_ptr <= read_ptr_next;

                // Enqueue portion
                for(int i = 0; i < `N_WRITE; ++i) begin
                     queue[write_ptr[ptr_width_p-1:0]+i] <= data_i[i];
                end
                // queue[write_ptr[ptr_width_p-1:0]] <= data_i[0];
                write_ptr <= write_ptr_next;
                // No need to check empty, since can't dequeue from empty
            end
        endcase
    end
/*****************************************************************************/
end

endmodule : fifo_synch_1rnw
