module regfile
(
    input clk,
    input rst,
    input flush,
    input load_new,
	input load_wb,
    input [31:0] in_regfile,
    input logic [4:0] in_score_new,
    input logic [4:0] in_score_wb,
    input [4:0] src_a, src_b, dest,load_dest,
    output logic [31:0] reg_a, reg_b,
    output logic [4:0] score_a, score_b
);

//logic [31:0] data [32] /* synthesis ramstyle = "logic" */ = '{default:'0};
logic [31:0] data [32];
logic [4:0] score [32];

always_ff @(posedge clk)
begin
    if (rst)
    begin
        for (int i=0; i<32; i=i+1) begin
            data[i] <= '0;
            score[i] <= '0;
        end
    end
	else if(flush)begin
        for (int i=0; i<32; i=i+1) begin
            score[i] <= '0;
        end
		if(load_wb && dest) data[dest] <= in_regfile;
	end
    else if (load_new && load_wb && dest && load_dest)
    begin
		if(dest == load_dest)begin
			score[load_dest] <= in_score_new;
			data[dest] <= in_regfile;
		end
		else begin
			score[load_dest] <= in_score_new;
			data[dest] <= in_regfile;
			if(in_score_wb == score[dest]) score[dest] <= '0;
			else score[dest] <= score[dest];

		end
    end
	else if(load_new && load_dest)begin
		score[load_dest] <= in_score_new;
	end
	else if(load_wb && dest)begin
		data[dest] <= in_regfile;
		if(in_score_wb == score[dest]) score[dest] <= '0;
		else score[dest] <= score[dest];
	end
end

always_comb
begin
	if(!src_a)begin
		reg_a = '0;
		score_a = 5'b0;
	end
	else begin
		if(load_wb && (src_a == dest) && (in_score_wb==score[dest])) begin
			reg_a = in_regfile;
			score_a = 5'b0;
		end
		else begin
			reg_a = data[src_a];
			score_a = score[src_a];
		end
	end

	if(!src_b)begin
		reg_b = '0;
		score_b = 5'b0;
	end
	else begin
		if(load_wb && (src_b == dest) && (in_score_wb==score[dest])) begin
			reg_b = in_regfile;
			score_b = 5'b0;
		end
		else begin
			reg_b = data[src_b];
			score_b = score[src_b];
		end
	end
end

endmodule : regfile
