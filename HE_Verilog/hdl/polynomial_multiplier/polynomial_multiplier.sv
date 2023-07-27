/*
Top level module for the polynomial multiplier
Takes two parameters:
1) the dimension of the multiplier array (8 x 8 multipliers, 4 x 4 multipliers, etc.)
2) The width of each coefficient of the polynomial, called INPUT_WIDTH

This is right now set up to take in N coefficients of A, and N coefficients of B, if 
the multiplication unit utilizes N x N multipliers. After the multipliers complete and the partial sums
are calculated using the adder tree, the done signal will be raused and 
2N-1 c values should be outputted, to represent the polynomial product of the two N long inputs. 
*/

/*
TODO: Implement carry and start/done signals, and reset
TODO: Make the output width twice the width of the inputs
*/

module polynomial_multiplier #(
    parameter int MULTIPLIER_WIDTH = 8,
    parameter int INPUT_WIDTH = 8
) (
    input logic clk,
    input logic reset,
    input logic start,
    input logic [MULTIPLIER_WIDTH-1:0][INPUT_WIDTH-1:0] as,
    input logic [MULTIPLIER_WIDTH-1:0][INPUT_WIDTH-1:0] bs,
    input logic [2*MULTIPLIER_WIDTH-2:0][INPUT_WIDTH-1:0] carry,
    output logic [2*MULTIPLIER_WIDTH-2:0][INPUT_WIDTH-1:0] cs,
    output logic done
);

    logic [$clog2(MULTIPLIER_WIDTH):0] ready_counter;
  genvar column_height;

  // A N by M multiplier creates 2n-1 columns of partial products, which is the module addition_column
  // All the elements of each column are summed together using the adder tree. 
  generate
    for (
        column_height = 1; column_height < MULTIPLIER_WIDTH; column_height = column_height + 1
    ) begin
      //Initialize the pair of columns of column height N
      addition_column #(
          .MULTIPLIER_WIDTH(MULTIPLIER_WIDTH),
          .HEIGHT(column_height),
          .INPUT_WIDTH(INPUT_WIDTH)
      ) column_first_half (
          .clk(clk),
          .reset(reset),
          .as(as[column_height-1:0]),
          .bs(bs[column_height-1:0]),
          .c_value(cs[column_height-1])
      );
      addition_column #(
        .MULTIPLIER_WIDTH(MULTIPLIER_WIDTH),
          .HEIGHT(column_height),
          .INPUT_WIDTH(INPUT_WIDTH)
      ) column_second_half (
          .clk(clk),
          .reset(reset),
          .as(as[MULTIPLIER_WIDTH-1:MULTIPLIER_WIDTH-column_height]),
          .bs(bs[MULTIPLIER_WIDTH-1:MULTIPLIER_WIDTH-column_height]),
          .c_value(cs[2*MULTIPLIER_WIDTH-1-column_height])
      );

    end
  endgenerate

  //Initialize single column with the greatest height of MULTIPLIER_WIDTH
  addition_column #(
    .MULTIPLIER_WIDTH(MULTIPLIER_WIDTH),
      .HEIGHT(MULTIPLIER_WIDTH),
      .INPUT_WIDTH(INPUT_WIDTH)
  ) column_middle (
      .clk(clk),
      .reset(reset),
      .as(as),
      .bs(bs),
      .c_value(cs[MULTIPLIER_WIDTH-1])
  );
  assign next_ready_counter = ready_counter + 1;
  
    assign ready_counter[0] = start;
  genvar k;
    generate
        for (k = 0; k < ($clog2(MULTIPLIER_WIDTH)); k = k + 1) begin
            always_ff @(posedge clk) begin
               
                    ready_counter[k+1] <= ready_counter[k] ;
               
            end 
        end
    endgenerate
  assign done = ready_counter[$clog2(MULTIPLIER_WIDTH)];

endmodule
