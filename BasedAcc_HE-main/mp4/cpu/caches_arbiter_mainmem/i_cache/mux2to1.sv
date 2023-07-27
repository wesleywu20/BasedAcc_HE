module mux2to1
	#(parameter width = 256 )
	(input logic [width-1:0] d0,d1,
	input logic s,
	output logic [width-1:0] y);
	always_comb begin 
		if(s)
			y = d1;
		else 
			y = d0;
		end
endmodule
