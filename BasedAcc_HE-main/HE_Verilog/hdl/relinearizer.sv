`include "he_headers.sv"

module relinearizer(
 input logic                   rst,
 input logic                   clk,
 input logic                   ready_i,
 input logic [`BIT_WIDTH-1:0]  coeff_i,
 output logic                  ready_o,
 output logic [`BIT_WIDTH-1:0] coeff_o
);

always_comb begin
   coeff_o = coeff_i;
   ready_o = ready_i;
end

always_ff @(posedge clk) begin

end

endmodule
