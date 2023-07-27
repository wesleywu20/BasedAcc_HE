/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module i_cache #(
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

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp
);

//Outputs from bus adaptor to cache 
logic [255:0] mem_wdata256;//output
logic [255:0] mem_rdata256;//output
logic [31:0] mem_byte_enable256;//output


logic valid0, valid1,lru,hit0,hit1;
logic data_out_sel,data_in_sel,pmem_address_sel;
logic load0_valid,load1_valid,valid_in;
logic load0_tag,load1_tag;
logic load_lru, lru_in,read_all;
logic [31:0] load_data0_in,load_data1_in;



cache_control control
(
    .*,
    .read(mem_read),.write(mem_write),
    .pmem_resp(pmem_resp), .mem_byte_enable256(mem_byte_enable256),

     //inputs from datapath
    .hit0(hit0),.hit1(hit1),       
    .lru(lru),.valid0(valid0),.valid1(valid1),  
     //outputs
    .data_out_sel(data_out_sel), .data_in_sel(data_in_sel), .pmem_address_sel(pmem_address_sel),
    .read_all(read_all),
    .load_data0_in(load_data0_in),.load_data1_in(load_data1_in),
    .load_lru(load_lru), .lru_in(lru_in),
    .load0_valid(load0_valid), .load1_valid(load1_valid), .valid_in(valid_in),
    .load0_tag(load0_tag), .load1_tag(load1_tag),
    .mem_resp(mem_resp), .pmem_read(pmem_read), .pmem_write(pmem_write)

);

cache_datapath datapath
(
    .*,
    .read(mem_read),.write(mem_write),
    .pmem_rdata(pmem_rdata),
    .mem_wdata256(mem_wdata256),
    //comes from state machine
    .read_all(read_all),
    .valid_in(valid_in),
    .lru_in(lru_in),

    .load_data0_in(load_data0_in),   .load_data1_in(load_data1_in),
    .load0_tag(load0_tag),.load1_tag(load1_tag),
    .load0_valid(load0_valid),.load1_valid(load1_valid),
    .load_lru(load_lru),

    //Inputs for muxes coming from the controller
    .data_in_sel(data_in_sel),//If 0 we choose CPU DATA if 1 memory data
    .data_out_sel(data_out_sel),//if 0 we choose the data from way0 otherwise choose the data from way
    .pmem_address_mux_sel(pmem_address_sel),

    //passed to state machine , 
    .valid0_out(valid0),
    .valid1_out(valid1),
    .lru_out(lru),
    .hit0(hit0),
    .hit1(hit1),

    .data_out(mem_rdata256),
    .pmem_address(pmem_address) 
   

);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256),
    .mem_rdata256(mem_rdata256),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),
    .mem_byte_enable(mem_byte_enable),
    .mem_byte_enable256(mem_byte_enable256),
    .address(mem_address) //input from cpu
);

endmodule : i_cache
