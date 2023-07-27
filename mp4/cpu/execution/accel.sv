`define BASE_WIDTH 512
`define EXTEN_WIDTH (2*`BASE_WIDTH-1)
`define INDEX_SIZE ($clog2(`BASE_WIDTH)-1)
`define NUM_ADDRESSES `BASE_WIDTH*2

module accel
import rv32i_types::*;

(
    input logic clk,
    input logic reset,
	
	input logic iq_assert,//assert from IQ, saying its ready

    input logic[2:0] funct3,

	input logic [31:0] source,destination,

	output logic accel_ready,accel_done,


	//mem interactions
	output logic mem_read,
	output logic mem_write,
	output logic [31:0] address,
	output logic [31:0] st_data,
	

	input logic mem_resp,
	input logic [31:0] data
);


logic mem_resp_hold, store_start;
logic [31:0] counter,load_address,store_address;
logic load_done,store_done,calc_done;

logic [`INDEX_SIZE:0] index, c,calc_i;
logic [2:0] calc_j,matrix_index,upper_index;
logic [`INDEX_SIZE+1:0] exten_width;
logic signed [63:0] a,b,index_small;

//inputs
logic signed [63:0] ct0 [`BASE_WIDTH][2];
logic signed [63:0] ct1 [`BASE_WIDTH][2];

logic signed [63:0] rln0 [`BASE_WIDTH][8];
logic signed [63:0] rln1 [`BASE_WIDTH][8];

logic [63:0] q;
logic [136:0] t;

//intermediate

logic signed [127:0] mul_0_0 [`EXTEN_WIDTH];
logic signed [127:0] mul_1_0 [`EXTEN_WIDTH];
logic signed [127:0] mul_0_1 [`EXTEN_WIDTH];
logic signed [127:0] mul_1_1 [`EXTEN_WIDTH];

logic signed [127:0] mul_0_0_mod [`BASE_WIDTH];
logic signed [127:0] mul_1_0_mod [`BASE_WIDTH];
logic signed [127:0] mul_0_1_mod [`BASE_WIDTH];
logic signed [127:0] mul_1_1_mod [`BASE_WIDTH];

logic signed [63:0] c0 [`BASE_WIDTH];
logic signed [63:0] c1 [`BASE_WIDTH];
logic signed [63:0] c2 [`BASE_WIDTH];

logic signed [136:0] c0_mult [`BASE_WIDTH];
logic signed [136:0] c1_mult [`BASE_WIDTH];
logic signed [136:0] c2_mult [`BASE_WIDTH];

logic signed [63:0] c2_prime [`BASE_WIDTH][8];

logic signed [63:0] c0_prime [`EXTEN_WIDTH][8];
logic signed [63:0] c1_prime [`EXTEN_WIDTH][8];

logic signed [63:0] c0_prime_mod [`BASE_WIDTH][8];
logic signed [63:0] c1_prime_mod [`BASE_WIDTH][8];

logic [63:0] c0_out [`BASE_WIDTH];
logic [63:0] c1_out [`BASE_WIDTH];

assign q = 64'h3FFFFFFFFFFAC01;
assign t = 9'd256;

assign index = counter[`INDEX_SIZE+1:1];
assign upper_index = counter[`INDEX_SIZE+4:`INDEX_SIZE+2];

enum int unsigned {
    idle,load,calc0,calc0_1,calc1_0,calc1_1,calc1_2,calc2,calc4,calc3,calc3_0,store
} state, next_state;

assign accel_done = store_done;

always_comb begin

	if((state == store))begin
		if(counter < `NUM_ADDRESSES)begin
			if(!counter[0]) st_data= c0_out[index][31:0];
			else st_data = c0_out[index][63:32];
		end
		else if(counter < `NUM_ADDRESSES*2)begin
			if(!counter[0]) st_data = c0_out[index][31:0];
			else st_data = c0_out[index][63:32];
		end
		else if(counter < `NUM_ADDRESSES*3)begin
			if(!counter[0]) st_data = c1_out[index][31:0];
			else st_data = c1_out[index][63:32];
		end
		else if(counter < `NUM_ADDRESSES*4)begin
			if(!counter[0]) st_data = c1_out[index][31:0];
			else st_data = c1_out[index][63:32];
		end
	end
	else st_data= 64'hx;

end

always_ff @(posedge clk) begin
	if(reset) begin
		for(int i=0;i<`BASE_WIDTH;i++)begin
			for(int j=0;j<8;j++)begin
				c2_prime[i][j] = '0;
				c1_prime_mod[i][j] <= '0;
				c0_prime_mod[i][j] <= '0;
			end
//			c1_out[i] <= '0;
//			c0_out[i] <= '0;
		end
		
		for(int i=0;i<`EXTEN_WIDTH;i++)begin
			for(int j=0;j<2;j++)begin
				//ct0[i][j] <= '0;
				//ct1[i][j] <= '0;
			end
			for(int j=0;j<8;j++)begin
			//	rln0[i][j] <= '0;
			//	rln1[i][j] <= '0;
				c1_prime[i][j] <= '0;
				c0_prime[i][j] <= '0;
			end
			mul_0_0[i] <= '0;
			mul_0_1[i] <= '0;
			mul_1_0[i] <= '0;
			mul_1_1[i] <= '0;
			//c0[i] <= '0;
			//c1[i] <= '0;
			//c2[i] <= '0;

		end
	end
	else if((state == load) && mem_resp)begin
/*
		if(counter < `NUM_ADDRESSES)begin
			if(!counter[0]) ct0[index][0][31:0] <= data;
			else ct0[index][0][63:32] <= data;
		end
		else if(counter < `NUM_ADDRESSES*2) begin
			if(!counter[0]) ct0[index][1][31:0] <= data;
			else ct0[index][1][63:32] <= data;
		end
		else if(counter < `NUM_ADDRESSES*3) begin
			if(!counter[0]) ct1[index][0][31:0] <= data;
			else ct1[index][0][63:32] <= data;
		end
		else if(counter < `NUM_ADDRESSES*4) begin
			if(!counter[0]) ct1[index][1][31:0] <= data;
			else ct1[index][1][63:32] <= data;
		end
//fix load order
		else if(counter < (`NUM_ADDRESSES*4 + (`NUM_ADDRESSES*8))) begin
			if(!counter[0]) rln0[index][upper_index][31:0] <= data;
			else rln0[index][upper_index][63:32] <= data;
		end
		else if(counter < (`NUM_ADDRESSES*4 + 2*(`NUM_ADDRESSES*8))) begin
			if(!counter[0]) rln1[index][upper_index][31:0] <= data;
			else rln1[index][upper_index][63:32] <= data;
		end
*/
	end

	else if(state == calc0) begin
		mul_0_0[a+b] <= mul_0_0[a+b] + (ct0[a][0] * ct1[b][0]);
		mul_0_1[a+b] <= mul_0_1[a+b] + (ct0[a][0] * ct1[b][1]);
		mul_1_0[a+b] <= mul_1_0[a+b] + (ct0[a][1] * ct1[b][0]);
		mul_1_1[a+b] <= mul_1_1[a+b] + (ct0[a][1] * ct1[b][1]);
	end

	else if(state == calc0_1) begin
		for(int i=0;i<`BASE_WIDTH-1;i++) begin
			mul_0_0_mod[i] <= mul_0_0[i] - mul_0_0[i+512];
			mul_0_1_mod[i] <= mul_0_1[i] - mul_0_1[i+512];
			mul_1_0_mod[i] <= mul_1_0[i] - mul_1_0[i+512];
			mul_1_1_mod[i] <= mul_1_1[i] - mul_1_1[i+512];
		end
			mul_0_0_mod[511] <= mul_0_0[511] ;
			mul_0_1_mod[511] <= mul_0_1[511] ;
			mul_1_0_mod[511] <= mul_1_0[511] ;
			mul_1_1_mod[511] <= mul_1_1[511] ;
	end
	// first mukltiply by t to a 134 bit type, then divide by q, and then mod
	// it
	else if(state == calc1_0) begin
		for(int i=0;i<`BASE_WIDTH;i++) begin
			c0_mult[i] <= t * (mul_0_0_mod[i]);
			c1_mult[i] <= t * (mul_0_1_mod[i] + mul_0_1_mod[i]);
			c2_mult[i] <= t * (mul_1_1_mod[i]);
		end
	end
	else if(state == calc1_1) begin
		for(int i=0;i<`BASE_WIDTH;i++) begin
			c0_mult[i] <= (c0_mult[i])/q;
			c1_mult[i] <= (c1_mult[i])/q;
			c2_mult[i] <= (c2_mult[i])/q;
		end
	end
	else if(state == calc1_2) begin
		for(int i=0;i<`BASE_WIDTH;i++) begin
/*
			c0[i] <= (c0_mult[i])%q;
			c1[i] <= (c1_mult[i])%q;
			c2[i] <= (c2_mult[i])%q;
*/
		end
	end

	else if(state == calc2) begin
		for(int i=0;i<8;i++) begin
			for(int j=0;j<`BASE_WIDTH;j++) begin
				c2_prime[j][i] <= (c2[j]/(t**(i))) %t;
			end
		end
	end
	else if(state == calc3) begin
		for(int i=0;i<8;i++) begin
			c0_prime[a+b][i] <= c0_prime[a+b][i] + (rln0[a][i] * c2_prime[b][i]);
			c1_prime[a+b][i] <= c1_prime[a+b][i] + (rln1[a][i] * c2_prime[b][i]);
		end
	end
	else if(state == calc3_0) begin
		for(int i=0;i<8;i++) begin
			for(int j=0;j<`BASE_WIDTH-1;j++) begin
				c0_prime_mod[j][i] <= c0_prime[j][i] - c0_prime[j+512][i];
				c1_prime_mod[j][i] <= c1_prime[j][i] - c1_prime[j+512][i];
			end
				c0_prime_mod[511][i] <= c0_prime[511][i];
				c1_prime_mod[511][i] <= c1_prime[511][i];
		end
	end
	//polynomial modulus again to make it back to 512
	else if(state == calc4) begin
		if(!calc_j) begin
			c0_out[calc_i] <= (c0[calc_i] + c0_prime_mod[calc_i][calc_j]) %q;
			c1_out[calc_i] <= (c1[calc_i] + c1_prime_mod[calc_i][calc_j]) %q;
		end
		else begin
			c0_out[calc_i] <= (c0_out[calc_i] + c0_prime_mod[calc_i][calc_j]) %q;
			c1_out[calc_i] <= (c1_out[calc_i] + c1_prime_mod[calc_i][calc_j]) %q;
		end

	end
end


always_ff @(posedge clk) begin
    if(state == idle)begin
        load_address <= source;
		store_address <= destination;
    end
end

always_ff @(posedge clk) begin 
	if((state == load || state == store)) begin
		if(mem_resp) counter <= counter +32'b1;
	end
	else counter <= '0;
end

always_ff @(posedge clk) begin
	if(state == calc0 ||state == calc3) begin
		if(b == (`BASE_WIDTH-1)) begin // 1024+1024-1
			a <= a+1;
			b <= '0;
		end
		else begin
			b <= b+1;
		end
	end
	else begin
		a <= '0;
		b <= '0;
	end
end

always_ff @(posedge clk) begin
	if(state == calc1_0) begin
		exten_width <= exten_width+1'b1;
	end
	else begin
		exten_width <= '0;
	end
end

always_ff @(posedge clk) begin
	if(state == calc2) begin
		if(c == (`BASE_WIDTH-1)) begin // 1024+1024-1
			index_small<= index_small+1'b1;
			c <= '0;
		end
		else begin
			c <= c+ 1;
		end
	end
	else begin
		c <= '0;
		index_small <= '0;
	end
end

always_ff @(posedge clk) begin
	if(state == calc4) begin
		if(calc_i == (`BASE_WIDTH-1)) begin // 1024+1024-1
			calc_i <= '0;
			calc_j <= calc_j+1;
		end
		else begin // 1024+1024-1
			calc_i <= calc_i+1;
		end
	end
	else begin
		calc_i <= '0;
		calc_j <= '0;
	end
end

always_ff @(posedge clk) begin
	if(reset) mem_resp_hold <= 1'b0;
	else if(mem_resp) mem_resp_hold <= 1'b1;
	else mem_resp_hold <= 1'b0;
end

//states are described

function automatic void set_defaults();
    mem_write = 1'b0;
    mem_read = 1'b0;
    accel_ready = 1'b0;
	address = '0;
	load_done = 1'b0;
	store_done = 1'b0;
	calc_done = 1'b0;
endfunction

function automatic void load_comb();
	address = load_address + 4*counter;
    if(counter >= `NUM_ADDRESSES*20) load_done = 1'b1;
    if(!mem_resp_hold) mem_read = 1'b1;
endfunction

function automatic void store_comb();
	address = store_address + 4*counter;
    if(counter >= `NUM_ADDRESSES*4) store_done = 1'b1;
    if(!mem_resp_hold) mem_write = 1'b1;
endfunction

function automatic void calc_comb();
	if( (a == (`BASE_WIDTH-1) && b == (`BASE_WIDTH-1)) || (exten_width == (`EXTEN_WIDTH-1))) calc_done = 1'b1;
	if( (c == (`BASE_WIDTH-1) && index_small == 7)) calc_done = 1'b1;
	if(calc_i == (`BASE_WIDTH-1) && (calc_j == 3'd7)) calc_done = 1'b1;
endfunction

always_comb begin
	next_state = state;
	case(state)
        idle: if(iq_assert) next_state = load;
        load: if(load_done) next_state = calc0;
        calc0: if(calc_done) next_state = calc0_1;
        calc0_1: next_state = calc1_0;

        calc1_0: next_state = calc1_1;
        calc1_1: next_state = calc1_2;
        calc1_2: next_state = calc2;

        calc2: next_state = calc3;
        calc3: if(calc_done) next_state = calc3_0;
        calc3_0: next_state = calc4;
        calc4: if(calc_done) next_state = store;
        store: if(store_done) next_state = idle;
	endcase
end

always_comb begin
    set_defaults();
	case(state)
        idle: accel_ready = 1'b1;
        load: load_comb();
        calc0,calc2,calc3,calc4: calc_comb();
        store: store_comb();
	endcase
end

always_ff @(posedge clk) begin
	if(reset)
	    state <= idle;
    else
	    state <= next_state;
end

endmodule : accel
