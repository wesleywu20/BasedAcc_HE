module rob
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_instruction, //when IQ asserts
	//from IQ
    input logic [4:0] reg_num_i,//the reg to write back to
	input rv32i_opcode opcode_i,
	input logic [31:0] imm_data,
	input logic [2:0] pc_save_i,

	output [4:0] reg_id_o,
	input command_buffer cmd_buf_alu,//cmd buffer
	input command_buffer cmd_buf_branch,//cmd buffer
	input command_buffer cmd_buf_ld_str,//cmd buffer

	input command_buffer cmd_buf_mul,//cmd buffer
	input command_buffer cmd_buf_div,//cmd buffer
	input command_buffer cmd_buf_accel,//cmd buffer

    input logic [4:0] src_a, src_b,//up to 2 selects for data in rob
	output logic [4:0] reg_id_a, reg_id_b,
    output logic [31:0] reg_a, reg_b,//the 2 potential reads
	output logic free, //1 if there is a free spot

	output logic [4:0] reg_id_wb,
	output logic [4:0] reg_select,
	output logic reg_wb, flush,

	output logic store_ready,
	output logic load_ready,
	input logic mem_resp,

	input logic [31:0] target_predict_i,
	output logic branch_complete,
	output logic [2:0] pc_flush_o,
	output logic [31:0] pc_target,//in branches it will be a 0 if NT and a 1 if T
									//in jalr it will be the target address
	output logic [31:0] reg_data,
	input logic [31:0] instruction_i,
	input logic [31:0] inst_pc,
	input logic [31:0] b_imm_i,
	input logic [31:0] j_imm_i
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [4:0] reg_id [8];
logic [4:0] reg_num [8];
logic valid [8];
logic [31:0] data [8];
logic [2:0] pc_save [8];
logic [31:0] target_predict [8];
logic [31:0] jal_save [8];
logic [31:0] instruction [8];
logic [31:0] instr_pc_ [8];
logic [31:0] b_imm [8];
logic [31:0] j_imm [8];
rv32i_opcode opcode [8];

logic [7:0] load_data_alu,load_data_branch,load_data_ld_str,load_data_mul,load_data_div,load_data_accel;
logic [2:0] head_pointer;
logic [2:0] tail_pointer;
logic [3:0] size;
logic load_new,write_back;

assign load_new = load_instruction & free;
assign reg_id_o = reg_id[tail_pointer];


