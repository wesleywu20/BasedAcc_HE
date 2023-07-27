import rv32i_types::*;
module decode
(
    input clk,
    input rst,
    input reset,
	input flush_i,
    input [31:0] i_cache,
    input [31:0] pc,
    input load_ir,
	input [2:0] branch_id,

    output load_queue,
    output instr_struct instruction
);

/*
------INPUT-------
load_ir -> if mem_resp=1 from I cache then the new instruction can be loaded to decode in IR

------OUTPUT------
load_queue -> if instruction has finished executing load_queue is asserted
*/
logic load_queue_a,decode_assert,decode_asserted;
logic [4:0] rd;
int branch_count;

//Decoding Instruction from I cache and filling the struct
ir ir (
    .clk (clk),
    .rst (rst),
    .load (load_ir),
    .in (i_cache),
    .funct3 (instruction.funct3),
    .funct7 (instruction.funct7),
    .opcode (instruction.opcode),
    .i_imm (instruction.i_imm),
    .s_imm (instruction.s_imm),
    .b_imm (instruction.b_imm),
    .u_imm (instruction.u_imm),
    .j_imm (instruction.j_imm),
    .rs1 (instruction.rs1),
    .rs2 (instruction.rs2),
    .branch_id_in(branch_id),
    .branch_id_out(instruction.branch_id),
    .rd (rd),
    .instruction_(instruction.instruction)
);
assign instruction.pc = pc;
//assign load_queue = load_queue_a;
assign decode_asserted = decode_assert;
logic flush,flush_state;

assign load_queue = (instruction.instruction && !flush) ? load_ir : 0;

always_comb
begin
        if(instruction.opcode == op_br) begin
		instruction.rd = '0; //if the branch is taken or not from the prediction
	end else 
		instruction.rd = rd;

end 



always_ff @(posedge clk) begin
	if (reset)
		flush_state <= 0;
	else if(flush_i && load_ir)
		flush_state <= 1'b0;
	else if (flush_i)
		flush_state <= 1'b1;
	else if(load_ir)
		flush_state <= 1'b0;
end


assign flush =  flush_i || flush_state;


always_ff @(posedge clk) begin
	if (reset)
		branch_count <= 0;
	if ((instruction.opcode == op_br || instruction.opcode == op_jal || instruction.opcode == op_jalr) && load_ir)
		branch_count <= branch_count + 1;
end

always_ff @(posedge clk) begin
	if(rst) 
	begin
		load_queue_a <= 1'b0;
		decode_assert <= 1'b0;

	end 
	else if (load_ir && i_cache)
	begin
		decode_assert <= 1'b1;
	end
        else 
	begin 
           	decode_assert <= 1'b0;
	end


	if(decode_asserted)
	begin
		load_queue_a <= 1'b1;
	end
	else
	begin
		load_queue_a <= 1'b0;
	end
		
end

endmodule
