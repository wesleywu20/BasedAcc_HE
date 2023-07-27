module tomasulo
import rv32i_types::*;
(
    input logic clk,
    input logic reset,
	
	input logic iq_assert, //assert from IQ, saying its ready
	output logic iq_read, //saying it can assert a new command//saying it can assert a new command

	input logic [4:0] rd,
	input logic [4:0] r1_i,r2_i,//inital load from regs
	input logic [31:0] src2_i,//initial load from reg/rob
	input rv32i_opcode opcode_i,

	input logic [2:0] pc_save, //pc of the branch(in event of mispredict)
	input logic [31:0] target_predict_i,//for jalr what is the predicted target

	//input logic [2:0] funct3,
	input logic [6:0] funct7,
	input logic [2:0] funct3, //alu type from IQ

	output logic flush,
	output logic branch_complete,

	output logic [2:0] pc_send,//next instruction addr for next instruction
	output logic [31:0] branch_result,

	input logic mem_resp,
	output logic mem_read,
	output logic mem_write,

	output logic [31:0] address_d_cache,
	output logic [31:0] data_d_cache,
	input logic [31:0] data_ld,

	output [3:0] mem_byte_enable,

	input logic [31:0] inst_pc,
	input logic [31:0] instruction_i,
	input [31:0] b_imm,
	input [31:0] j_imm

);

logic [31:0] address_d_cache_ld,address_accel;
logic [31:0] st_data_str,st_data_accel;

logic mem_read_ld,mem_read_accel;
logic mem_write_str,mem_write_accel;

assign mem_read = mem_read_ld || mem_read_accel;
assign mem_write = mem_write_str || mem_write_accel;

always_comb begin
	if(mem_read_accel || mem_write_accel) address_d_cache = address_accel;
	else address_d_cache = address_d_cache_ld;
end

always_comb begin
	if(mem_write_accel) data_d_cache = st_data_accel;
	else data_d_cache = st_data_str;
end

command_buffer cmd_buf[6];
logic score_input;
logic free_alu_res,free_branch_res,free_rob,write_back_rob;
logic done_accel;

logic [4:0] reg_id_load,reg_id_wb,reg_sel_rob;
logic [4:0] score_a_regfile,score_b_regfile;
logic [4:0] reg_id_a_rob,reg_id_b_rob;
logic [4:0] r1_res,r2_res;
logic [31:0] src1_res,src2_res;
logic [31:0] reg_a_rob,reg_b_rob,reg_data_rob;
logic [31:0] reg_a_regfile,reg_b_regfile;
logic alu_instruction,imm,branch_instruction,rand_instruction,mul_instruction;
logic ld_instruction,str_instruction;
logic rand_free,cmp_free,alu_free;
logic ld_free,str_free;
logic regfile_load;
logic st_ready,ld_ready;
logic div_free,div_instruction;
logic free_mul,free_div,mul_free;
logic load_free;
logic accel_instruction,free_accel,accel_free;


assign iq_read = branch_instruction || alu_instruction || rand_instruction || ld_instruction || str_instruction || mul_instruction || div_instruction || accel_instruction;
assign regfile_load = alu_instruction || rand_instruction || ld_instruction || mul_instruction || div_instruction;

assign rand_free = free_rob;
assign cmp_free = free_branch_res && free_rob;
assign alu_free = free_alu_res && free_rob;
assign load_free= ld_free && free_rob;
assign store_free= str_free && free_rob;
assign mul_free = free_mul && free_rob;
assign div_free = free_div && free_rob;

assign accel_free = free_accel && free_rob;


assign accel_instruction = (opcode_i == op_accel) ? (iq_assert && accel_free):1'b0;

always_comb begin
	if(opcode_i == op_jal || opcode_i == op_lui || opcode_i == op_auipc) begin
		rand_instruction = iq_assert && rand_free;
	end
	else begin
		rand_instruction = 1'b0;
	end
end

always_comb begin
	if(opcode_i == op_br) begin
		branch_instruction = iq_assert && cmp_free;
	end
	else begin
		branch_instruction = 1'b0;
	end
end

always_comb begin
	if(opcode_i == op_load ) begin
		ld_instruction = iq_assert && load_free;
	end
	else begin
		ld_instruction = 1'b0;
	end

	if(opcode_i == op_store) begin
		str_instruction = iq_assert && store_free;
	end
	else begin
		str_instruction = 1'b0;
	end
