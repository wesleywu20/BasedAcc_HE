module param_multiplier 
 #(parameter X_WIDTH = 64,
   parameter Y_WIDTH = 8)
  (
  input logic clk,
  input logic [X_WIDTH-1:0] x,
  input logic [Y_WIDTH-1:0] y,
  output logic [(X_WIDTH+Y_WIDTH)-1:0] prod
  );
  
  logic [X_WIDTH-2:0] sum_rows [Y_WIDTH];
  logic [X_WIDTH-2:0] carry_rows [Y_WIDTH];
  
  // first row of adders different because it only uses half adders
  generate
    for (genvar i = 0; i < X_WIDTH - 1; i = i + 1) begin
      half_adder ha(.a(x[i + 1] & y[0]), .b(x[i] & y[1]), 
                    .s(sum_rows[0][i]), .c_out(carry_rows[0][i]));
    end
  endgenerate
  
  // array of MULT_WIDTH * MULT_WIDTH adders for calculating partial products
  generate
    for (genvar y_idx = 2; y_idx < Y_WIDTH; y_idx = y_idx + 1) begin
      for (genvar x_idx = 0; x_idx < X_WIDTH - 1; x_idx = x_idx + 1) begin
        if (x_idx < X_WIDTH - 2) begin
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
    for (genvar j = 0; j < X_WIDTH - 2; j = j + 1) begin
      if (j == 0) begin
        full_adder lsb(.a(1'b0), .b(sum_rows[Y_WIDTH - 2][j + 1]), .c_in(carry_rows[Y_WIDTH - 2][j]),
                       .s(sum_rows[Y_WIDTH - 1][j]), .c_out(carry_rows[Y_WIDTH - 1][j]));
      end
      else begin
        full_adder others(.a(sum_rows[Y_WIDTH - 2][j + 1]), .b(carry_rows[Y_WIDTH - 1][j - 1]), .c_in(carry_rows[Y_WIDTH - 2][j]),
                          .s(sum_rows[Y_WIDTH - 1][j]), .c_out(carry_rows[Y_WIDTH - 1][j]));
      end
    end
  endgenerate

  full_adder prod_msb(.a(carry_rows[Y_WIDTH - 1][X_WIDTH - 3]), .b(x[X_WIDTH - 1] & y[Y_WIDTH - 1]), .c_in(carry_rows[Y_WIDTH - 2][X_WIDTH - 2]),
                      .s(sum_rows[Y_WIDTH - 1][X_WIDTH - 2]), .c_out(carry_rows[Y_WIDTH - 1][X_WIDTH - 2]));

  // assign partial product of last adder in row to next LSB in full product
  always_comb begin
    prod[0] = x[0] & y[0];
    for (int row = 1; row < Y_WIDTH; row++) begin
      prod[row] = sum_rows[row - 1][0];
    end
    prod[(X_WIDTH+Y_WIDTH)-1:Y_WIDTH] = {carry_rows[Y_WIDTH - 1][X_WIDTH - 2], sum_rows[Y_WIDTH - 1]};
  end

endmodule