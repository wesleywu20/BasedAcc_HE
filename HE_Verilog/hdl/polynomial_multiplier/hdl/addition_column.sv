/*
A single column of partial products. The inputs are two vectors, in which the dot product is calculated. The output
of a single addition column module maps to a single calculated c value. The column has a HEIGHT, which presents the total 
number of partial products to be added together, which is a number needed by the adder tree module. 
*/

`include "../../multiplier_unit/hdl/half_multiplier.sv"
`include "../../multiplier_unit/hdl/half_adder.sv"
`include "../../multiplier_unit/hdl/full_adder.sv"

module addition_column #(
    parameter int MULTIPLIER_WIDTH = 8,
    parameter int HEIGHT = 1,
    parameter int INPUT_WIDTH = 8

) (
    input logic clk,
    input logic reset,
    input logic [HEIGHT-1:0][INPUT_WIDTH-1:0] as,
    input logic [HEIGHT-1:0][INPUT_WIDTH-1:0] bs,
    output logic [INPUT_WIDTH-1:0] c_value
);
  logic [HEIGHT-1:0][INPUT_WIDTH-1:0] partial_products;
  logic [$clog2(MULTIPLIER_WIDTH) - $clog2(HEIGHT) : 0][INPUT_WIDTH-1:0] delayed_outputs;
  genvar i;

  generate
    if (HEIGHT == 1) begin
      //if the column only needs to do one partial product, then an adder tree is not needed
      half_multiplier #(
          .MULT_WIDTH(INPUT_WIDTH)
      ) partial_product (
          .clk(clk),
          .x(as),
          .y(bs),
          .half_prod(delayed_outputs[0])
      );
    end else begin
      //generate the multipliers to create each partial product, and connect it to the adder tree
      for (i = 0; i < HEIGHT; i = i + 1) begin
        //initialize lane in first slice
        half_multiplier #(
            .MULT_WIDTH(INPUT_WIDTH)
        ) partial_product (
            .clk(clk),
            .x(as[i]),
            .y(bs[HEIGHT-1-i]),
            .half_prod(partial_products[i])
        );
      end
      //adder tree for summing up the multiple results of the multiplier
      adder_tree #(
          .INPUTS_NUM (HEIGHT),
          .IDATA_WIDTH(INPUT_WIDTH)
      ) at (
          .clk  (clk),
          .nrst (reset),
          .idata({partial_products}),
          .odata(delayed_outputs[0])
      );
    end
  endgenerate

    genvar k;
    generate
        for (k = 0; k < ($clog2(MULTIPLIER_WIDTH) - $clog2(HEIGHT)); k = k + 1) begin
            always_ff @(posedge clk) begin
                    delayed_outputs[k+1] <= delayed_outputs[k] ;
            end 
        end
    endgenerate

    assign c_value = delayed_outputs[$clog2(MULTIPLIER_WIDTH) - $clog2(HEIGHT) ];




endmodule
