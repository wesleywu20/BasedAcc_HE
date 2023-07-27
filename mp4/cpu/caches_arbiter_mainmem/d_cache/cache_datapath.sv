/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath_d #(
    parameter s_offset = 5,
    parameter s_index  = 3,
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
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic [3:0]     mem_byte_enable,

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
	input logic pmem_out_sel
);


logic [255:0] datain,data_out_0,data_out_1,data_out,bus_out;
logic [31:0] write_en_0,write_en_1,write_en;
logic [23:0] tag_0,tag_1;
logic valid_0,valid_1,valid_in_0,valid_in_1,lru_next,lru;
logic dirty_0,dirty_1;

logic replace_hold,tag_0_hit_hold,tag_1_hit_hold;

assign replace = replace_hold;
assign tag_0_hit = tag_0_hit_hold;
assign tag_1_hit = tag_1_hit_hold;


data_array_d w0(
.clk(clk),
.read(1'b1),
.write_en(write_en_0),
.rindex(mem_address[7:5]),
.windex(mem_address[7:5]),
.datain(datain),
.dataout(data_out_0)
);


data_array_d w1(
.clk(clk),
.read(1'b1),
.write_en(write_en_1),
.rindex(mem_address[7:5]),
.windex(mem_address[7:5]),
.datain(datain),
.dataout(data_out_1)
);

array_d #(
    .s_index(3),
    .width(24)
)
tag_array_0(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_0)
);


array_d #(
    .s_index(3),
    .width(24)
)

tag_array_1(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_1)
);

array_d #(
    .s_index(3),
    .width(1)
)

lru_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_lru),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(lru_next),
    .dataout(lru)
);

array_d #(
    .s_index(3),
    .width(1)
)

valid_0_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(valid_in_0),
    .dataout(valid_0)
);

array_d #(
    .s_index(3),
    .width(1)
)

valid_1_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(valid_in_1),
    .dataout(valid_1)
);

array_d #(
    .s_index(3),
    .width(1)
)

dirty_0_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(dirty_in_0),
    .dataout(dirty_0)
);

array_d #(
    .s_index(3),
    .width(1)
)

dirty_1_array(
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(dirty_in_1),
    .dataout(dirty_1)
);

bus_adapter_d
ba0(
    .mem_wdata256(bus_out),
    .mem_rdata256(data_out),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(write_en),
    .address(mem_address)
);

always_comb begin

	case(pmem_out_sel)
		1'b0: pmem_address = {mem_address[31:5],5'b0}; 
		1'b1: begin
				case(replace)
					1'b0: pmem_address = {tag_0[23:0],mem_address[7:5],5'b0}; 
					1'b1: pmem_address = {tag_1[23:0],mem_address[7:5],5'b0}; 
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
		1'b1: data_out= data_out_0;
		1'b0: data_out= data_out_1;

	endcase

	case(tag_1_hit&~tag_0_hit)
		1'b0: data_out= data_out_0;
		1'b1: data_out= data_out_1;
	endcase

	case((tag_0 == mem_address[31:8]) && valid_0)
		1'b0: tag_0_hit_hold = 1'b0;
		1'b1: tag_0_hit_hold = 1'b1;
	endcase

	case((tag_1 == mem_address[31:8]) && valid_1)
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

endmodule : cache_datapath_d
