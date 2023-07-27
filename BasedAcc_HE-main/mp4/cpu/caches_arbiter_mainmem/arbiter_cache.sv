
module arbiter_cache
//Tomasulo-arbiter-mainmem
import rv32i_types::*;
(
    input clk,
    input rst,
    /* CPU memory signals */
    input   logic [31:0]    i_mem_address,
    input   logic [31:0]    d_mem_address,

    output  logic [31:0]    i_mem_rdata,//back to cpu
    output  logic [31:0]    d_mem_rdata,//back to cpu 

    input   logic [31:0]    d_mem_wdata,

    input   logic           i_mem_read,
    input   logic           d_mem_read,
    input   logic           d_mem_write,
    input   logic [3:0]     d_mem_byte_enable,
    output  logic           i_mem_resp,//back to cpu
    output  logic           d_mem_resp,//back to cpu 

    //Physical memory 
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

/* Physical memory signals */

logic [31:0] i_pmem_address;
logic [255:0] i_pmem_rdata, i_pmem_wdata;
logic i_pmem_read, i_pmem_write;


logic [31:0] d_pmem_address;
logic [255:0] d_pmem_rdata, d_pmem_wdata;
logic d_pmem_read, d_pmem_write; 

logic [31:0] pmem_address_adapt;
logic pmem_read_adapt,pmem_write_adapt,pmem_resp_adapt;

//New signals for L2 Cache
logic L2_resp,L2_read,L2_write;
logic [31:0] L2_address;
logic [255:0] pmem_rdata_adapt,pmem_wdata_adapt,L2_rdata,L2_wdata;

//Instruction cache 
i_cache i_cache(
.*,
    .mem_address(i_mem_address),
    .mem_rdata(i_mem_rdata),
    .mem_wdata('0), 	//non-functional for I cache 
    .mem_read(i_mem_read),          //from arbiter
    .mem_write('0), 		//non functional for I cache
    .mem_byte_enable('1),	//non-functional for I cache
    .mem_resp(i_mem_resp),
    //L2 cache
    .pmem_address(i_pmem_address),
    .pmem_rdata(L2_rdata),
    .pmem_wdata(i_pmem_wdata),//No effect
    .pmem_read(i_pmem_read),
    .pmem_write(i_pmem_write),
    .pmem_resp(i_pmem_resp)
);

//Data Cache 
d_cache d_cache(
.*,
    .mem_address(d_mem_address),
    .mem_rdata(d_mem_rdata),
    .mem_wdata(d_mem_wdata),
    .mem_read(d_mem_read),         //from arbiter
    .mem_write(d_mem_write),       //from arbiter
    .mem_byte_enable(d_mem_byte_enable),
    .mem_resp(d_mem_resp),
    //L2 Cache
    .pmem_address(d_pmem_address),
    .pmem_rdata(L2_rdata),
    .pmem_wdata(L2_wdata),
    .pmem_read(d_pmem_read),
    .pmem_write(d_pmem_write),
    .pmem_resp(d_pmem_resp)//we dont want both caches to see pmem_resp

);


//Arbiter
arbiter arbiter(
.*,
    .rst(rst),
    .i_read_in(i_pmem_read),
    .d_read_in(d_pmem_read),
    .d_write_in(d_pmem_write),
    .i_pmem_address(i_pmem_address),
    .d_pmem_address(d_pmem_address),
    .i_mem_resp(i_mem_resp),
    .d_mem_resp(d_mem_resp),

    .d_pmem_resp(d_pmem_resp),//output
    .i_pmem_resp(i_pmem_resp),//output
    //L2 Cache 
    .pmem_address(L2_address),//output
    .pmem_read(L2_read),//output
    .pmem_write(L2_write),//output

    .pmem_resp(L2_resp)//input
);


L2_cache L2_cache(
.*,
    .mem_address(L2_address),
    .mem_rdata(L2_rdata),
    .mem_wdata(L2_wdata),
    .mem_read(L2_read),         //from arbiter
    .mem_write(L2_write),       //from arbiter
    .mem_byte_enable('1),
    .mem_resp(L2_resp),
    //Pmem goes to cache line adapter
    .pmem_address(pmem_address_adapt),
    .pmem_rdata(pmem_rdata_adapt),
    .pmem_wdata(pmem_wdata_adapt),
    .pmem_read(pmem_read_adapt),
    .pmem_write(pmem_write_adapt),
    .pmem_resp(pmem_resp_adapt)
);

cacheline_adaptor
ca0(
    .clk(clk),
    .reset_n(~rst),

    // Port to LLC (Lowest Level Cache)
    .line_i(pmem_wdata_adapt), //write to pmem
    .line_o(pmem_rdata_adapt),//read data from pmem
    .address_i(pmem_address_adapt),
    .read_i(pmem_read_adapt), //data cache or i_cache
    .write_i(pmem_write_adapt),//from data cache 
    .resp_o(pmem_resp_adapt),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);


endmodule : arbiter_cache
