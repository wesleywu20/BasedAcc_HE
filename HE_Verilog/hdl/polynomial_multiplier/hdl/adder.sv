//Will be replaced by a custom adder

module adder #(
    parameter int INPUT_WIDTH = 16,
    parameter int OUTPUT_WIDTH = 16
)(
    input  logic [ INPUT_WIDTH-1:0] a,
    input  logic [ INPUT_WIDTH-1:0] b,
    output logic [OUTPUT_WIDTH-1:0] sum
);
  assign sum = a + b;
endmodule
