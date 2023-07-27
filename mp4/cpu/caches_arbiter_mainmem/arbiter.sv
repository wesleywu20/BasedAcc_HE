module arbiter(
    input logic clk,
    input logic rst,

    input logic i_read_in,
    input logic d_read_in,
    input logic d_write_in,
    input logic [31:0] i_pmem_address,d_pmem_address,
    input logic i_mem_resp,d_mem_resp,

    output logic d_pmem_resp,//output
    output logic i_pmem_resp,//output
    output logic [31:0] pmem_address,//output
    output logic pmem_read,//output
    output logic pmem_write,//output

    input  logic pmem_resp//input
);
enum int unsigned {
    idle,i_cache,d_cache
} state,next_state;

//logic [1:0] counter;

//logic servicing_i_cache,servicing_d_cache;

always_comb 
begin : state_actions
    //Default 
    i_pmem_resp = '0;
    d_pmem_resp  = '0;
    pmem_address = '0;
    pmem_read = '0;
    pmem_write = '0;
    unique case(state)
        idle: begin
		/*if(i_read_in && ~(d_read_in || d_write_in))begin
			//servicing_i_cache = '1;
			//servicing_d_cache = '0;
			pmem_address = i_pmem_address;
    			i_pmem_resp = pmem_resp;
    			d_pmem_resp  = '0;
			pmem_read = i_read_in;
			pmem_write = '0;
		end 
		//Considers when i_read is o or high at the same time
		else if ((d_read_in || d_write_in)) begin 
 
			//servicing_i_cache = '0;
			//servicing_d_cache = '1;
			pmem_address = d_pmem_address;
    			i_pmem_resp = '0;
    			d_pmem_resp  = pmem_resp;
			pmem_read = d_read_in;
			pmem_write = d_write_in;
		end 
		else begin	
    			i_pmem_resp = '0;
    			d_pmem_resp  = '0;
    			pmem_address = '0;
    			pmem_read = '0;
    			pmem_write = '0;

		end 	*/   
        end 
	//Means we are servicing I cache 
        i_cache: 
        begin
    		i_pmem_resp = pmem_resp;
    		d_pmem_resp  = '0;
    		pmem_address = i_pmem_address;
    		pmem_read = i_read_in;
    		pmem_write = '0;
        end
	//We are servicing d cache
        d_cache:
        begin
    		i_pmem_resp = '0;
    		d_pmem_resp  = pmem_resp;
    		pmem_address = d_pmem_address;
    		pmem_read = d_read_in;
    		pmem_write = d_write_in;
        end
        default: ;
    endcase
end


always_comb 
begin: next_state_logic
    next_state = state;
    unique case(state)
        idle:begin
	    //If only the i_cache
            if(i_read_in && ~(d_read_in || d_write_in)) next_state = i_cache;
	    //if only the d_cache 
            else if(~i_read_in && (d_read_in || d_write_in)) next_state = d_cache;
	    //If both caches want to read
	    else if(i_read_in && (d_read_in || d_write_in))  next_state = d_cache;//Priority to data cache 
	    //Stay in the idle state
	    else next_state = idle;  
        end 
        i_cache:begin
	    if(i_mem_resp == '0)
		next_state = i_cache;
            //else if(i_mem_resp == 1'b1 && (d_write_in || d_read_in))
                //next_state = d_cache;
            else  next_state = idle;
        end 
        d_cache: begin 
            if(d_mem_resp == 1'b0)
                next_state = d_cache;
            //else if (pmem_resp == 1'b1 && (d_write_in||d_read_in))begin 
                //put a counter here so that we dont give priority to data too mnay times
                //counter = counter + 1'b1;
                //next_state = d_cache;
            //end 
            //else if(d_mem_resp == 1'b1 &&(i_read_in)) next_state = i_cache;

	    else next_state = idle;

            //if(counter == 2'b10)begin
                //No more data cache give 1 instruction read
                //counter = '0;
                //next_state = i_cache; //do not starve instructions
	        //end
        end
        default: ;
    endcase
end

always_ff @(posedge clk) 
begin: next_state_assignment
    if(rst) 
        state<=idle;

    else state<=next_state;
end

endmodule : arbiter
