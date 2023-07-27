/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath #(
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
    input logic [31:0] mem_address,
    input logic read,write,
    //data from bus adapter
    //data from memory from the cache line adapter
    input logic [255:0] pmem_rdata,//data from main memory in a miss
    input logic [255:0] mem_wdata256,//data from the cpu to write 
    //comes from state machine
    input logic read_all,

    input logic valid_in,
    input logic lru_in,

    input logic [31:0] load_data0_in,load_data1_in,
    input logic load0_tag,load1_tag,

    input logic load0_valid,load1_valid,
    input logic load_lru,

    //Inputs for muxes coming from the controller
    input logic data_in_sel,//If 0 we choose CPU DATA if 1 memory data
    input logic data_out_sel,//if 0 we choose the data from way0 otherwise choose the data from way
    input logic pmem_address_mux_sel,
 
    output logic valid0_out,
    output logic valid1_out,
    output logic lru_out,
    output logic hit0,
    output logic hit1,

    output logic [255:0] data_out,
    output logic [31:0] pmem_address
);
assign pmem_address = {mem_address[31:5],5'b0};

logic [255:0] data_in_mux_out,data0_out,data1_out;
logic [23:0] tag0_out,tag1_out;

always_comb 
begin
    if((read ||write) &&(tag0_out==mem_address[31:8])&&valid0_out) 
	hit0=1'b1;
    else 
	hit0=1'b0;
end
always_comb 
begin
    if((read ||write) &&(tag1_out==mem_address[31:8])&&valid1_out)
	hit1=1'b1;
    else 
	hit1=1'b0;
end

cache_way cache_way0(
    .*,
    .mem_byte_enable256(load_data0_in),
    .data_in(data_in_mux_out),
    .valid_in(valid_in),
    .read_all(read_all),
    .load_tag(load0_tag),
    .load_valid(load0_valid),
    .data_out(data0_out),
    .tag_out(tag0_out),
    .valid_out(valid0_out)
   
);

//BAsed on a mux we decide if we want to pass mem_byte_enable as 0's if we dont write
//And otherwise pass the actual membyteenable

//Based on the mux we decide whether datain is coming from cpu or main memory
cache_way cache_way1(
    .*,
    .mem_byte_enable256(load_data1_in), 
    .data_in(data_in_mux_out),
    .valid_in(valid_in),
    .read_all(read_all),
    .load_tag(load1_tag),
    .load_valid(load1_valid),
    .data_out(data1_out),
    .tag_out(tag1_out),
    .valid_out(valid1_out)
   
);

array  #(3,1)lru
(
    .*,
    .read(read_all),
    .load(load_lru),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(lru_in),
    .dataout(lru_out)
);
mux2to1 #(256)data_in_mux(.d0(mem_wdata256),.d1(pmem_rdata),.s(data_in_sel),.y(data_in_mux_out));

mux2to1 #(256)data_out_mux(.d0(data0_out),.d1(data1_out),.s(data_out_sel),.y(data_out));


endmodule : cache_datapath
