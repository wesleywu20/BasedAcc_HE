module half_adder(input logic a, b,
                  output logic s, c_out);
 
  always_comb begin
    s = a ^ b;
    c_out = a & b;
  end
  
endmodule 