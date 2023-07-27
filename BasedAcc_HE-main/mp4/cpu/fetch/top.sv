
//Module between Tomasulo CPU and cache 
import rv32i_types::*; 

module top(
    input clk,
    input rst, 
//Input data_cache 
    input logic[31:0] i_cache,
    input logic mem_resp,station_ready,

    output logic not_empty,
    output logic[31:0] cache_pc,
    //output logic[31:0] current_pc,
    // Cpu Signals
    output logic[31:0] inst_pc,
    output rv32i_opcode opcode,  
    output logic [4:0] rs1, rs2, rd,
    output logic [2:0] funct3,
    output logic [31:0] imm_val,
    output logic [6:0] funct7,

    //output logic imm_on,
    output logic enqueue_assert,
    output logic dequeue_assert, //tells arapan that dequeue has happened

    output logic i_mem_read,
    input logic flush,
    input logic branch_complete,
    input logic [2:0]branch_ID_i,
    input logic [31:0]branch_result,

    output logic [2:0]branch_ID_o,
    output logic [31:0]prediction,
    output logic [31:0] instruction_,
    output logic [31:0] b_imm_o,
    output logic [31:0] j_imm_o

);

logic queue_ready,load_queue, load_pc_decode;
logic [31:0] current_pc;
logic [2:0] branch_id;
instr_struct decoded_I,data_o;


I_fetch fetch_I(
    .clk(clk),
    .rst(rst), 
    .mem_resp(mem_resp),
    .queue_ready(queue_ready), //input 

    .decoded_update(decoded_I), // after decoding
    .get_next_pc(load_queue),//from instruction queue

    .cache_pc(cache_pc),
    .current_pc(current_pc),

    .i_mem_read(i_mem_read),

    .branch_complete(branch_complete),
    .branch_ID_i(branch_ID_i),
    .branch_result(branch_result),
    .flush(flush),
    .prediction(prediction),
    .branch_ID_o(branch_id),
    .load_pc(load_pc_decode)
);

decode decode_I(
    .clk(clk),
    .rst(rst),
	.flush_i(flush),
    .reset(rst), 
    .i_cache(i_cache),
    .pc(current_pc),
    .load_ir(load_pc_decode),
	.branch_id(branch_id),
    .instruction(decoded_I),
    .load_queue(load_queue)
);

I_queue queue_I(
    .clk_i(clk),
    .reset_n_i(rst),
    .flush(flush),
   

    .data_i(decoded_I),
    .valid_i(load_queue),	//the new decoded inst
    .ready_o(queue_ready), 	//ready to take another instruction in queue

    .valid_o(not_empty),		//not empty
    .data_o(data_o),		//dequeued data
    .yumi_i(station_ready),	//if a reserveation station is free 
    //.assert_o(dequeue_assert)		//dequeued data is in output buffer

    .enqueue_assert(enqueue_assert),
    .dequeue_assert(dequeue_assert)
);

assign opcode = data_o.opcode;
assign funct3 = data_o.funct3;
assign rs1 = data_o.rs1;
assign rs2 = data_o.rs2;
assign rd = data_o.rd;
assign inst_pc = data_o.pc;
assign funct7 = data_o.funct7;
assign b_imm_o = data_o.b_imm;
assign j_imm_o = data_o.j_imm;
assign instruction_ = data_o.instruction;
assign branch_ID_o = data_o.branch_id;

always_comb begin
    unique case (data_o.opcode)
    	7'b0110111: 				//load upper immediate (U type) lui
		imm_val = data_o.u_imm;
        7'b0010111: 				//add upper immediate PC (U type) auipc
		imm_val = data_o.u_imm + inst_pc;
    	7'b1101111: 				//jump and link (J type) jal
		imm_val = data_o.j_imm;
    	7'b1100111: 				//jump and link register (I type) jalr
		imm_val = data_o.i_imm;
    	7'b1100011: 				//branch (B type) br
		imm_val = data_o.b_imm;
    	7'b0000011: 				//load (I type) load
		imm_val = data_o.i_imm;
    	7'b0100011: 				//store (S type) store
		imm_val = data_o.s_imm;
    	7'b0010011: 				//arith ops with register/immediate operands (I type) imm
		imm_val = data_o.i_imm;
    	7'b0110011: 				//arith ops with register operands (R type) reg
		;
    	7'b1110011: 				//control and status register (I type) csr
		imm_val = data_o.i_imm;
	default: ;
    endcase
end

endmodule : top
