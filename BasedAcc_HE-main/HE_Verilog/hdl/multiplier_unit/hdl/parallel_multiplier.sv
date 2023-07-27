module parallel_multiplier #(parameter MULT_WIDTH = 64)
  (
  input logic clk,
  input logic [MULT_WIDTH-1:0] x, y,
  output logic [MULT_WIDTH*2-1:0] prod
  );
  
  logic [MULT_WIDTH-2:0] sum_rows [MULT_WIDTH];
  logic [MULT_WIDTH-2:0] carry_rows [MULT_WIDTH];
  
  // first row of adders different because it only uses half adders
  generate
    for (genvar i = 0; i < MULT_WIDTH - 1; i = i + 1) begin
      half_adder ha(.a(x[i + 1] & y[0]), .b(x[i] & y[1]), 
                    .s(sum_rows[0][i]), .c_out(carry_rows[0][i]));
    end
  endgenerate
  
  // array of MULT_WIDTH * MULT_WIDTH adders for calculating partial products
  generate
    for (genvar y_idx = 2; y_idx < MULT_WIDTH; y_idx = y_idx + 1) begin
      for (genvar x_idx = 0; x_idx < MULT_WIDTH - 1; x_idx = x_idx + 1) begin
        if (x_idx < MULT_WIDTH - 2) begin
          full_adder fa(.a(x[x_idx] & y[y_idx]), .b(sum_rows[y_idx - 2][x_idx + 1]), .c_in(carry_rows[y_idx - 2][x_idx]),
                        .s(sum_rows[y_idx - 1][x_idx]), .c_out(carry_rows[y_idx - 1][x_idx]));
        end
        else begin
          full_adder fa_outer(.a(x[x_idx + 1] & y[y_idx - 1]), .b(x[x_idx] & y[y_idx]), .c_in(carry_rows[y_idx - 2][x_idx]),
                          .s(sum_rows[y_idx - 1][x_idx]), .c_out(carry_rows[y_idx - 1][x_idx]));
        end
      end
    end
  endgenerate

  // last row of full adders (chained carry bits)
  generate
    for (genvar j = 0; j < MULT_WIDTH - 2; j = j + 1) begin
      if (j == 0) begin
        full_adder lsb(.a(1'b0), .b(sum_rows[MULT_WIDTH - 2][j + 1]), .c_in(carry_rows[MULT_WIDTH - 2][j]),
                       .s(sum_rows[MULT_WIDTH - 1][j]), .c_out(carry_rows[MULT_WIDTH - 1][j]));
      end
      else begin
        full_adder others(.a(sum_rows[MULT_WIDTH - 2][j + 1]), .b(carry_rows[MULT_WIDTH - 1][j - 1]), .c_in(carry_rows[MULT_WIDTH - 2][j]),
                          .s(sum_rows[MULT_WIDTH - 1][j]), .c_out(carry_rows[MULT_WIDTH - 1][j]));
      end
    end
  endgenerate

  full_adder prod_msb(.a(carry_rows[MULT_WIDTH - 1][MULT_WIDTH - 3]), .b(x[MULT_WIDTH - 1] & y[MULT_WIDTH - 1]), .c_in(carry_rows[MULT_WIDTH - 2][MULT_WIDTH - 2]),
                      .s(sum_rows[MULT_WIDTH - 1][MULT_WIDTH - 2]), .c_out(carry_rows[MULT_WIDTH - 1][MULT_WIDTH - 2]));

  // assign partial product of last adder in row to next LSB in full product
  always_comb begin
    prod[0] = x[0] & y[0];
    for (int row = 1; row < MULT_WIDTH; row++) begin
      prod[row] = sum_rows[row - 1][0];
    end
    prod[MULT_WIDTH*2-1:MULT_WIDTH] = {carry_rows[MULT_WIDTH - 1][MULT_WIDTH - 2], sum_rows[MULT_WIDTH - 1]};
  end

endmodule