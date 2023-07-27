import rv32i_types::*;
module based_mul
(
    input [31:0] a, b,
    output logic [63:0] f
);

assign f = a*b;

endmodule : based_mul