end

always_comb begin

	if(opcode_i == op_imm ||opcode_i == op_jal ||opcode_i == op_jalr) begin
		imm = 1'b1;
	end
	else begin
		imm = 1'b0;
	end

end

always_comb begin
	if(opcode_i == op_jal || opcode_i == op_jalr|| opcode_i == op_imm) begin
		alu_instruction = iq_assert && alu_free;
		mul_instruction = 1'b0;
		div_instruction = 1'b0;
	end
	else if(opcode_i == op_reg)begin
		if(funct7[0] && !funct3[2])begin
			mul_instruction = iq_assert && mul_free;
			alu_instruction = 1'b0;
			div_instruction = 1'b0;
		end
		else if(funct7[0] && funct3[2])begin
			div_instruction = iq_assert && div_free;
			mul_instruction = 1'b0;
			alu_instruction = 1'b0;
		end
		else begin
			alu_instruction = iq_assert && alu_free;
			mul_instruction = 1'b0;
			div_instruction = 1'b0;
		end
	end
	else begin
		alu_instruction = 1'b0;
		mul_instruction = 1'b0;
		div_instruction = 1'b0;
	end
end

rob rob0
(
    .clk(clk),
    .rst(reset),
    .load_instruction(iq_read), //when IQ asserts
    .reg_num_i(rd),//the reg to write back to
	.opcode_i(opcode_i),
	.imm_data(src2_i),
	.inst_pc(inst_pc),
	.instruction_i(instruction_i),
	.target_predict_i(target_predict_i),
	.pc_save_i(pc_save),
	.pc_flush_o(pc_send),
	.pc_target(branch_result),
	.b_imm_i(b_imm),
	.j_imm_i(j_imm),
	.flush(flush),
	.store_ready(st_ready),
	.load_ready(ld_ready),
	.mem_resp(mem_resp),
	.branch_complete(branch_complete),
	.reg_id_o(reg_id_load),
	.cmd_buf_alu(cmd_buf[0]),//cmd buffer
	.cmd_buf_branch(cmd_buf[1]),//cmd buffer
	.cmd_buf_ld_str(cmd_buf[2]),//cmd buffer
	.cmd_buf_mul(cmd_buf[3]),//cmd buffer
	.cmd_buf_div(cmd_buf[4]),//cmd buffer
	.cmd_buf_accel(cmd_buf[5]),//cmd buffer
    .src_a(score_a_regfile),
    .src_b(score_b_regfile),//up to 2 selects for data in rob
    .reg_a(reg_a_rob),
	.reg_b(reg_b_rob),//the 2 potential reads
	.reg_id_a(reg_id_a_rob),
	.reg_id_b(reg_id_b_rob),
	.free(free_rob),//1 if there is a free spot
	.reg_select(reg_sel_rob),
	.reg_id_wb(reg_id_wb),
	.reg_wb(write_back_rob),
	.reg_data(reg_data_rob)
);

always_comb begin

	if(!score_a_regfile)begin
		r1_res = score_a_regfile;
		src1_res = reg_a_regfile;
	end
	else  begin
		r1_res = reg_id_a_rob;
		src1_res = reg_a_rob;
	end
end

always_comb begin

	if(imm)begin
		r2_res = '0;
		src2_res = src2_i;

	end
	else begin
		if(!score_b_regfile)begin
			r2_res = score_b_regfile;
			src2_res = reg_b_regfile;
		end
		else  begin
			r2_res = reg_id_b_rob;
			src2_res = reg_b_rob;
		end
	end
end
regfile regfile0
(
    .clk(clk),
    .rst(reset),
	.flush(flush),
    .load_new(regfile_load),
	.load_wb(write_back_rob),
    .in_regfile(reg_data_rob),
    .in_score_new(reg_id_load),
	.in_score_wb(reg_id_wb),
	.src_a(r1_i),
	.src_b(r2_i),
	.dest(reg_sel_rob),
	.load_dest(rd),
    .reg_a(reg_a_regfile), 
	.reg_b(reg_b_regfile),
    .score_a(score_a_regfile), 
	.score_b(score_b_regfile)
);


