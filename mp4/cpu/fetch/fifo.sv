import rv32i_types::*;
module I_queue #(
    parameter width_p = $bits(instr_struct),
    parameter cap_p = 8
)
(

    input logic clk_i,
    input logic reset_n_i,
    input logic flush, 

    // valid-ready input protocol
    input instr_struct data_i,
    input logic valid_i,
    output logic ready_o,

    // valid-yumi output protocol
    output logic valid_o,
    output instr_struct data_o,
    input logic yumi_i,
    output logic dequeue_assert,
    output logic enqueue_assert
    
);
/*
----INPUT-----
flush -> flush the entire pipeline in a mispredict and assert that flush happened
data_i -> instruction from IR
valid_i -> load_queue  (enqu)when decode is done 
yumi_i -> station_ready
assert_o -> tells that the dequeued data is in output buffer or that the flush happened or data is enqueued
ready_o -> Instruction queue is not full ready to take a new decoded inst

*/

/******************************** Declarations *******************************/
instr_struct queue [cap_p-1:0];

// Pointers which point to the read and write ends of the queue
ptr_t read_ptr, write_ptr, read_ptr_next, write_ptr_next;

// Helper logic
logic empty, full, ptr_eq, sign_match;
logic  enqueue, dequeue;

// We always know what the next data which will be dequeued is.
// Thus it only makes sense to register it in an output buffer
instr_struct output_buffer_r;
/*****************************************************************************/

/***************************** Output Assignments ****************************/
assign ready_o = ~full;//we can enqueue from decoder when high and fetch the next pc from I cache
assign valid_o = ~empty;//Pull from the queue only when not empty
assign data_o = output_buffer_r;
/*****************************************************************************/

/******************************** Assignments ********************************/
assign full = ptr_eq & (~sign_match);
assign ptr_eq = |(read_ptr[ptr_width_p-1:0] == write_ptr[ptr_width_p-1:0]);
assign sign_match = read_ptr[ptr_width_p] == write_ptr[ptr_width_p];
assign empty = ptr_eq & sign_match;
assign enqueue = ready_o & valid_i;
assign dequeue = valid_o & yumi_i;
assign write_ptr_next = write_ptr + '1;
assign read_ptr_next = read_ptr + '1;
/*****************************************************************************/

/*************************** Non-Blocking Assignments ************************/
always_ff @(posedge clk_i/*, negedge reset_n_i*/) begin
    // The `n` in the `reset_n_i` means the reset signal is active low
    if (reset_n_i) begin
        read_ptr  <= '0;
        write_ptr <= '0;
        //assert_o <= '0;
	dequeue_assert <= '0;
	enqueue_assert <='0;
    end
    //Flush the entire pipeline
    //if(flush)begin
    else if(flush)begin
        read_ptr  <= '0;
        write_ptr <= '0;
        //assert_o <= '1;
    end 
    else begin
        case ({enqueue, dequeue})
            2'b00: begin
		//assert_o <= '0;
		dequeue_assert <= '0;
		enqueue_assert <='0;

	    end
            2'b01: begin : dequeue_case
                output_buffer_r <= queue[read_ptr_next[ptr_width_p-1:0]];
                read_ptr <= read_ptr_next;
                //assert_o <= '1;
		dequeue_assert <= '1;
		enqueue_assert <='0;
            end
            2'b10: begin : enqueue_case 
                queue[write_ptr[ptr_width_p-1:0]] <= data_i;
                write_ptr <= write_ptr_next;
		dequeue_assert <= '0;
		enqueue_assert <='1;
		//assert_o <= '0;
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
        	//assert_o <= '1;
		dequeue_assert <= '1;
		enqueue_assert <='1;

                // Enqueue portion
                queue[write_ptr[ptr_width_p-1:0]] <= data_i;
                write_ptr <= write_ptr_next;
                // No need to check empty, since can't dequeue from empty
            end
        endcase
    end
/*****************************************************************************/
end

endmodule : I_queue

