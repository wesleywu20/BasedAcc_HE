module btb #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    input [31:0]cur_pc, // to check against the btb to see if it's in there
    input [2:0]branch_ID_i,
    input [31:0]decoded_target,
    input load_btb,
    output btb_hit,
    output [2:0]branch_ID_o
);
logic [31:0]pc_out;
logic [2:0]tar_idx;

array #(.s_index(3), .width(32)) addr_array (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_btb),
    .rindex(cur_pc[2:0]),
    .windex(cur_pc[2:0]),
    .datain(updated_pc),
    .dataout(pc_out)
);

always_comb begin
	if (load_btb)
		tar_idx = branch_ID_i;
	else
		tar_idx = cur_pc[2:0];
end

array #(.s_index(8), .width(32)) target_array (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_btb),
    .rindex(tar_idx),
    .windex(tar_idx),
    .datain(updated_target),
    .dataout(target)
);

endmodule