alu_res_station alu_res_station0
(
    .clk(clk),
    .reset(reset || flush),
	
	.iq_assert(alu_instruction),//assert from IQ, saying its ready

	.destination(reg_id_load),
	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.funct3(funct3),//alu type from IQ
	.funct7(funct7[5]),
	.imm(imm),
	.cmd_buf_alu(cmd_buf[0]),
	.cmd_buf_ld_str(cmd_buf[2]),

	.cmd_buf_mul(cmd_buf[3]),
	.cmd_buf_div(cmd_buf[4]),

	.free_o(free_alu_res)
);
cmp_res_station cmp_res_station0
(
    .clk(clk),
    .reset(reset||flush),
	
	.iq_assert(branch_instruction),//assert from IQ, saying its ready

	.destination(reg_id_load),
	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.funct3(funct3),//alu type from IQ

	.cmd_buf_alu(cmd_buf[0]),//cmd buffer
	.cmd_buf_ld_str(cmd_buf[2]),

	.cmd_buf_mul(cmd_buf[3]),
	.cmd_buf_div(cmd_buf[4]),

	.cmd_buf(cmd_buf[1]),

	.free_o(free_branch_res)
);

accel_res_station accel_res_station0
(
    .clk(clk),
    .reset(reset||flush),
	
	.iq_assert(accel_instruction),//assert from IQ, saying its ready

	.destination(reg_id_load),
	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.funct3(funct3),//alu type from IQ

	.cmd_buf_alu(cmd_buf[0]),//cmd buffer
	.cmd_buf_ld_str(cmd_buf[2]),

	.cmd_buf_mul(cmd_buf[3]),
	.cmd_buf_div(cmd_buf[4]),

	.cmd_buf(cmd_buf[5]),//accel bus

	.free_o(free_accel),

	.mem_read(mem_read_accel),
	.mem_write(mem_write_accel),
	.address(address_accel),
	.st_data(st_data_accel),

	.mem_resp(mem_resp),
	.data(data_ld)
);


ld_str_queue ld_str_0(
    .clk(clk),
    .rst(reset),
    .flush(flush),
    .load_ld(ld_instruction), //when IQ asserts
    .load_str(str_instruction), //when IQ asserts
	//from IQ
	//load new entry
    .destination(reg_id_load),//the reg to write back to
	.funct3(funct3),

	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.imm_i(src2_i),//initial load from reg/rob
	
	//wait for inputs to come in
	.cmd_buf_alu(cmd_buf[0]),//cmd buffer

	.cmd_buf_mul(cmd_buf[3]),//cmd buffer
	.cmd_buf_div(cmd_buf[4]),//cmd buffer

	.cmd_buf_ld(cmd_buf[2]),
	
	.mem_resp(mem_resp),
	.mem_read(mem_read_ld),
	.mem_write(mem_write_str),
	.address_d_cache(address_d_cache_ld),
	.data_d_cache(st_data_str),
	.data_ld(data_ld),
	.store_ready(st_ready),
	.load_ready(ld_ready),

	.free_load(ld_free),
	.free_store(str_free),
	.mem_byte_enable(mem_byte_enable)
);

mult_res_station mul0(
    .clk(clk),
    .reset(reset||flush),
	
	.iq_assert(mul_instruction),//assert from IQ, saying its ready

	.destination(reg_id_load),
	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.funct3(funct3),//alu type from IQ

	.cmd_buf_alu(cmd_buf[0]),//cmd buffer
	.cmd_buf_ld_str(cmd_buf[2]),
	.cmd_buf_div(cmd_buf[4]),

	.cmd_buf(cmd_buf[3]),

	.free_o(free_mul)
);

div_res_station div0(
    .clk(clk),
    .reset(reset||flush),
	
	.iq_assert(div_instruction),//assert from IQ, saying its ready

	.destination(reg_id_load),
	.r1_i(r1_res),
	.r2_i(r2_res),//inital load from reg/rob
	.src1_i(src1_res),
	.src2_i(src2_res),//initial load from reg/rob
	.funct3(funct3),//alu type from IQ

	.cmd_buf_alu(cmd_buf[0]),//cmd buffer
	.cmd_buf_ld_str(cmd_buf[2]),
	.cmd_buf_mul(cmd_buf[3]),

	.cmd_buf(cmd_buf[4]),

	.free_o(free_div)
);
endmodule : tomasulo
