module ir
import rv32i_types::*;
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    output [2:0] funct3,
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output [31:0] i_imm,
    output [31:0] s_imm,
    output [31:0] b_imm,
    output [31:0] u_imm,
    output [31:0] j_imm,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,
    output [31:0]instruction_,
	input logic [2:0] branch_id_in,
	output logic [2:0] branch_id_out
);

logic [31:0] data;
logic [2:0] branch_id;

assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign opcode = rv32i_opcode'(data[6:0]);
assign i_imm = {{21{data[31]}}, data[30:20]};
assign s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign u_imm = {data[31:12], 12'h000};
assign j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign rs1 = data[19:15];
assign rs2 = data[24:20];
assign rd = data[11:7];
assign instruction_ = data;
assign branch_id_out = branch_id;

//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
		branch_id <= '0;
    end
    else if (load == 1)
    begin
        data <= in;
		branch_id <= branch_id_in;
    end
    else
    begin
        data <= data;
		branch_id <= branch_id;
    end
end

endmodule : ir
