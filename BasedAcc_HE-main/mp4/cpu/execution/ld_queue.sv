module ld_queue
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_instruction, //when IQ asserts
	//from IQ
	//load new entry
    input logic [4:0] destination_i,//the reg to write back to
	input [2:0] funct3_i,
	input logic [4:0] r1_i,//inital load from reg/rob
	input logic [31:0] src1_i,//initial load from reg/rob
	input logic [31:0] imm_i,
	
	//wait for inputs to come in
	input command_buffer cmd_buf_alu,//cmd buffer

	input command_buffer cmd_buf_ld,
	input command_buffer cmd_buf_mul,
	input command_buffer cmd_buf_div,

	output [2:0] head_funct3,
	
	output logic head_ready,
	output logic [4:0] head_id,
	output logic [31:0] head_address,
	output logic [31:0] src1_out,

	input logic del_head,
	output logic free_o
);

logic [4:0] reg_num [4];
logic valid [4];//if entry is used
logic [31:0] data [4];

logic [2:0] funct3 [4];
logic [4:0] destination [4];
logic [4:0] r1 [4];
logic [31:0] src1 [4];


logic [31:0] imm [4];

logic [1:0] head_pointer;
logic [1:0] tail_pointer;
logic [2:0] size;
logic load_new;

assign load_new = load_instruction & free_o;
//assign head_ready = valid[head_pointer];
assign head_id = reg_num[head_pointer];
assign head_funct3 = funct3[head_pointer];
assign head_address = src1[head_pointer] + imm[head_pointer];
assign src1_out = src1[head_pointer];


always_comb begin
	if(valid[head_pointer]) head_ready = !(r1[head_pointer]);
	else head_ready = 1'b0;
end


always_comb begin
	if(size == 3'd4)begin
		free_o = 1'b0;
	end
	else begin
		free_o = 1'b1;
	end
end

/*
always_comb begin
	for(int i=0;i<4;i=i+1)begin
		if(reg_num[i] == cmd_buf_alu.reg_id) load_data_alu[i] = 1'b1;
		else load_data_alu[i] = 1'b0;
		if(reg_num[i] == cmd_buf_ld.reg_id) load_data_ld_str[i] = 1'b1;
		else load_data_ld_str[i] = 1'b0;
	end
end
*/

always_ff @(posedge clk)begin
    if (rst)begin
		head_pointer <= 2'b0;
		tail_pointer <= 2'b0;
		size <= 3'b0;
    end
	else if(load_new && del_head)begin//load data fix it
		size <= size;
		tail_pointer <= tail_pointer +1'b1;
		head_pointer <= head_pointer + 1'b1;
	end
	else if(load_new)begin
		size <= size +1'b1;
		tail_pointer <= tail_pointer +1'b1;
	end
	else if(del_head)begin
		size <= size - 1'b1;
		head_pointer <= head_pointer + 1'b1;
	end
    else begin
		head_pointer <= head_pointer;
		tail_pointer <= tail_pointer;
		size <= size;
    end
end

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i=0; i<4; i=i+1) begin
            reg_num[i] <= '0;
			funct3[i] <= '0;
            r1[i] <= '0;
            src1[i] <= '0;
			imm[i] <= '0;
			valid[i] <= '0;
        end
    end
	else if(load_new)begin
		reg_num[tail_pointer] <= destination_i;
		funct3[tail_pointer] <= funct3_i;
        r1[tail_pointer] <= r1_i;
        src1[tail_pointer] <= src1_i;
        imm[tail_pointer] <= imm_i;
		valid[tail_pointer] <= 1'b1;

		//for(int i=tail_pointer+1; i< (tail_pointer+4);i++ )begin
		for(int i=0; i< 4;i++ )begin
			if(i >= (tail_pointer+1) && i< (tail_pointer+4))begin
				if(valid[i])begin
					if(r1[i])begin
						if(r1[i] == cmd_buf_alu.reg_id)begin
							r1[i] <= '0;
							src1[i] <= cmd_buf_alu.data;
						end
						if(r1[i] == cmd_buf_ld.reg_id)begin
							r1[i] <= '0;
							src1[i] <= cmd_buf_ld.data;
						end
						if(r1[i] == cmd_buf_mul.reg_id)begin
							r1[i] <= '0;
							src1[i] <= cmd_buf_mul.data;
						end
						if(r1[i] == cmd_buf_div.reg_id)begin
							r1[i] <= '0;
							src1[i] <= cmd_buf_div.data;
						end
					end
				end
			end
		end

	end
	else if(del_head)begin
		valid[head_pointer] <= 1'b0;
		reg_num[head_pointer] <= '0;
		funct3[head_pointer] <= '0;
        r1[head_pointer] <= '0;
        src1[head_pointer] <= '0;
        imm[head_pointer] <= '0;
	end

	for(int i=0; i< 4;i++ )begin
		if(valid[i])begin
			if(r1[i])begin
				if(r1[i] == cmd_buf_alu.reg_id)begin
					r1[i] <= '0;
					src1[i] <= cmd_buf_alu.data;
				end
				if(r1[i] == cmd_buf_ld.reg_id)begin
					r1[i] <= '0;
					src1[i] <= cmd_buf_ld.data;
				end
				if(r1[i] == cmd_buf_mul.reg_id)begin
					r1[i] <= '0;
					src1[i] <= cmd_buf_mul.data;
				end
				if(r1[i] == cmd_buf_div.reg_id)begin
					r1[i] <= '0;
					src1[i] <= cmd_buf_div.data;
				end
			end
		end
	end
end

endmodule : ld_queue
