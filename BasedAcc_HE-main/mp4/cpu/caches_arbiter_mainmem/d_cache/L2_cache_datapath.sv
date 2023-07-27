//8 kB cache 2 sets 
//5 bits for index  32 byte cacheline 
//8kb/(256 bits*2) = 2 13/2 9 = 2  4 = 16 lines in the cache  index = 4 bits
//address is 32 bits which allows for         23+4+5
/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module L2_cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,
	
	//cpu signals
    input   logic [31:0]    mem_address,
    output  logic [255:0]    mem_rdata,
    input   logic [255:0]    mem_wdata,
    input   logic [32:0]     mem_byte_enable,
    input logic mem_read, mem_write,

	//mem signals
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,

	//load signals

	input load_tag_0,
	input load_tag_1,
	input load_lru,
	input load_valid_0,
	input load_valid_1,

	//dirty
	input logic load_dirty_0,
	input logic load_dirty_1,
	input logic dirty_in_0,
	input logic dirty_in_1,
	output logic dirt_0,
	output logic dirt_1,
	
	input logic [1:0] update,
	output replace,
	output tag_0_hit,
	output tag_1_hit,
	input data_select,
	input write_way,
	input logic pmem_out_sel,
        input logic mem_resp
);


logic [255:0] datain,data_out_0,data_out_1,data_out,bus_out,r_data;
logic [31:0] write_en_0,write_en_1,write_en;
logic [s_index-1:0] rindex,windex;
logic [s_tag-1:0] tag_0,tag_1,tag_in;
logic valid_0,valid_1,valid_in_0,valid_in_1,lru_next,lru;
logic dirty_0,dirty_1;

logic replace_hold,tag_0_hit_hold,tag_1_hit_hold;

assign write_en = mem_byte_enable;
assign rindex =  mem_address[8:5];
assign windex =  mem_address[8:5];
assign tag_in = mem_address[31:9];
assign replace = replace_hold;
assign tag_0_hit = tag_0_hit_hold;
assign tag_1_hit = tag_1_hit_hold;


data_array_d 
#(
    .s_offset(s_offset),
    .s_index(s_index)
)
w0(
.clk(clk),
.read(1'b1),
.write_en(write_en_0),
.rindex(rindex),
.windex(windex),
.datain(datain),
.dataout(data_out_0)
);


data_array_d 
#(
    .s_offset(s_offset),
    .s_index(s_index)
)
w1(
.clk(clk),
.read(1'b1),
.write_en(write_en_1),
.rindex(rindex),
.windex(windex),
.datain(datain),
.dataout(data_out_1)
);

array_d #(
    .s_index(s_index),
    .width(s_tag)
)
tag_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_0),
    .rindex(rindex),
    .windex(windex),
    .datain(tag_in),
    .dataout(tag_0)
);


array_d #(
    .s_index(s_index),
    .width(s_tag)
)

tag_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_1),
    .rindex(rindex),
    .windex(windex),
    .datain(tag_in),
    .dataout(tag_1)
);

array_d #(
    .s_index(s_index),
    .width(1)
)

lru_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_lru),
    .rindex(rindex),
    .windex(windex),
    .datain(lru_next),
    .dataout(lru)
);

array_d #(
    .s_index(s_index),
    .width(1)
)

valid_0_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_0),
    .rindex(rindex),
    .windex(windex),
    .datain(valid_in_0),
    .dataout(valid_0)
);

array_d #(
    .s_index(s_index),
    .width(1)
)

valid_1_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_1),
    .rindex(rindex),
    .windex(windex),
    .datain(valid_in_1),
    .dataout(valid_1)
);

array_d #(
    .s_index(s_index),
    .width(1)
)

dirty_0_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_0),
    .rindex(rindex),
    .windex(windex),
    .datain(dirty_in_0),
    .dataout(dirty_0)
);

array_d #(
    .s_index(s_index),
    .width(1)
)

dirty_1_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_1),
    .rindex(rindex),
    .windex(windex),
    .datain(dirty_in_1),
    .dataout(dirty_1)
);

assign bus_out = mem_wdata;
//assign mem_rdata = data_out; 
always_comb begin
	if(mem_resp)
		mem_rdata = data_out; 
	else mem_rdata = r_data;

end

always_ff @(posedge clk)
begin
	if(mem_resp) r_data <= data_out;
end
/*bus_adapter_d
ba0(
    .mem_wdata256(bus_out),
    .mem_rdata256(data_out),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(write_en),
    .address(mem_address)
);*/

always_comb begin

	case(pmem_out_sel)
		1'b0: pmem_address = {mem_address[31:5],5'b0}; 
		1'b1: begin
				case(replace)
					1'b0: pmem_address = {tag_0[s_tag-1:0],mem_address[8:5],5'b0}; 
					1'b1: pmem_address = {tag_1[s_tag-1:0],mem_address[8:5],5'b0}; 
			    endcase
			  end
	endcase

	case(data_select)
		1'b0: datain = bus_out;
		1'b1: datain = pmem_rdata;
	endcase

	case(replace)
		1'b0: pmem_wdata = data_out_0;
		1'b1: pmem_wdata = data_out_1;
	endcase
	case(tag_0_hit)
		1'b0: data_out= data_out_1;
		1'b1: data_out= data_out_0;
	endcase

	case(tag_1_hit)
		1'b0: data_out= data_out_0;
		1'b1: data_out= data_out_1;
	endcase

	case((tag_0 == tag_in) && valid_0 && (mem_read | mem_write))
		1'b0: tag_0_hit_hold = 1'b0;
		1'b1: tag_0_hit_hold = 1'b1;
	endcase

	case((tag_1 == tag_in) && valid_1 && (mem_read | mem_write))
		1'b0: tag_1_hit_hold = 1'b0;
		1'b1: tag_1_hit_hold = 1'b1;
	endcase

	case(update)
		2'b00: begin
				  write_en_0 = 32'b0;
				  write_en_1 = 32'b0;
				  valid_in_0 = 1'b0;
				  valid_in_1 = 1'b0;
			  end
		2'b10: begin
				write_en_0 = 32'hFFFFFFFF;
				write_en_1 = 32'b0;
				valid_in_0 = 1'b1;
				valid_in_1 = 1'b0;
			  end
		2'b01: begin
				write_en_0 = 32'b0;
				write_en_1 = 32'hFFFFFFFF;
				valid_in_0 = 1'b0;
				valid_in_1 = 1'b1;
			  end
		2'b11: begin
				case(write_way)
					1'b0:begin
						write_en_0 = write_en;
						write_en_1 = 32'h0;
						valid_in_0 = 1'b0;
						valid_in_1 = 1'b1;
						end
					1'b1:
						begin
						write_en_0 = 32'b0;
						write_en_1 = write_en;
						valid_in_0 = 1'b0;
						valid_in_1 = 1'b1;
						end
				endcase
			  end
		default: begin
				write_en_0 = 32'b0;
				write_en_1 = 32'b0;
				valid_in_0 = 1'b0;
				valid_in_1 = 1'b0;

		end

	endcase
	

end

always_comb begin
	  if(!valid_0) begin
		 replace_hold = 1'b0;
	  end
	  else if(!valid_1) begin
		 replace_hold = 1'b1;
	  end
	  else if(lru) begin
		 replace_hold = 1'b1;
	  end
	  else begin
		 replace_hold = 1'b0;
	  end

end

assign lru_next = tag_0_hit;
assign dirt_0 = dirty_0 && valid_0;
assign dirt_1 = dirty_1 && valid_1;

endmodule : L2_cache_datapath
