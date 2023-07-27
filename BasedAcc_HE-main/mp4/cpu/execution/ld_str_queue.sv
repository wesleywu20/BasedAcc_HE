module ld_str_queue
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_ld, //when IQ asserts
    input load_str, //when IQ asserts
	input flush,
	//from IQ
	//load new entry
    input logic [4:0] destination,//the reg to write back to
	input logic [2:0] funct3,
	input logic [4:0] r1_i,r2_i,//inital load from reg/rob
	input logic [31:0] src1_i,src2_i,//initial load from reg/rob
	input logic [31:0] imm_i,
	
	//wait for inputs to come in
	input command_buffer cmd_buf_alu,//cmd buffer
	input command_buffer cmd_buf_mul,//cmd buffer
	input command_buffer cmd_buf_div,//cmd buffer

	output command_buffer cmd_buf_ld,
	
	input logic mem_resp,
	output logic mem_read,
	output logic mem_write,

	input store_ready,
	input load_ready,

	output logic [31:0] address_d_cache,
	output logic [31:0] data_d_cache,

	input logic [31:0] data_ld,

	output logic free_load,
	output logic free_store,
	output logic [3:0] mem_byte_enable
);



logic head_ready_ld,head_ready_str;
logic [4:0] head_id_ld,head_id_str;
logic [31:0] head_address_ld,head_address_str;
logic del_head_ld,del_head_str;
logic in_use_ld,in_use_str;
logic [2:0] funct3_ld,funct3_str;
logic [31:0] load_data;
logic [31:0] add_out;
logic [31:0] data_out_input;
logic flush_hold;
logic free_s,free_l;
logic mem_resp_hold;

assign address_d_cache = {add_out[31:2],2'b0};

assign free_store = !flush_hold && free_s;
assign free_load = !flush_hold && free_l;

always_ff @(posedge clk) begin
	if(rst) flush_hold <= 1'b0;
	else if(flush_hold == 2'b1 && mem_resp) flush_hold <= 2'd2;
	else if(flush_hold == 2'd2) flush_hold <= 2'b0;

	else if(flush && !mem_read && !mem_write) flush_hold <= 2'd2;
	else if(flush) flush_hold <= 2'b1;
end


always_ff @(posedge clk) begin
	if(rst) mem_resp_hold <= 1'b0;
	else if(mem_resp) mem_resp_hold <= 1'b1;
	else mem_resp_hold <= 1'b0;
end

always_comb begin

	if(!store_ready || mem_resp_hold)begin
		mem_write = 1'b0;
	end
	else begin
		mem_write = head_ready_str;
	end

end
always_comb begin

	if(!load_ready || mem_resp_hold)begin
		mem_read = 1'b0;
	end
	else begin
		mem_read = head_ready_ld;
	end
	//if(mem_resp) mem_read =1'b0;

end
/*
always_comb begin

	if(in_use_str && !mem_read)begin
		mem_read = 1'b0;
	end
	else begin
		mem_read = head_ready_ld;
	end

end
*/
always_comb begin

	if(mem_read) begin
		add_out	= head_address_ld;
	end
	else if(mem_write) begin
		add_out	= head_address_str;
	end
	else begin
		add_out= '0;
	end
end


always_comb begin

	if(mem_resp)begin
		if(mem_read) begin
			del_head_ld = 1'b1;
		end
		else begin
			del_head_ld = 1'b0;
		end

		if(mem_write) begin
			del_head_str = 1'b1;
		end
		else begin
			del_head_str = 1'b0;
		end
	end
	else begin
		del_head_str = 1'b0;
		del_head_ld = 1'b0;
	end
end


ld_queue ld_queue0(
    .clk(clk),
    .rst(rst ||flush),
    .load_instruction(load_ld), //when IQ asserts
    .destination_i(destination),//the reg to write back to
	.r1_i(r1_i),
	.src1_i(src1_i),
	.imm_i(imm_i),
	.funct3_i(funct3),

	.cmd_buf_alu(cmd_buf_alu),//cmd buffer
	.cmd_buf_mul(cmd_buf_mul),//cmd buffer
	.cmd_buf_div(cmd_buf_div),//cmd buffer

	.cmd_buf_ld(cmd_buf_ld),

	.head_ready(head_ready_ld),
	.head_id(head_id_ld),
	.head_address(head_address_ld),
	.head_funct3(funct3_ld),

	.del_head(del_head_ld),

	.free_o(free_l)
);


str_queue str_queue0(
    .clk(clk),
    .rst(rst ||flush),
    .load_instruction(load_str), //when IQ asserts
    .destination_i(destination),//the reg to write back to
	.funct3_i(funct3),
	.r1_i(r1_i),
	.r2_i(r2_i),//inital load from reg/rob
	.src1_i(src1_i),
	.src2_i(src2_i),//initial load from reg/rob
	.imm_i(imm_i),

	.cmd_buf_alu(cmd_buf_alu),//cmd buffer
	.cmd_buf_mul(cmd_buf_mul),//cmd buffer
	.cmd_buf_div(cmd_buf_div),//cmd buffer
	.cmd_buf_ld(cmd_buf_ld),

	.head_ready(head_ready_str),
	.head_id(head_id_str),
	.head_address(head_address_str),
	.head_data(data_out_input),

	.head_funct3(funct3_str),

	.del_head(del_head_str),

	.free_o(free_s),
	.in_use(in_use_str)
);

always_comb begin
	case(funct3_ld)
		3'b000: begin
					case(add_out[1:0])
					2'b00:load_data = {{24{data_ld[7]}}, data_ld[7:0]};
					2'b01:load_data = {{24{data_ld[15]}}, data_ld[15:8]};
					2'b10:load_data = {{24{data_ld[23]}}, data_ld[23:16]};
					2'b11:load_data = {{24{data_ld[31]}}, data_ld[31:24]};
					endcase
				end
		3'b001: begin 
					case(add_out[1])
						1'b0:load_data = {{16{data_ld[15]}}, data_ld[15:0]};
						1'b1:load_data = {{16{data_ld[31]}}, data_ld[31:16]};
					endcase
				end
		3'b010: load_data = data_ld[31:0];
		3'b100: begin
					case(add_out[1:0])
					2'b00:load_data = {24'b0, data_ld[7:0]};
					2'b01:load_data = {24'b0, data_ld[15:8]};
					2'b10:load_data = {24'b0, data_ld[23:16]};
					2'b11:load_data = {24'b0, data_ld[31:24]};
					endcase
				end
		3'b101: begin 
					case(add_out[1])
						1'b0:load_data = {16'b0, data_ld[15:0]};
						1'b1:load_data = {16'b0, data_ld[31:16]};
					endcase
				end
	endcase
