/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    	input clk,
    	input rst,
        input logic read,
	input logic write,
        input logic pmem_resp,
    	input logic [31:0] mem_byte_enable256,

	input logic hit0,hit1,       
        input logic lru,valid0,valid1, //current values of this like valid1_out
	//Mux sel
	output logic data_out_sel,data_in_sel,pmem_address_sel,

	output logic read_all,
	output logic [31:0] load_data0_in,load_data1_in,//this is mem enable when we want to write the the cashe and in the fetch state and O in other statess
	output logic load_lru, lru_in,
	output logic load0_valid,load1_valid,valid_in,
	output logic load0_tag,load1_tag,

	output logic mem_resp,pmem_read,pmem_write


);

enum int unsigned {
    check,missfetch
} state, next_state;

function void set_defaults();

	data_in_sel = 1'b0;
	data_out_sel = 1'b0;
        pmem_address_sel =1'b0; //Usually it is the CPU address unless there is a writeback
 	read_all = 1'b1;// Always read??

	load_data0_in = '0; //all 1 s when we want to write
	load_data1_in = '0; //all 1 s when we want to write
	load_lru = 1'b0;
	lru_in = 1'b0;
	load0_tag = 1'b0;
	load0_valid = 1'b0;


	load1_tag = 1'b0;
	load1_valid = 1'b0;

	mem_resp =1'b0;
	pmem_read = 1'b0;
	pmem_write = 1'b0;
	
endfunction

always_comb
begin : state_actions

    /* Actions for each state */
    /* Default output assignments */
    	set_defaults();
	unique case(state)
		check: begin     
			if(read && hit0) begin
				data_out_sel=1'b0; 
				mem_resp =1'b1;
				//Update LRU
				load_lru = 1'b1;
				lru_in = 1'b1;        
			end 
			if(read && hit1)begin
				data_out_sel=1'b1;
				mem_resp = 1'b1;
				//Update LRU
				load_lru = 1'b1;
				lru_in = 1'b0;
			end
		end
		missfetch:begin 
			pmem_read = 1'b1;
			pmem_address_sel =1'b0; 
			data_in_sel = 1'b1;
				
			if(lru ==1'b1)begin
				load_data1_in = '1; 
				load1_tag = 1'b1;
				load1_valid = 1'b1;
				valid_in = 1'b1;
					
			end
			else begin 
				load_data0_in = '1;
				load0_tag = 1'b1;
				load0_valid = 1'b1;
				valid_in = 1'b1;
			

			end 
		end

	endcase 

end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	
	unique case(state)
	check: begin
		if((hit0||hit1)&&(read || write) || ~(read || write))                                                                                
			next_state = check; 
	       	else  next_state = missfetch;       
	end
	missfetch:begin                              
		if(pmem_resp ==0)
			next_state = missfetch; 
		else next_state = check;
	end

	default: next_state = check;
	endcase
end

always_ff @(posedge clk)
begin: next_state_assignment

	if (rst) 
		state <= check;
	else 
		state <= next_state;
end


endmodule : cache_control
