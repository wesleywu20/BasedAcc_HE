`include "../hdl/he_headers.sv"

module du_tb;

   bit clk, start, done;
   always #1 clk = clk === 1'b0;
   bit rst;
   logic [2*`BIT_WIDTH-1:0] dividend;
   logic [`BIT_WIDTH-1:0] divisor, quotient, remainder;

   du dut(
          .clk(clk),
          .rst(rst),
          .dividend(dividend),
          .divisor(divisor),
          .quotient(quotient),
          .remainder(remainder),
          .start(start),
          .done(done)
          );

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task div(input [`BIT_WIDTH-1:0] dividend_i, input [`BIT_WIDTH-1:0] divisor_i);
      @(posedge clk);

      divisor = divisor_i;
      dividend = {{`BIT_WIDTH{1'b0}}, dividend_i};
      start = 1'b1;
      @(posedge clk) start = 1'b0;

      @(posedge clk iff done)
      $display("%x / %x = %x R %x", dividend_i, divisor_i, quotient, remainder);
   endtask // div


   initial begin
      $display("Starting du tests...");

      reset();
      div(-17-8*`_Q, `_Q);

      $finish;
    end

endmodule : du_tb
