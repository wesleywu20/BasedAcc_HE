module I_fetch
import rv32i_types::*; 
(
    input logic clk,
    input logic rst, 
    input logic mem_resp,
    input logic queue_ready,
    input  instr_struct decoded_update, // after decoding
    input logic get_next_pc,


    output logic i_mem_read,

    input branch_complete,
    input [2:0]branch_ID_i,
    input [31:0]branch_result,
    input flush,

    output [31:0]cache_pc,current_pc,

    output [2:0]branch_ID_o,
    output [31:0]prediction,
    output logic load_pc
);

logic load_pc, b_pred_out;
logic [1:0] branch_was_taken;
logic [2:0] branch_ID_out, head_arr_idx, tail_arr_idx, save_j_idx; 
logic [2:0] pcmux_sel;
logic [31:0] pred_tar, pcmux_out, pc_out, branch_NT_address, branch_info, old_branch_tar, branch_pred_target, branch_pred_tar, completed_branch_addr, calc_jalr_tar, jalr_tar;
logic [31:0] branch_addr_arr [8];
logic [31:0] branch_NT_arr [8];
logic [31:0] jalr_T_arr [8];
logic b_or_j [8];
logic [1:0] flush_hold;
logic array_op;
logic [31:0] pc_out_;
int branch_count;
int miss_count;
rv32i_opcode opcode_decode,opcode_save;

assign current_pc = pc_out; 
//assign cache_pc = (load_pc) ? pcmux_out : pc_out_;
//assign cache_pc = pcmux_out;
//assign load_pc = queue_ready;
assign branch_ID_o = tail_arr_idx;
//assign branch_ID_o = branch_ID_out;
//assign load_pc = mem_resp;
logic b_complete;
logic load_pc_hold;
logic [2:0] branch_id;
logic [31:0] jid;
logic [2:0] branch_id_save;
logic [31:0] jid_save;
logic [31:0] old_NT_save;
logic [31:0] old_NT;
logic cycle;
logic [31:0] cache_save;
logic [1:0] out_counter;

assign b_complete = (i_mem_read) ? 0: branch_complete;

