module full_adder(input logic a, b, c_in,
                  output logic s, c_out);

  assign s = (a ^ b) ^ c_in;
  assign c_out = (c_in & (a ^ b)) | (a & b);
  
endmodule