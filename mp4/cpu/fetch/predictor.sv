import rv32i_types::*;
module predictor # (
	parameter GSHARE_GLOBAL = 10
)
(
	input clk,
	input rst,
	
	input instr_struct current_instr,
	input logic [31:0]completed_branch_addr,

	input logic [1:0] branch_was_taken,
	output logic prediction,
	output logic [31:0]branch_target
	//output logic [GSHARE_GLOBAL-1:0]global_bhr
);

typedef enum bit[1:0] {
	STRONGLY_TAKEN = 2'b00,
	WEAKLY_TAKEN = 2'b01,
	WEAKLY_NOT_TAKEN = 2'b10,
	STRONGLY_NOT_TAKEN = 2'b11
} bp_state;

localparam table_size = 2**GSHARE_GLOBAL;

logic [GSHARE_GLOBAL-1:0]global_bhr;
logic [1:0]pht [0:table_size-1];

logic [GSHARE_GLOBAL-1:0] read_index;
logic [GSHARE_GLOBAL-1:0] update_index;

logic instr_is_branch;
logic pht_out;

assign read_index = global_bhr ^ current_instr.pc[GSHARE_GLOBAL+1:2];
assign update_index = global_bhr ^ completed_branch_addr[GSHARE_GLOBAL+1:2];

assign prediction = (pht[0] <= 2'b01) ? 1'b1 : 1'b0;
assign branch_target = (instr_is_branch & pht[0]<=2'b01) ? (current_instr.pc + current_instr.b_imm) : (current_instr.pc + 4);

always_comb begin
	if (current_instr.opcode == op_br)
		instr_is_branch = 1'b1;
	else
		instr_is_branch = 1'b0;
end

int i;
always @(posedge clk) begin
	if (rst) begin
		global_bhr <= 0;
		for (i=0; i<1024; i=i+1) begin
			pht[i] <= WEAKLY_TAKEN;
		end
	end else begin	
		if (branch_was_taken == 2'b10) begin
			global_bhr <= {global_bhr[GSHARE_GLOBAL-2:0], 1'b1};
			case (pht[update_index])
				STRONGLY_TAKEN : begin
					pht[update_index] <= STRONGLY_TAKEN;
					pht_out <= 1'b1;
					end	
				WEAKLY_TAKEN : begin
					pht[update_index] <= STRONGLY_TAKEN;
					pht_out <= 1'b1;	
					end
				WEAKLY_NOT_TAKEN : begin
					pht[update_index] <= WEAKLY_TAKEN;
					pht_out <= 1'b0;
					end	
				STRONGLY_NOT_TAKEN : begin 
					pht[update_index] <= WEAKLY_NOT_TAKEN;
					pht_out <= 1'b0;
					end			
			endcase
		end
		else if (branch_was_taken == 2'b01) begin
			global_bhr <= {global_bhr[GSHARE_GLOBAL-2:0], 1'b0 };
			case (pht[update_index])
				STRONGLY_TAKEN : begin
					pht[update_index] <= WEAKLY_TAKEN;
					pht_out <= 1'b1;
					end	
				WEAKLY_TAKEN : begin 
					pht[update_index] <= WEAKLY_NOT_TAKEN;
					pht_out <= 1'b1;
					end	
				WEAKLY_NOT_TAKEN : begin 
					pht[update_index] <= STRONGLY_NOT_TAKEN;
					pht_out <= 1'b0;
					end	
				STRONGLY_NOT_TAKEN : begin 
					pht[update_index] <= STRONGLY_NOT_TAKEN;
					pht_out <= 1'b0;
					end			
			endcase
		end	
	end
end




endmodule