always_comb begin
	if(mem_resp && flush_hold == 2'b0) load_pc_hold = 1'b1;
	else if(mem_resp && flush_hold == 2'b1) load_pc_hold = 1'b0;
	else if(mem_resp && flush_hold == 2'd2) load_pc_hold = 1'b1;
	else load_pc_hold = 1'b0;
end
assign load_pc = !flush && load_pc_hold && queue_ready;

always_ff @(posedge clk)
begin
    /* Assignment of next state on clock edge */
        if (rst) i_mem_read <= 1'b0;
        else if (~get_next_pc) i_mem_read<= 1'b1;
        if(mem_resp) i_mem_read <= 1'b0;
end

always_ff @(posedge clk)begin
	if(rst) flush_hold <= 2'b0;
	else if(flush && !mem_resp) flush_hold <= 2'b1;
	else if(flush && mem_resp) flush_hold <= 2'd2;
	else if(flush_hold == 2'b1 && mem_resp) flush_hold <= 2'd2;
	else if(flush_hold == 2'd2 && mem_resp) flush_hold <= 2'd0;
end

always_ff @(posedge clk)begin
	if(rst) out_counter <= 2'b0;
	else if(!i_mem_read) out_counter <= 2'd0;
	else if(out_counter == 2'b0 && i_mem_read) out_counter <= 2'b1;
	else if(out_counter == 2'b1 && i_mem_read) out_counter <= 2'd2;
end
/*
always_ff @(posedge clk) begin
	if(rst) cache_save <= '0;
	else if(!out_counter && i_mem_read) cache_save <= pcmux_out;
end

assign cache_pc = (!out_counter && i_mem_read) ? pcmux_out : cache_save;
*/
assign cache_pc = pcmux_out;



/*
always_ff @(posedge clk) begin

	if(rst) pc_out_ <= 32'b0;
	else if(load_pc) pc_out_ <= pcmux_out;
end
*/

/*
always_ff @(posedge clk) begin
	if(load_pc) opcode_save <= decoded_update.opcode;
end

assign opcode_decode = (load_pc) ? decoded_update.opcode : opcode_save;
*/


always_comb begin
	if (flush_hold == 2'd2) 
	//if (flush) 
		pcmux_sel = 3'b100;
	else begin
		//unique case(opcode_decode)
		unique case(decoded_update.opcode)
			op_jalr : pcmux_sel = 3'b011;
			op_jal : pcmux_sel = 3'b010;
                        op_br : pcmux_sel = 3'b001;
			default: pcmux_sel = 3'b000;
		endcase
	end 
end

always_comb begin
	pcmux_out = pc_out;

	unique case (pcmux_sel)
		3'b000: pcmux_out = pc_out + 4;
		3'b001: pcmux_out = branch_pred_target; //decoded_update.pc + decoded_update.b_imm;  //pc_out + 4;
                3'b010: pcmux_out = decoded_update.pc + decoded_update.j_imm;
		3'b011: pcmux_out = jalr_tar;
		3'b100: pcmux_out = old_NT_save;		
		default:;
	endcase
end

always_ff @(posedge clk) begin
	if (load_pc) begin
		branch_pred_tar <= branch_pred_target;
	end
end

assign pred_tar = (load_pc) ? branch_pred_target: branch_pred_tar;

pc_register pc_register0(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

always_ff @(posedge clk) begin
	array_op <= load_pc;
end

always_ff @(posedge clk) begin
	if (rst) begin
		branch_id_save <= '0;
		jid_save <= '0;
		old_NT_save <= '0;
	end else if (branch_complete) begin
		branch_id_save <= branch_ID_i;
		jid_save <= branch_result;
		old_NT_save <= (b_or_j[branch_ID_i]) ? branch_result : branch_NT_arr[branch_ID_i];
	end else if (!branch_complete) begin
		branch_id_save <= branch_id_save;
		jid_save <= jid_save;
		old_NT_save <= old_NT_save;
	end
end
/*
always_comb begin
	branch_id = (flush) ? branch_ID_i : branch_id_save;
	jid = (branch_complete) ? branch_result : jid_save;
	old_NT = (branch_complete) ? branch_NT_arr[branch_id] : old_NT_save;
end
*/

always_ff @(posedge clk) begin
	if (rst) begin
		branch_count <= 0;
		miss_count <= 0;
		branch_was_taken <= 2'b00;
		head_arr_idx <= '0;
		tail_arr_idx <= '0;
		cycle <= 1'b1;
		save_j_idx <= 2'b00;
        for (int i=0; i<8; i=i+1) begin
		branch_addr_arr[i] <= '0;
            	branch_NT_arr[i] <= '0;
		b_or_j[i] <= '0;
		jalr_T_arr[i] <= '0;
        end

	end else if (flush_hold == 2'b10 && !i_mem_read) begin
		cycle <= 1'b0;
		branch_was_taken <= 2'b01;
		completed_branch_addr <= branch_addr_arr[branch_id_save];
		if (b_or_j[branch_id_save] == 1'b0) begin            	
			old_branch_tar <= branch_NT_arr[branch_id_save];
			miss_count <= miss_count + 1;
		end else if (b_or_j[branch_id_save] == 1'b1)
			old_branch_tar <= jid_save;
		head_arr_idx <= '0;
		tail_arr_idx <= '0;
		save_j_idx <= '0;
		for (int i=0; i<8; i=i+1) begin
			branch_addr_arr[i] <= '0;
            		branch_NT_arr[i] <= '0;
			jalr_T_arr[i] <= '0;
        	end
	end

	else if (b_complete && decoded_update.opcode == op_br && array_op) begin
		head_arr_idx <= head_arr_idx+1;
		branch_info <= branch_result;
		if (branch_result == 31'b1)
			branch_was_taken <= 2'b10;
		completed_branch_addr <= branch_addr_arr[head_arr_idx];
		if (branch_result != 31'b1 && branch_result != 31'b0) begin       		
			jalr_T_arr[head_arr_idx] <= branch_result;
			save_j_idx <= head_arr_idx;
		end

		tail_arr_idx <= (tail_arr_idx[2:0] + 3'b1);
		branch_ID_out <= tail_arr_idx;
        	branch_addr_arr[(tail_arr_idx[2:0])] <= decoded_update.pc;
		branch_NT_arr[tail_arr_idx[2:0]] <= branch_NT_address;
		b_or_j[tail_arr_idx[2:0]] <= 1'b0;
	end 

	else if (b_complete && decoded_update.opcode == op_jalr && array_op ) begin
		head_arr_idx <= head_arr_idx+1;
		branch_info <= branch_result;
		if (branch_result == 31'b1)
			branch_was_taken <= 2'b10;
		completed_branch_addr <= branch_addr_arr[head_arr_idx];
		if (branch_result != 31'b1 && branch_result != 31'b0) begin       		
			jalr_T_arr[head_arr_idx] <= branch_result;
			save_j_idx <= head_arr_idx;
		end

		tail_arr_idx <= (tail_arr_idx[2:0] + 3'b1);
		branch_ID_out <= tail_arr_idx;
        	branch_addr_arr[(tail_arr_idx[2:0])] <= decoded_update.pc;
		branch_NT_arr[(tail_arr_idx[2:0])] <= decoded_update.pc + 4;
		b_or_j[(tail_arr_idx[2:0])] <= 1'b1;
		//if (jalr_T_arr[(tail_arr_idx[2:0])])
		if (tail_arr_idx[2:0] == save_j_idx)
			jalr_tar <= jalr_T_arr[save_j_idx];
	        else
			jalr_tar <= pc_out + 4;
	end 

	else if (b_complete) begin
		head_arr_idx <= head_arr_idx+1;
		branch_info <= branch_result;
		if (branch_result == 31'b1)
			branch_was_taken <= 2'b10;
		completed_branch_addr <= branch_addr_arr[head_arr_idx];
		if (branch_result != 31'b1 && branch_result != 31'b0) begin       		
			jalr_T_arr[head_arr_idx] <= branch_result;
			save_j_idx <= head_arr_idx;
		end
	end

	else if (decoded_update.opcode == op_br && array_op) begin
		tail_arr_idx <= (tail_arr_idx[2:0] + 3'b1);
		branch_ID_out <= tail_arr_idx;
        	branch_addr_arr[tail_arr_idx[2:0]] <= decoded_update.pc;
		branch_NT_arr[tail_arr_idx[2:0]] <= branch_NT_address;
		b_or_j[tail_arr_idx[2:0]] <= 1'b0;
	end 

	else if (decoded_update.opcode == op_jalr && array_op) begin
		tail_arr_idx <= (tail_arr_idx[2:0] + 3'b1);
		branch_ID_out <= tail_arr_idx;
        	branch_addr_arr[(tail_arr_idx[2:0])] <= decoded_update.pc;
		branch_NT_arr[(tail_arr_idx[2:0])] <= decoded_update.pc + 4;
		b_or_j[(tail_arr_idx[2:0])] <= 1'b1;
		//if (jalr_T_arr[(tail_arr_idx[2:0])])
		if (tail_arr_idx[2:0] == save_j_idx)		
			jalr_tar <= jalr_T_arr[save_j_idx];
	        else
			jalr_tar <= pc_out + 4;
	end 

	else if (flush) begin
		cycle <= 1'b1;
		head_arr_idx <= head_arr_idx;
	end

	else
		branch_was_taken <= 2'b00;
end


//always_comb begin
//	unique case (branch_info)
//		31'b0: branch_was_taken = 1'b0;
//		31'b1: branch_was_taken = 1'b1;
//	endcase
//end

predictor predictor (
     .clk(clk),
     .rst(rst),
     .current_instr(decoded_update),
     .completed_branch_addr(completed_branch_addr),
     .branch_was_taken(branch_was_taken),
     .prediction(b_pred_out),
     .branch_target(branch_pred_target)
);
//assign b_pred_out = 1'b0;
assign prediction = {31'b0, b_pred_out};
always_comb begin
	if (decoded_update.opcode == op_br) begin
		if (b_pred_out == 1'b1)
			branch_NT_address = pc_out + 4;
		else
			branch_NT_address = decoded_update.pc + decoded_update.b_imm; // branch_pred_target
	end else 
		branch_NT_address = 32'b0;
		
end

endmodule : I_fetch
