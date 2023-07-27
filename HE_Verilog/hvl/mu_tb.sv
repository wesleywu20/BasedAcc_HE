`include "../hdl/he_headers.sv"

module mu_tb();

   bit clk, rst, done, start;
   always #1 clk = clk === 1'b0;

   logic [`BIT_WIDTH-1:0] a, b;
   logic [2*`BIT_WIDTH-1:0] c;


   mu dut(
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

   task mul(input [`BIT_WIDTH-1:0] a_i, input [`BIT_WIDTH-1:0] b_i);
      @(posedge clk);
      a = a_i;
      b = b_i;
      start = 1'b1;
      // @(posedge clk) start = 1'b0;

      @(posedge clk iff done);
      $display("%x * %x = %x", a, b, c);
   endtask // mul

   initial begin
      $display("Starting mu tests...");

      reset();
      mul(32'h1, 32'h5);


      $finish;
    end

endmodule : mu_tb
