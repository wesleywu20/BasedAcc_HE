import fifo_types::*;

module fifo_buffer #(
    /***************************** Param Declarations ****************************/
    // Width of words (in bits) stored in queue
    parameter width_p = 8,
    // FIFO's don't use shift registers, rather, they use pointers
    // which address to the "read" (dequeue) and "write" (enqueue)
    // ports of the FIFO's memory
    parameter ptr_width_p = 8,

    parameter cap_p = (1 << ptr_width_p)
) (
    input logic clk_i,
    input logic reset_n_i,

    // valid-ready input protocol
    input [width_p-1:0] data_i,
    input logic valid_i,
    output logic ready_o,

    // valid-yumi output protocol
    output logic valid_o,
    output [width_p-1:0] data_o,
    input logic yumi_i,

    // Arbitrary internal read/write access
    input logic buffer_write_i [cap_p-1:0],
    input [width_p-1:0] buffer_i [cap_p-1:0],
    output [width_p-1:0] buffer_o [cap_p-1:0],

    // Used for arbitrary internal access
    output [ptr_width_p-1:0] read_ptr_o,
    output [ptr_width_p-1:0] write_ptr_o
);

// The number of words stored in the FIFO

typedef logic [width_p-1:0] word_t;
// Why is the ptr type a bit longer than the "ptr_width"? 
// Make sure you can answer this question by the end of the semester
typedef logic [ptr_width_p:0] ptr_t;

/******************************** Declarations *******************************/
// Need memory to hold queued data
logic [width_p-1:0] queue [cap_p-1:0];
logic [width_p-1:0] queue_next [cap_p-1:0];

// Pointers which point to the read and write ends of the queue
ptr_t read_ptr, write_ptr, read_ptr_next, write_ptr_next;
logic [ptr_width_p - 1:0] read_ptr_trunc, write_ptr_trunc;
assign read_ptr_trunc = read_ptr[ptr_width_p-1:0];
assign write_ptr_trunc = write_ptr[ptr_width_p-1:0];

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
assign write_ptr_next = write_ptr + 1;
assign read_ptr_next = read_ptr + 1;

// Arbitrary read/write access
always_comb begin
    for(int i = 0; i < cap_p; i++) begin
        // $display("Buffer_write_i: %d | @tail: %d | @head: %d", 
        //     buffer_write_i[i], (enqueue && i == write_ptr_trunc), dequeue && i == read_ptr_trunc);
        if(buffer_write_i[i] && 
                ~(enqueue && i == write_ptr_trunc) && 
                ~(dequeue && i == read_ptr_trunc)) begin
            queue_next[i] = buffer_i[i];
        end
        else begin
            queue_next[i] = queue[i];
        end
    end
end

// Expose queue
assign buffer_o = queue;

// Expose queue pointers
assign read_ptr_o = read_ptr_trunc;
assign write_ptr_o = write_ptr_trunc;
/*****************************************************************************/

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i, negedge reset_n_i) begin    
    // The `n` in the `reset_n_i` means the reset signal is active low
    if (~reset_n_i) begin
        read_ptr  <= 0;
        write_ptr <= 0;

        // Hard reset for testbench purposes
        for(int i = 0; i < cap_p; i++) 
        begin
            queue[i] <= '0;
        end
    end
    else begin
        // Assign next queue (should be implemented as registers)
        for(int i = 0; i < cap_p; i++) 
        begin
            // // Check if enqueue or dequeue is not already reading/writing
            if(~(enqueue && i == write_ptr_trunc) && 
                    ~(dequeue && i == read_ptr_trunc)) begin
                queue[i] <= buffer_write_i[i] ? buffer_i[i] : queue[i];
            end
            // queue[i] <= queue_next[i];
        end
        
        case ({enqueue, dequeue})
            2'b00: ;
            2'b01: begin : dequeue_case
                output_buffer_r <= queue[read_ptr_next[ptr_width_p-1:0]];
                read_ptr <= read_ptr_next;
            end
            2'b10: begin : enqueue_case
                queue[write_ptr[ptr_width_p-1:0]] <= data_i;
                write_ptr <= write_ptr_next;
                if (empty) begin
                    output_buffer_r <= data_i;
                end
            end
            // When enqueing and dequeing simultaneously, we must be careful
            // to place proper data into output buffer.
            // If there is only one item in the queue, then the input data
            // Should be copied directly into the output buffer
            2'b11: begin : dequeue_and_enqueue_case
                // Dequeue portion
                output_buffer_r <= read_ptr_next[ptr_width_p-1:0] ==
                                     write_ptr[ptr_width_p-1:0] ?
                                        data_i :
                                        queue[read_ptr_next[ptr_width_p-1:0]];
                read_ptr <= read_ptr_next;

                // Enqueue portion
                queue[write_ptr[ptr_width_p-1:0]] <= data_i;
                write_ptr <= write_ptr_next;
                // No need to check empty, since can't dequeue from empty
            end
        endcase
    end
/*****************************************************************************/
end

endmodule : fifo_buffer
