module accel_res_station
import rv32i_types::*;

(
    input logic clk,
    input logic reset,

	input logic iq_assert,//assert from IQ, saying its ready

	input logic [4:0] destination,
	input logic [4:0] r1_i,r2_i,//inital load from reg/rob
	input logic [31:0] src1_i,src2_i,//initial load from reg/rob

	input logic [2:0] funct3,

	input command_buffer cmd_buf_alu,
	input command_buffer cmd_buf_ld_str,
	input command_buffer cmd_buf_mul,
	input command_buffer cmd_buf_div,

	output command_buffer cmd_buf,
	output logic free_o,

	output logic mem_read,
	output logic mem_write,
	output logic [31:0] address,
	output logic [31:0] st_data,

	input logic mem_resp,
	input logic [31:0] data

);

logic load_busy,load_1,load_2;
logic busy,busy_in;
logic iq_free,load_alu;
logic done;
logic accel_ready; // 1 if accel is avaible
logic accel_done; //1 for a cycle after isntruction is done
logic [4:0] r1_in,r2_in,r1,r2;
logic [4:0] destination_out;
logic [2:0] funct3_o;
logic [31:0] src1_in,src2_in,src1,src2;

assign free_o = !busy && accel_ready;
assign done = accel_done;


always_comb begin
	if(!accel_ready)begin
		load_alu = 1'b0;
		load_busy = 1'b0;
		if(accel_done)begin
			iq_free = 1'b1;
			load_busy = 1'b1;
			busy_in = 1'b0;
		end
	end
	else if(busy)begin
		load_busy = 1'b0;
		load_1 = 1'b0;
		load_2 = 1'b0;
		load_alu = 1'b0;
		if(!r1 && !r2)begin
			load_alu= 1'b1;
		end
		else begin
			if(r1)begin
				if(r1 == cmd_buf_alu.reg_id)begin
					load_1 = 1'b1;
					r1_in = 5'b0;
					src1_in = cmd_buf_alu.data;
				end
				if(r1 == cmd_buf_ld_str.reg_id)begin
					load_1 = 1'b1;
					r1_in = 5'b0;
					src1_in = cmd_buf_ld_str.data;
				end
				if(r1 == cmd_buf_mul.reg_id)begin
					load_1 = 1'b1;
					r1_in = 5'b0;
					src1_in = cmd_buf_mul.data;
				end
				if(r1 == cmd_buf_div.reg_id)begin
					load_1 = 1'b1;
					r1_in = 5'b0;
					src1_in = cmd_buf_div.data;
				end
			end
			if(r2)begin
				if(r2 == cmd_buf_alu.reg_id)begin
					load_2 = 1'b1;
					r2_in = 5'b0;
					src2_in = cmd_buf_alu.data;
				end
				if(r2 == cmd_buf_ld_str.reg_id)begin
					load_2 = 1'b1;
					r2_in = 5'b0;
					src2_in = cmd_buf_ld_str.data;
				end
				if(r2 == cmd_buf_mul.reg_id)begin
					load_2 = 1'b1;
					r2_in = 5'b0;
					src2_in = cmd_buf_mul.data;
				end
				if(r2 == cmd_buf_div.reg_id)begin
					load_2 = 1'b1;
					r2_in = 5'b0;
					src2_in = cmd_buf_div.data;
				end
			end
		end

	end
	else if(iq_assert)begin
		load_busy = 1'b1;
		load_1 = 1'b1;
		load_2 = 1'b1;
		r1_in = r1_i;
		r2_in = r2_i;
		src1_in = src1_i;
		src2_in = src2_i;
		busy_in = 1'b1;
		load_alu = 1'b0;
	end
	else begin
		iq_free = 1'b0;
		load_busy = 1'b0;
		load_1 = 1'b0;
		load_2 = 1'b0;
		load_alu = 1'b0;
	end

end


res_station_accel res_station0
(
    .clk(clk),
    .reset(reset),
	.load_busy(load_busy),
	.load_1(load_1),
	.load_2(load_2),
	.busy_i(busy_in),
	.aluop_i(funct3),
	.destination_i(destination),
	.r1_i(r1_in),
	.src1_i(src1_in),
	.r2_i(r2_in),
	.src2_i(src2_in),
	
	.busy_o(busy),
	.aluop_o(funct3_o),
	.destination_o(destination_out),
	.r1_o(r1),
	.src1_o(src1),
	.r2_o(r2),
	.src2_o(src2)
);

accel accel0(
    .clk(clk),
    .reset(reset),
	.iq_assert(load_alu),
	.funct3(funct3_o),
	.source(src1),
	.destination(src2),
	.accel_ready(accel_ready),
	.accel_done(accel_done),
	.mem_read(mem_read),
	.mem_write(mem_write),
	.address(address),
	.st_data(st_data),

	.mem_resp(mem_resp),
	.data(data)
);

always_comb
begin
    if(accel_done)begin
            cmd_buf.reg_id = destination_out;
            cmd_buf.data = 32'b0;
    end
    else begin
            cmd_buf.reg_id = 5'b0;
            cmd_buf.data = 32'b0;
	end 
end

endmodule : accel_res_station
