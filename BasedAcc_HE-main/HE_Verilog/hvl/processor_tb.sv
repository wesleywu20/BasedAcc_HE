`include "../hdl/he_headers.sv"

module processor_tb;

   bit clk;
   always #1 clk = clk === 1'b0;
   bit rst;

   logic [`BIT_WIDTH-1:0] t, q, data_i, data_o;
   logic                  valid_i, ready_o, done_o;

   processor dut(
                 .clk(clk),
                 .rst(rst),
                 .t(t),
                 .q(q),
                 .data_i(data_i),
                 .valid_i(valid_i),
                 .ready_o(ready_o),
                 .data_o(data_o),
                 .done_o(done_o)
                 );

   task clear_signals();
      rst = 1'b0;
      valid_i = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task process_coeff(input logic[`BIT_WIDTH-1:0] coeff);
      @(posedge clk);
      q = 32'h2; // Lol this isn't even prime
      t = 32'h15;
      data_i = coeff;
      @(posedge clk) valid_i = 1'b1;
      @(posedge clk) valid_i = 1'b0; // TODO shouldn't need

      @(posedge clk iff done_o) begin
         $display("%x", data_o);

         assert (data_o == ((coeff*t)/q)%q);
      end

   endtask // process_coeff

   initial begin
      $display("Starting processor unit tests...");
      clear_signals();
      reset();

      repeat(1000) process_coeff($urandom());

      $finish;
    end


endmodule : processor_tb