end
always_comb begin
	unique case (funct3_str)
		3'b000: begin
					case(add_out[1:0])
					2'b00: data_d_cache= {24'b0,data_out_input[7:0]};
					2'b01: data_d_cache= {16'b0,data_out_input[7:0],8'b0};
					2'b10: data_d_cache= {8'b0,data_out_input[7:0],16'b0};
					2'b11: data_d_cache= {data_out_input[7:0],24'b0};
					endcase
				end
		3'b001: begin
					case(add_out[1])
					1'b0: data_d_cache= {16'b0,data_out_input[15:0]};
					1'b1: data_d_cache= {data_out_input[15:0],16'b0};
					endcase
				end
		3'b010: data_d_cache = data_out_input;
		default:;
	endcase
end


always_comb begin
		case(funct3_str)
		3'b000: begin
					case(add_out[1:0])
					2'b00: mem_byte_enable = 4'b0001;
					2'b01: mem_byte_enable = 4'b0010;
					2'b10: mem_byte_enable = 4'b0100;
					2'b11: mem_byte_enable = 4'b1000;
					endcase
				end
		3'b001: begin
					case(add_out[1])
					2'b0: mem_byte_enable = 4'b0011;
					2'b1: mem_byte_enable = 4'b1100;
					endcase
				end
		3'b010: mem_byte_enable = 4'b1111;
		endcase
end

always_comb
begin
    if(del_head_ld)begin
            cmd_buf_ld.reg_id = head_id_ld;
            cmd_buf_ld.data = load_data;
    end
    else if(del_head_str)begin
            cmd_buf_ld.reg_id = head_id_str;
            cmd_buf_ld.data = data_d_cache;
	end
    else begin
            cmd_buf_ld.reg_id = 5'b0;
            cmd_buf_ld.data = 32'b0;
	end 
end

endmodule : ld_str_queue
