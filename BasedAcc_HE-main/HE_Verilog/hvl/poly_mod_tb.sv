`include "../hdl/he_headers.sv"

module poly_mod_tb;

   bit clk;
   always #1 clk = clk === 1'b0;

   bit rst, valid_i, valid_o;
   logic [`BIT_WIDTH-1:0] q, coeff_i, coeff_o;

   poly_mod dut(
                .clk(clk),
                .rst(rst),
                .q(q),
                .coeff_i(coeff_i),
                .valid_i(valid_i),
                .coeff_o(coeff_o),
                .valid_o(valid_o)
                );

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
      $display("Reset module.");

   endtask // reset

   task clear_signals();
      rst = 1'b1;
      valid_i = 1'b0;

      $display("Cleared signals.");

   endtask // clear_signals

   task enqueue_coeff(logic [`BIT_WIDTH-1:0] a);
      @(posedge clk);
      valid_i = 1'b1;
      coeff_i = a;

      @(posedge clk) valid_i = 1'b0;
   endtask // enqueue_coeff

   initial begin
      $display("Starting poly_mod unit tests...");

      clear_signals();
      reset();
      @(posedge clk);


      q = `BIT_WIDTH'h1337;

      repeat(`DEGREE_N) enqueue_coeff(`BIT_WIDTH'h12);
      repeat(`DEGREE_N) enqueue_coeff(`BIT_WIDTH'h10);

      repeat(1000) @(posedge clk); // Run clock to allow dequeueing to complete
      $finish;
   end

   always_ff @(posedge clk iff valid_o) begin // Output sync
      $display("%x", coeff_o);
   end

endmodule // poly_mod_tb
