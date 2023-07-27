module half_multiplier #(parameter MULT_WIDTH = 64)
  (
  input logic clk,
  input logic [MULT_WIDTH-1:0] x, y,
  output logic [MULT_WIDTH-1:0] half_prod
  );
  
  logic [MULT_WIDTH-2:0] sum_rows [MULT_WIDTH];
  logic [MULT_WIDTH-2:0] carry_rows [MULT_WIDTH];
  
  // first row of adders different because it only uses half adders
  assign half_prod[0] = x[0] & y[0];
  generate
    for (genvar i = 0; i < MULT_WIDTH - 1; i = i + 1) begin
      half_adder ha(.a(x[i + 1] & y[0]), .b(x[i] & y[1]), 
                    .s(sum_rows[0][i]), .c_out(carry_rows[0][i]));
    end
  endgenerate
  
  // array of MULT_WIDTH * MULT_WIDTH adders for calculating partial products
  generate
    for (genvar y_idx = 2; y_idx < MULT_WIDTH; y_idx = y_idx + 1) begin
      for (genvar x_idx = 0; x_idx < MULT_WIDTH - 1 - (y_idx - 1); x_idx = x_idx + 1) begin
          full_adder fa(.a(x[x_idx] & y[y_idx]), .b(sum_rows[y_idx - 2][x_idx + 1]), .c_in(carry_rows[y_idx - 2][x_idx]),
                        .s(sum_rows[y_idx - 1][x_idx]), .c_out(carry_rows[y_idx - 1][x_idx]));
      end
    end
  endgenerate

  // assign partial product of last adder in row to next LSB in full product
  always_comb begin
    for (int row = 1; row < MULT_WIDTH; row++) begin
      half_prod[row] = sum_rows[row - 1][0];
    end
  end

endmodule