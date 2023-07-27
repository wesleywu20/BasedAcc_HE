module alu_res_station
import rv32i_types::*;

(
    input logic clk,
    input logic reset,
	
	input logic iq_assert,//assert from IQ, saying its ready

	//input logic load_1_i,load_2_i, //dont think these are needed
	input logic [4:0] destination,
	input logic [4:0] r1_i,r2_i,//inital load from reg/rob
	input logic [31:0] src1_i,src2_i,//initial load from reg/rob
	//input alu_ops aluop_in,//alu type from IQ
	input logic [2:0] funct3,
	input logic funct7,
	input logic imm,

	output command_buffer cmd_buf_alu,
	input command_buffer cmd_buf_ld_str,
	input command_buffer cmd_buf_mul,
	input command_buffer cmd_buf_div,

	output logic free_o 

);

logic [1:0] load_busy,load_1,load_2;
logic [1:0] busy,busy_in;
alu_ops aluop[2];
logic [1:0] load_alu;
logic load_select,alu_select;

logic [1:0][4:0] r1_in,r2_in,r1,r2;
logic [1:0][4:0] destination_out;
logic [1:0][31:0] src1_in,src2_in,src1,src2;
logic [31:0] alu_out;
alu_ops aluop_in;//alu type from IQ


assign free_o = !busy[0] || !busy[1];

always_comb begin
	unique case(busy)
		2'b00: load_select = 1'b0;
		2'b01: load_select = 1'b1;
		2'b10: load_select = 1'b0;
		2'b11: load_select = 1'b0;
		default:;
	endcase
end

always_comb begin

	unique case (funct3)
		3'b000: begin
					if(funct7 & !imm) aluop_in = alu_sub;
					else aluop_in = alu_add;
				end
		3'b100: aluop_in = alu_xor;
		3'b110: aluop_in = alu_or;
		3'b111: aluop_in = alu_and;
		3'b001: aluop_in = alu_sll;
		3'b101: begin
					if(funct7) aluop_in = alu_sra;
					else aluop_in = alu_srl;
				end
		3'b010: aluop_in = alu_slt;
		3'b011: aluop_in = alu_sltu;
	endcase

end
logic first_ready;

always_comb begin
for(int i=0;i<2;i++)begin
	load_busy[i] = 1'b0;
	load_1[i] = 1'b0;
	load_2[i] = 1'b0;
	load_alu[i] = 1'b0;
	first_ready = (i) ? busy[0] && !r1[0] && !r2[0] : '0;
	if(busy[i])begin
		if(!r1[i] && !r2[i] && !first_ready)begin
			load_alu[i] = 1'b1;
			load_busy[i] = 1'b1;
			busy_in[i] = 1'b0;
			alu_select = i[0];
		end
		else begin
			if(r1[i])begin
				if(r1[i] == cmd_buf_alu.reg_id)begin
					load_1[i] = 1'b1;
					r1_in[i] = 5'b0;
					src1_in[i] = cmd_buf_alu.data;
				end
				if(r1[i] == cmd_buf_ld_str.reg_id)begin
					load_1[i] = 1'b1;
					r1_in[i] = 5'b0;
					src1_in[i] = cmd_buf_ld_str.data;
				end
				if(r1[i] == cmd_buf_mul.reg_id)begin
					load_1[i] = 1'b1;
					r1_in[i] = 5'b0;
					src1_in[i] = cmd_buf_mul.data;
				end
				if(r1[i] == cmd_buf_div.reg_id)begin
					load_1[i] = 1'b1;
					r1_in[i] = 5'b0;
					src1_in[i] = cmd_buf_div.data;
				end
			end
			if(r2[i])begin
				if(r2[i] == cmd_buf_alu.reg_id)begin
					load_2[i] = 1'b1;
					r2_in[i] = 5'b0;
					src2_in[i] = cmd_buf_alu.data;
				end
				if(r2[i] == cmd_buf_ld_str.reg_id)begin
					load_2[i] = 1'b1;
					r2_in[i] = 5'b0;
					src2_in[i] = cmd_buf_ld_str.data;
				end
				if(r2[i] == cmd_buf_mul.reg_id)begin
					load_2[i] = 1'b1;
					r2_in[i] = 5'b0;
					src2_in[i] = cmd_buf_mul.data;
				end
				if(r2[i] == cmd_buf_div.reg_id)begin
					load_2[i] = 1'b1;
					r2_in[i] = 5'b0;
					src2_in[i] = cmd_buf_div.data;
				end
			end
		end
	end
	else if(iq_assert)begin
		load_busy[load_select] = 1'b1;
		load_1[load_select] = 1'b1;
		load_2[load_select] = 1'b1;
		r1_in[load_select] = r1_i;
		r2_in[load_select] = r2_i;
		src1_in[load_select] = src1_i;
		src2_in[load_select] = src2_i;
		busy_in[load_select] = 1'b1;
		load_alu[load_select] = 1'b0;
	end
	else begin
		load_busy[i] = 1'b0;
		load_1[i] = 1'b0;
		load_2[i] = 1'b0;
		load_alu[i] = 1'b0;
	end
end
end


res_station res_station0
(
    .clk(clk),
    .reset(reset),

	.load_busy(load_busy[0]),
	.load_1(load_1[0]),
	.load_2(load_2[0]),
	.busy_i(busy_in[0]),

	.aluop_i(aluop_in),
	.destination_i(destination),

	.r1_i(r1_in[0]),
	.src1_i(src1_in[0]),
	.r2_i(r2_in[0]),
	.src2_i(src2_in[0]),
	
	.busy_o(busy[0]),
	.aluop_o(aluop[0]),
	.destination_o(destination_out[0]),
	.r1_o(r1[0]),
	.src1_o(src1[0]),
	.r2_o(r2[0]),
	.src2_o(src2[0])
);

res_station res_station1
(
    .clk(clk),
    .reset(reset),
	.load_busy(load_busy[1]),
	.load_1(load_1[1]),
	.load_2(load_2[1]),
	.busy_i(busy_in[1]),

	.aluop_i(aluop_in),
	.destination_i(destination),

	.r1_i(r1_in[1]),
	.src1_i(src1_in[1]),
	.r2_i(r2_in[1]),
	.src2_i(src2_in[1]),
	
	.busy_o(busy[1]),
	.aluop_o(aluop[1]),
	.destination_o(destination_out[1]),
	.r1_o(r1[1]),
	.src1_o(src1[1]),
	.r2_o(r2[1]),
	.src2_o(src2[1])
);


alu alu0(
    .aluop(aluop[alu_select]),
    .a(src1[alu_select]),
	.b(src2[alu_select]),
    .f(alu_out)
);

always_comb
begin
    if(load_alu[0] || load_alu[1])begin
            cmd_buf_alu.reg_id = destination_out[alu_select];
            cmd_buf_alu.data = alu_out;
    end
    else begin
            cmd_buf_alu.reg_id = 5'b0;
            cmd_buf_alu.data = 32'b0;
	end 
end

endmodule : alu_res_station
