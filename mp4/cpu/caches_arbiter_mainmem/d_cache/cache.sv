/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module d_cache #(
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

	//cache checks
	logic load_tag_0;
	logic load_tag_1;
	logic load_lru;
	logic load_valid_0;
	logic load_valid_1;
	logic load_dirty_0,load_dirty_1;
	logic dirty_in_0,dirty_in_1;
	logic dirt_0,dirt_1;
	
	logic [1:0] update;
	logic replace;
	logic tag_0_hit;
	logic tag_1_hit;
	logic data_select;
	logic write_way;
	logic pmem_out_sel;

cache_control_d control
(.*);

cache_datapath_d datapath
(.*);

endmodule : d_cache
