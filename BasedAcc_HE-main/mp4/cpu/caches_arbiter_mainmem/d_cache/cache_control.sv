/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control_d (
    input clk,
    input rst,
	//cpu communication
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,

	//memory communication
    output logic pmem_read,
    output logic pmem_write,
    input logic pmem_resp,

	//cache checks
	output logic load_tag_0,
	output logic load_tag_1,
	output logic load_lru,
	output logic load_valid_0,
	output logic load_valid_1,
	//dirty
	output logic load_dirty_0,
	output logic load_dirty_1,
	output logic dirty_in_0,
	output logic dirty_in_1,
	input logic dirt_0,
	input logic dirt_1,
	
	output logic [1:0] update,
	input logic replace,
	input logic tag_0_hit,
	input logic tag_1_hit,
	output logic data_select,
	output logic write_way,
	output logic pmem_out_sel
);
logic resp_delay;

enum int unsigned {
	idle, read, read_hit,miss,update_cache, write_back
} state, next_state;

function void set_defaults();
	mem_resp = 1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	load_tag_0 = 1'b0;
	load_tag_1 = 1'b0;
	load_lru = 1'b0;
	load_valid_0 = 1'b0;
	load_valid_1 = 1'b0;
	load_dirty_0 = 1'b0;
	dirty_in_0 = 1'b0;
	load_dirty_1 = 1'b0;
	dirty_in_1 = 1'b0;
	update = 2'b00;
	data_select = 1'b1;
	write_way= 1'b0;
	pmem_out_sel= 1'b0;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();

	unique case(state)
		idle:;
		read:begin
				if(tag_0_hit || tag_1_hit)begin
					load_lru = 1'b1;
					mem_resp = 1'b1;
					if(mem_write)begin
						update = 2'b11;
						data_select = 1'b0;
						if(tag_0_hit)begin
							write_way = 1'b0;
							load_dirty_0 = 1'b1;
							dirty_in_0 = 1'b1;
						end
						else begin
							write_way = 1'b1;
							load_dirty_1 = 1'b1;
							dirty_in_1 = 1'b1;
						end
					end
				end
			end
		miss: pmem_read = 1'b1;
		update_cache: begin
						if(!replace)begin
							update = 2'b10;
							load_tag_0 = 1'b1;
							load_valid_0 = 1'b1;
							load_dirty_0 = 1'b1;
							dirty_in_0 = 1'b0;
						end
						else begin
							update = 2'b01;
							load_tag_1 = 1'b1;
							load_valid_1 = 1'b1;
							load_dirty_1 = 1'b1;
							dirty_in_1 = 1'b0;
						end
					  end
		write_back: begin
						pmem_write = 1'b1;
						pmem_out_sel = 1'b1;
					end

		default:;
	endcase
    /* Actions for each state */
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_state = state;
	
	unique case(state)

		idle: if((mem_read || mem_write) & !mem_resp) next_state = read;
		read: if(tag_0_hit || tag_1_hit) next_state = idle;
			  else if((!replace && dirt_0) || (replace && dirt_1)) next_state = write_back;
			  else next_state = miss;
		miss: if(pmem_resp) next_state = update_cache;
		update_cache: next_state = read;
		write_back: if(pmem_resp) next_state = miss;
		default:;

	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment

	if(rst) state <= idle;
	else state <= next_state;
	
end
endmodule : cache_control_d
