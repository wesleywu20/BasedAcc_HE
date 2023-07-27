/*
Needs to be further implemented
*/

module multiplier #(
    parameter int INPUT_WIDTH = 16
) (
    input  logic [ INPUT_WIDTH-1:0] a,
    input  logic [ INPUT_WIDTH-1:0] b,
    output logic [ INPUT_WIDTH-1:0] product
);
  assign product = a * b;
endmodule
