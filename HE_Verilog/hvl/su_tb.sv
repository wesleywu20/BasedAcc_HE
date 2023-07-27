module su_tb#(
              parameter BIT_WIDTH = 64
              );

   bit clk, rst, done, start;
   always #1 clk = clk === 1'b0;

   logic [BIT_WIDTH-1:0] a, b, c;

   su dut(
          .clk(clk),
          .rst(rst),
          .a(a),
          .b(b),
          .c(c),
          .start(start),
          .done(done)
          );

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task sub(input [BIT_WIDTH-1:0] a_i, input [BIT_WIDTH-1:0] b_i);
      @(posedge clk);
      a = a_i;
      b = b_i;
      start = 1'b1;
      @(posedge clk) start = 1'b0;

      @(posedge clk iff done);
      $display("%x * %x = %x", a, b, c);
   endtask // mul

   initial begin
      $display("Starting su tests...");

      reset();
      sub(32'h8, 32'h5);

      $finish;
    end

endmodule : su_tb
