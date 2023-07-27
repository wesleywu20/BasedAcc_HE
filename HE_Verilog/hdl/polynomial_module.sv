module polynomial_module(
                         logic                clk,
                         logic                rst,
                         logic [8-1:0][8-1:0] data_out
                         );

   polynomial_multiplier polynomial_multiplier(
                                               .clk(clk),
                                               .reset(~rst), // rst is active low, reset is active high
                                               .start(),
                                               .as(),
                                               .bs(),
                                               .carry(),
                                               .cs(data_out),
                                               .done()
                                               );

   always_ff @(posedge clk) begin

   end

endmodule
