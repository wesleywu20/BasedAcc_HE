module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [3:0] read_ready,write_ready;
logic [255:0] read_cache,write_cache;
logic resp_read,resp_write,read_stall,write_stall;
logic read_on,write_on,write_enter;
assign line_o = read_cache;
assign burst_o = write_cache[(write_ready)*64 +: 64];
assign address_o = address_i;
assign read_o = read_on;
assign write_o = write_on;
assign resp_o = resp_read || resp_write;


always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n)begin
       read_ready <= 4'd0; 
       read_cache <= 256'd0;
       resp_read <= 1'b0;
       read_on <= 1'b0;
	   read_stall <= 1'b0;

    end 

    else if((resp_i  && read_on) || read_ready)begin
		read_cache[(read_ready+1)*64 -1 -: 64] <= burst_i;
		if(read_ready == 3)begin
			resp_read <= 1'b1;
			read_ready <= 4'd0;
			read_on <= 1'b0;
			read_stall <= 1'b1;
		end
		else begin
			read_ready <= read_ready+ 4'd1;
			resp_read <= 1'b0;
			read_on <= 1'b1;
			read_stall <= 1'b0;
		end
    end

    else if(read_stall) begin
				read_stall<= 1'b0;
				resp_read <= 1'b0;
				end
    else if(read_i) read_on <= 1'b1;

    else begin
	    read_ready <= read_ready;
	    read_cache <= read_cache;
	    resp_read <= 1'b0;
        read_on <= read_on;
	    read_stall <= read_stall;

    end
	
end

always_ff @(posedge clk,negedge reset_n) begin
    if(!reset_n)begin
       write_ready <= 4'd0; 
       write_cache <= 256'd0;
       resp_write <= 1'b0;
       write_on <= 1'b0;
       write_enter <= 1'b0;
	   write_stall<= 1'b0;

    end 

    else if((resp_i && write_on) || write_ready)begin
		if(write_ready == 3)begin
		resp_write <= 1'b1;
		write_ready <= 4'd0;
		write_on <= 1'b0;
		write_cache <= write_cache;
		write_stall <= 1'b1;
		end

		else begin
		write_ready <= write_ready+ 4'd1;
		resp_write <= 1'b0;
		write_on <= 1'b1;
		write_cache <= write_cache;
		write_stall <= 1'b0;
		end

    end
    else if(write_stall) begin
						write_stall<= 1'b0;
						resp_write <= 1'b0;
						end
    else if(write_i) begin
	write_on <= 1'b1;
	write_cache <= line_i;
    end

    else begin
	    write_ready <= write_ready;
	    write_cache <= write_cache;
        resp_write <= 1'b0;
	    write_on <= write_on;
	    write_enter <= write_enter;
	   write_stall<= write_stall;
    end
	
end



endmodule : cacheline_adaptor
