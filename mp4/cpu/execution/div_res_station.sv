module div_res_station
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

	output command_buffer cmd_buf,

	output logic free_o 

);

logic load_busy,load_1,load_2;
logic busy,busy_in;
logic iq_free,load_alu;
logic [4:0] r1_in,r2_in,r1,r2;
logic [4:0] destination_out;
logic [31:0] src1_in,src2_in,src1,src2;
logic ready,done;
logic [2:0] mulop;
logic [31:0] quot,rem;
logic start,busy_m;

logic [31:0] dividend,divisor,quot_out,rem_out;
logic sign_out;

always_ff @(posedge clk)begin
    if(reset) start <= '0;
	else if(start) start <= '0;
	else if(load_alu) start<= 1'b1;
end

always_ff @(posedge clk)begin
    if(reset) busy_m <= '0;
	else if(done) busy_m <= '0;
	else if(load_alu) busy_m <= 1'b1;
end

assign free_o = !busy;

always_comb begin
	load_busy = 1'b0;
	load_1 = 1'b0;
	load_2 = 1'b0;
	if(busy)begin
		load_alu= 1'b0;
		if(!r1 && !r2 && !busy_m)begin
			load_alu= 1'b1;
			//iq_free = 1'b1;
			//load_busy = 1'b1;
			//busy_in = 1'b0;
		end
		else if(!r1 && !r2 && done)begin
			iq_free = 1'b1;
			load_busy = 1'b1;
			busy_in = 1'b0;
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


res_station_mul mul_station0
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
	.aluop_o(mulop),
	.destination_o(destination_out),
	.r1_o(r1),
	.src1_o(src1),
	.r2_o(r2),
	.src2_o(src2)
);
div_int div0(
    .clk(clk),
    .start(start),          // start signal
    .busy(ready),           // calculation in progress
    .valid(done),          // quotient and remainder are valid
    .dbz(),            // divide by zero flag
    .x(dividend),  // dividend
    .y(divisor),  // divisor
    .q(quot),  // quotient
    .r(rem)   // remainder
    );


always_comb begin 
//	if(mulop[0])begin
		dividend = src1;
		divisor = src2;
		quot_out = quot;
		rem_out = rem;
		sign_out = 1'b0;
//	end
/*
	else begin
		dividend = (src1[31]) ? (~(src1)+1): src1;
		divisor = (src2[31]) ? (~(src2)+1): src2;
		quot_out = (sign_out) ? (~(quot)+1) : quot;
		rem_out = rem;
		sign_out = src1[31] ^ src2[31];
	end
*/
end

always_comb
begin
    if(busy_m && done)begin
            cmd_buf.reg_id = destination_out;
			if(mulop[2:1] == 2'b10) cmd_buf.data = quot_out;
			else if(mulop[2:1] == 2'b11) cmd_buf.data = rem_out;
			else cmd_buf.data = 32'b0;
    end
    else begin
            cmd_buf.reg_id = 5'b0;
            cmd_buf.data = 32'b0;
	end 
end

endmodule : div_res_station
