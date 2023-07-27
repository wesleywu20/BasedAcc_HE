module based_cpu 
import rv32i_types::*;
(
	input clk, 
	input rst,

	input pmem_resp,
	input [63:0]pmem_rdata,
	output logic pmem_read,
	output logic pmem_write,
	output rv32i_word pmem_address,
	output [63:0]pmem_wdata


);


//Intermediate logic 

logic [31:0] cache_pc;
logic [31:0] i_cache;
logic [31:0] imm_val;
logic station_ready,dequeue_assert;
rv32i_opcode opcode;
logic [4:0] rs1,rs2,rd;
logic [2:0] funct3;
logic [6:0] funct7;
logic [31:0] address_d_cache;
logic [31:0] data_ld;
logic [31:0] data_d_cache;
logic d_mem_read,i_mem_read;
logic d_mem_write;
logic d_mem_resp;
logic mem_resp;
logic branch_complete;
logic flush;

logic [3:0] mem_byte_enable;
logic [2:0]brID_ex_to_fetch;
logic [2:0]brID_fetch_to_ex;

logic [31:0] branch_result;
logic [31:0] prediction;
logic [31:0] inst_pc,instruction_,b_imm,j_imm;

logic [63:0] done_mul;
based_mul m0(
	.a(pmem_rdata[31:0]),
	.b(pmem_rdata[63:32]),
	.f(done_mul)
);

top fetch_top(
    .clk(clk),
    .rst(rst), 
    //Instruction Cache
    .i_mem_read(i_mem_read),
    .i_cache(i_cache),
    .cache_pc(cache_pc),
    .mem_resp(mem_resp),

    .station_ready(station_ready),
    .not_empty(dequeue_assert),

    //output logic[31:0] current_pc,
    // Cpu Signals
    .inst_pc(inst_pc),
    .opcode(opcode),  
    .rs1(rs1), 
    .rs2(rs2), 
    .rd(rd),
    .funct3(funct3),
    .imm_val(imm_val),
    .funct7(funct7),

    //output logic imm_on,
    .enqueue_assert(),
    .dequeue_assert(), //tells arapan that dequeue has happened

    .flush(flush),
    .branch_complete(branch_complete),
    .branch_ID_i(brID_ex_to_fetch),
    .branch_result(branch_result),

    .branch_ID_o(brID_fetch_to_ex),
    .prediction(prediction),
    .instruction_(instruction_),
    .b_imm_o(b_imm),
    .j_imm_o(j_imm)
);


arbiter_cache cache_top (
    .clk(clk),
    .rst(rst), 
    // CPU memory signals
    .i_mem_address(cache_pc),
    .d_mem_address(address_d_cache),
    .i_mem_rdata(i_cache),//back to cpu
    .d_mem_rdata(data_ld),//back to cpu 
    .d_mem_wdata(data_d_cache),
    .i_mem_read(i_mem_read),
    .d_mem_read(d_mem_read),
    .d_mem_write(d_mem_write),
    .d_mem_byte_enable(mem_byte_enable),
    .i_mem_resp(mem_resp),//back to cpu
    .d_mem_resp(d_mem_resp),//back to cpu 

    //Physical memory 
    .pmem_resp(pmem_resp),
    .pmem_rdata(pmem_rdata),
    .pmem_read(pmem_read),
    .pmem_write(pmem_write),
    .pmem_address(pmem_address),
    .pmem_wdata(pmem_wdata)
);


tomasulo tomasulo0 (
    .clk(clk),
    .reset(rst), 
	
    .iq_assert(dequeue_assert), //assert from IQ, saying its ready
    .iq_read(station_ready), //saying it can assert a new command//saying it can assert a new command

    .inst_pc(inst_pc),
    .instruction_i(instruction_),

    .rd(rd),
    .r1_i(rs1),
    .r2_i(rs2),//inital load from regs
    .src2_i(imm_val),//initial load from reg/rob
    .opcode_i(opcode),

    .pc_save(brID_fetch_to_ex), //pc of the branch(in event of mispredict)
    .target_predict_i(prediction),//for jalr what is the predicted target

	//input logic [2:0] funct3,
    .funct7(funct7),
    .funct3(funct3), //alu type from IQ

    .flush(flush),
    .branch_complete(branch_complete),

    .pc_send(brID_ex_to_fetch),//next instruction addr for next instruction
    .branch_result(branch_result),

    .mem_resp(d_mem_resp),
    .mem_read(d_mem_read),
    .mem_write(d_mem_write),

    .address_d_cache(address_d_cache),
    .data_d_cache(data_d_cache),
    .data_ld(data_ld),
    .mem_byte_enable(mem_byte_enable),

    .b_imm(b_imm),
    .j_imm(j_imm)
);

endmodule
