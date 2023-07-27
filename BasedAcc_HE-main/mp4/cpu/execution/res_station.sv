
module res_station
import rv32i_types::*;
(
    input logic clk,
    input logic reset,
	input logic load_busy,//occupy res station
				load_1,//load arg 1 
				load_2, //load arg 2

	input logic busy_i, //set busy or not
	input alu_ops aluop_i,//operation to be filled
	input logic [4:0] destination_i,
	input logic [4:0] r1_i,
	input logic [31:0] src1_i,
	input logic [4:0] r2_i,
	input logic [31:0] src2_i,
	
	output logic busy_o,//indicate if in use
	output alu_ops aluop_o,
	output logic [4:0] destination_o,
	output logic [4:0] r1_o,
	output logic [31:0] src1_o,
	output logic [4:0] r2_o,
	output logic [31:0] src2_o
);

logic busy;
alu_ops aluop;
logic [4:0] destination;
logic [4:0] r1;
logic [31:0] src1;
logic [4:0] r2;
logic [31:0] src2;

always_ff @(posedge clk)
begin
    if (reset)
    begin
            busy <= 1'b0;
    end
    else 
    begin
		if (load_busy)begin
			busy <= busy_i;
			aluop<= aluop_i;
			destination<=destination_i;
		end
		else begin
			busy <= busy;
			aluop<= aluop;
			destination<=destination;
		end

		if(load_1)begin
			r1 <= r1_i;
			src1 <= src1_i;
		end
		else begin
			r1 <= r1;
			src1 <= src1;
		end

		if(load_2)begin
			r2 <= r2_i;
			src2 <= src2_i;
		end
		else begin
			r2 <= r2;
			src2 <= src2;
		end
    end
end
always_comb begin
	busy_o = busy;
	aluop_o= aluop;
	destination_o = destination;
	r1_o = r1;
	src1_o = src1;
	r2_o = r2;
	src2_o = src2;
end
endmodule : res_station








module res_station_cmp
import rv32i_types::*;
(
    input logic clk,
    input logic reset,
	input logic load_busy,//occupy res station
				load_1,//load arg 1 
				load_2, //load arg 2

	input logic busy_i, //set busy or not
	input branch_funct3_t aluop_i,//operation to be filled
	input logic [4:0] destination_i,
	input logic [4:0] r1_i,
	input logic [31:0] src1_i,
	input logic [4:0] r2_i,
	input logic [31:0] src2_i,
	
	output logic busy_o,//indicate if in use
	output branch_funct3_t aluop_o,
	output logic [4:0] destination_o,
	output logic [4:0] r1_o,
	output logic [31:0] src1_o,
	output logic [4:0] r2_o,
	output logic [31:0] src2_o
);

logic busy;
branch_funct3_t aluop;
logic [4:0] destination;
logic [4:0] r1;
logic [31:0] src1;
logic [4:0] r2;
logic [31:0] src2;

always_ff @(posedge clk)
begin
    if (reset)
    begin
            busy <= 1'b0;
    end
    else 
    begin
		if (load_busy)begin
			busy <= busy_i;
			aluop<= aluop_i;
			destination<=destination_i;
		end
		else begin
			busy <= busy;
			aluop<= aluop;
			destination<=destination;
		end

		if(load_1)begin
			r1 <= r1_i;
			src1 <= src1_i;
		end
		else begin
			r1 <= r1;
			src1 <= src1;
		end

		if(load_2)begin
			r2 <= r2_i;
			src2 <= src2_i;
		end
		else begin
			r2 <= r2;
			src2 <= src2;
		end
    end
end
always_comb begin
	busy_o = busy;
	aluop_o= aluop;
	destination_o = destination;
	r1_o = r1;
	src1_o = src1;
	r2_o = r2;
	src2_o = src2;
end
endmodule : res_station_cmp



module res_station_mul
import rv32i_types::*;
(
    input logic clk,
    input logic reset,
	input logic load_busy,//occupy res station
				load_1,//load arg 1 
				load_2, //load arg 2

	input logic busy_i, //set busy or not
	input logic [2:0] aluop_i,//operation to be filled
	input logic [4:0] destination_i,
	input logic [4:0] r1_i,
	input logic [31:0] src1_i,
	input logic [4:0] r2_i,
	input logic [31:0] src2_i,
	
	output logic busy_o,//indicate if in use
	output logic [2:0] aluop_o,
	output logic [4:0] destination_o,
	output logic [4:0] r1_o,
	output logic [31:0] src1_o,
	output logic [4:0] r2_o,
	output logic [31:0] src2_o
);

logic busy;
logic [2:0] aluop;
logic [4:0] destination;
logic [4:0] r1;
logic [31:0] src1;
logic [4:0] r2;
logic [31:0] src2;

always_ff @(posedge clk)
begin
    if (reset)
    begin
            busy <= 1'b0;
    end
    else 
    begin
		if (load_busy)begin
			busy <= busy_i;
			aluop<= aluop_i;
			destination<=destination_i;
		end
		else begin
			busy <= busy;
			aluop<= aluop;
			destination<=destination;
		end

		if(load_1)begin
			r1 <= r1_i;
			src1 <= src1_i;
		end
		else begin
			r1 <= r1;
			src1 <= src1;
		end

		if(load_2)begin
			r2 <= r2_i;
			src2 <= src2_i;
		end
		else begin
			r2 <= r2;
			src2 <= src2;
		end
    end
end
always_comb begin
	busy_o = busy;
	aluop_o= aluop;
	destination_o = destination;
	r1_o = r1;
	src1_o = src1;
	r2_o = r2;
	src2_o = src2;
end
endmodule : res_station_mul















module res_station_accel
import rv32i_types::*;
(
    input logic clk,
    input logic reset,
	input logic load_busy,//occupy res station
				load_1,//load arg 1 
				load_2, //load arg 2

	input logic busy_i, //set busy or not
	input logic [2:0] aluop_i,//operation to be filled
	input logic [4:0] destination_i,
	input logic [4:0] r1_i,
	input logic [31:0] src1_i,
	input logic [4:0] r2_i,
	input logic [31:0] src2_i,
	
	output logic busy_o,//indicate if in use
	output logic [2:0] aluop_o,
	output logic [4:0] destination_o,
	output logic [4:0] r1_o,
	output logic [31:0] src1_o,
	output logic [4:0] r2_o,
	output logic [31:0] src2_o
);

logic busy;
logic [2:0] aluop;
logic [4:0] destination;
logic [4:0] r1;
logic [31:0] src1;
logic [4:0] r2;
logic [31:0] src2;

always_ff @(posedge clk)
begin
    if (reset)
    begin
            busy <= 1'b0;
    end
    else 
    begin
		if (load_busy)begin
			busy <= busy_i;
			aluop<= aluop_i;
			destination<=destination_i;
		end
		else begin
			busy <= busy;
			aluop<= aluop;
			destination<=destination;
		end

		if(load_1)begin
			r1 <= r1_i;
			src1 <= src1_i;
		end
		else begin
			r1 <= r1;
			src1 <= src1;
		end

		if(load_2)begin
			r2 <= r2_i;
			src2 <= src2_i;
		end
		else begin
			r2 <= r2;
			src2 <= src2;
		end
    end
end
always_comb begin
	busy_o = busy;
	aluop_o= aluop;
	destination_o = destination;
	r1_o = r1;
	src1_o = src1;
	r2_o = r2;
	src2_o = src2;
end
endmodule : res_station_accel