always_comb begin
	if(size == 4'd8)begin
		free = 1'b0;

	end
	else begin
		free = 1'b1;
	end
end


always_comb begin
	for(int i=0;i<8;i=i+1)begin
		if(reg_id[i] == cmd_buf_alu.reg_id) load_data_alu[i] = 1'b1;
		else load_data_alu[i] = 1'b0;
		if(reg_id[i] == cmd_buf_branch.reg_id) load_data_branch[i] = 1'b1;
		else load_data_branch[i] = 1'b0;
		if(reg_id[i] == cmd_buf_ld_str.reg_id) load_data_ld_str[i] = 1'b1;
		else load_data_ld_str[i] = 1'b0;
		if(reg_id[i] == cmd_buf_mul.reg_id) load_data_mul[i] = 1'b1;
		else load_data_mul[i] = 1'b0;
		if(reg_id[i] == cmd_buf_div.reg_id) load_data_div[i] = 1'b1;
		else load_data_div[i] = 1'b0;
		if(reg_id[i] == cmd_buf_accel.reg_id) load_data_accel[i] = 1'b1;
		else load_data_accel[i] = 1'b0;
	end
end

always_ff @(posedge clk)begin
    if (rst || flush)begin
		head_pointer <= 3'b0;
		tail_pointer <= 3'b0;
		size <= 4'b0;
    end
	else if(load_new && write_back)begin//load data fix it
		size <= size;
		tail_pointer <= tail_pointer +1'b1;
		head_pointer <= head_pointer + 1'b1;
	end
	else if(load_new)begin
		size <= size +1'b1;
		tail_pointer <= tail_pointer +1'b1;
	end
	else if(write_back)begin
		size <= size - 1'b1;
		head_pointer <= head_pointer + 1'b1;
	end
    else begin
		head_pointer <= head_pointer;
		tail_pointer <= tail_pointer;
		size <= size;
    end
end

always_comb begin

	if(write_back) begin
		if(opcode[head_pointer] == op_br)begin
			reg_wb = 1'b0;
			pc_flush_o = pc_save[head_pointer];
			pc_target = data[head_pointer];
			branch_complete = 1'b1;
			if(target_predict[head_pointer][0] == data[head_pointer][0])begin
				flush = 1'b0;
			end
			else begin
				flush = 1'b1;
			end
		end
		else if(opcode[head_pointer] == op_jalr)begin
			reg_wb = 1'b1;
			pc_flush_o = pc_save[head_pointer];
			pc_target = jal_save[head_pointer];
			branch_complete = 1'b1;
			if(target_predict[head_pointer] == jal_save[head_pointer])begin
				flush = 1'b0;
			end
			else begin
				flush = 1'b1;
			end
		end
		else if(opcode[head_pointer] == op_store ||opcode[head_pointer] == op_accel)begin
			reg_wb = 1'b0;
			flush = 1'b0;
			branch_complete = 1'b0;
		end
		else begin
			reg_wb = 1'b1;
			flush = 1'b0;
			branch_complete = 1'b0;
		end
	end
	else begin
		flush = 1'b0;
		reg_wb = 1'b0;
		branch_complete = 1'b0;
	end
end

always_comb begin

	if(opcode[head_pointer] == op_store && size)begin
		store_ready= 1'b1;
	end
	else begin
		store_ready= 1'b0;
	end

	if(opcode[head_pointer] == op_load && size)begin
		load_ready= 1'b1;
	end
	else begin
		load_ready= 1'b0;
	end
end
		
always_comb begin

	if(valid[head_pointer] && size)begin
		reg_select = reg_num[head_pointer];
		write_back = 1'b1;
		if(opcode[head_pointer] == op_jal || opcode[head_pointer] == op_jalr) begin
			reg_data = data[head_pointer];
			reg_id_wb = reg_id[head_pointer];
		end
		else begin
			reg_data = data[head_pointer];
			reg_id_wb = reg_id[head_pointer];
		end
	end
/*
	else if(store_ready && mem_resp)begin
		write_back = 1'b1;
	end
*/
	else begin
		reg_select = '0;
		write_back = '0;
		reg_data = '0;
		reg_id_wb = '0;
	end

end


always_ff @(posedge clk)
begin
    if (rst||flush) begin
        for (int i=0; i<8; i=i+1) begin
            valid[i] <= '0;
            reg_id[i] <= {2'b11,i[2:0]};
            reg_num[i] <= '0;
            data[i] <= '0;
			pc_save[i] <= '0;
			target_predict[i] <= '0;
			jal_save[i] <= '0;
		instruction[i] <='0;
		instr_pc_[i] <='0;
		b_imm[i] <='0;
		j_imm[i] <='0;
        end
    end
	if(load_new)begin
		reg_num[tail_pointer] <= reg_num_i;
		opcode[tail_pointer] <= opcode_i;
		pc_save[tail_pointer] <= pc_save_i;
		target_predict[tail_pointer] <= target_predict_i;
		instruction[tail_pointer] <= instruction_i;
		instr_pc_[tail_pointer] <= inst_pc;
		b_imm[tail_pointer] <= b_imm_i;
		j_imm[tail_pointer] <= j_imm_i;
		if(opcode_i == op_lui || opcode_i == op_auipc)begin
			valid[tail_pointer] <= '1;
			data[tail_pointer] <= imm_data;
			jal_save[tail_pointer] <= '0;
		end
		else if(opcode_i == op_jal) begin
			valid[tail_pointer] <= '1;
			data[tail_pointer] <= inst_pc+4;
			jal_save[tail_pointer] <= '0;
		end
		else if(opcode_i == op_jalr) begin
			valid[tail_pointer] <= '0;
			data[tail_pointer] <= inst_pc+4;
			jal_save[tail_pointer] <= 32'b1;
		end
		else begin
			valid[tail_pointer] <= '0;
			jal_save[tail_pointer] <= '0;
		end
	end
	if(write_back)begin
		valid[head_pointer] <= '0;
		reg_num[head_pointer] <= '0;
		data[head_pointer] <= '0;
		pc_save[head_pointer] <= '0;
		instr_pc_[head_pointer] <= '0;
		b_imm[head_pointer] <= '0;
		j_imm[head_pointer] <= '0;
	end
    for (int i=0; i<8; i=i+1) begin
		if(load_data_alu[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			if(jal_save[i])
				jal_save[i] <= cmd_buf_alu.data;
			else 
				data[i] <= cmd_buf_alu.data;
		end
		if(load_data_branch[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			data[i] <= cmd_buf_branch.data;
		end
		if(load_data_ld_str[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			data[i] <= cmd_buf_ld_str.data;
		end
		if(load_data_mul[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			data[i] <= cmd_buf_mul.data;
		end
		if(load_data_div[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			data[i] <= cmd_buf_div.data;
		end
		if(load_data_accel[i])begin
			valid[i] <= 1'b1;
			reg_num[i] <= reg_num[i];
			data[i] <= cmd_buf_div.data;
		end
	end
end

always_comb
begin
	if(valid[src_a[2:0]])begin
		reg_a = data[src_a[2:0]];
		reg_id_a = '0;
	end
	else if(load_data_alu[src_a[2:0]])begin
		reg_a = cmd_buf_alu.data;
		reg_id_a = '0;
	end
	else if(load_data_branch[src_a[2:0]])begin
		reg_a = cmd_buf_branch.data;
		reg_id_a = '0;
	end
	else if(load_data_ld_str[src_a[2:0]])begin
		reg_a = cmd_buf_ld_str.data;
		reg_id_a = '0;
	end
	else if(load_data_mul[src_a[2:0]])begin
		reg_a = cmd_buf_mul.data;
		reg_id_a = '0;
	end
	else if(load_data_div[src_a[2:0]])begin
		reg_a = cmd_buf_div.data;
		reg_id_a = '0;
	end
	else begin
		reg_a = '0;
		reg_id_a = reg_id[src_a[2:0]];
	end

	if(valid[src_b[2:0]])begin
		reg_b = data[src_b[2:0]];
		reg_id_b= '0;
	end
	else if(load_data_alu[src_b[2:0]])begin
		reg_b = cmd_buf_alu.data;
		reg_id_b = '0;
	end
	else if(load_data_branch[src_b[2:0]])begin
		reg_b = cmd_buf_branch.data;
		reg_id_b = '0;
	end
	else if(load_data_ld_str[src_b[2:0]])begin
		reg_b = cmd_buf_ld_str.data;
		reg_id_b = '0;
	end
	else if(load_data_mul[src_b[2:0]])begin
		reg_b = cmd_buf_mul.data;
		reg_id_b = '0;
	end
	else if(load_data_div[src_b[2:0]])begin
		reg_b = cmd_buf_div.data;
		reg_id_b = '0;
	end
	else begin
		reg_b = '0;
		reg_id_b = reg_id[src_b[2:0]];
	end
end

endmodule : rob
