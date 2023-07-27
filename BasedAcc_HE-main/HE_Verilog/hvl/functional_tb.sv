`include "../hdl/he_headers.sv"

module functional_tb;

   bit clk;
   always #1 clk = clk === 1'b0;
   bit rst;

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] ct00, ct01, ct10, ct11;
   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] res [1:0];
   logic [`BIT_WIDTH-1:0]                t, q;

   logic                                 start_i, valid_o;

   functional dut
     (
      .clk(clk),
      .rst(rst),
      .t(t),
      .q(q),
      .start_i(start_i),
      .ct00(ct00),
      .ct01(ct01),
      .ct10(ct10),
      .ct11(ct11),
      .valid_o(valid_o),
      .res(res)
      );

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task clear_signals();
      rst = 1'b1;
      start_i = 1'b0;
   endtask // clear_signals

   task set_params(input logic [`BIT_WIDTH-1:0] t_n, q_n);
      t = t_n;
      q = q_n;
   endtask // set_params

   task start(input logic [`DEGREE_N-1:0][`BIT_WIDTH] a_0, a_1, b_0, b_1);
      ct00 = a_0;
      ct01 = a_1;
      ct10 = b_0;
      ct11 = b_1;

      @(posedge clk) start_i = 1'b1;
      @(posedge clk) start_i = 1'b0;

   endtask // start

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] a_0, a_1, b_0, b_1;

   initial begin
      $display("Functional TB");

      clear_signals();
      reset();

      set_params(`BIT_WIDTH'h5, `BIT_WIDTH'h9);

      a_0 = {`DEGREE_N{`BIT_WIDTH'h1}};
      a_1 = {`DEGREE_N{`BIT_WIDTH'h2}};
      b_0 = {`DEGREE_N{`BIT_WIDTH'h3}};
      b_1 = {`DEGREE_N{`BIT_WIDTH'h4}};

      $display("%x", a_0);


      start(a_0, a_1, b_0, b_1);

      @(posedge clk iff valid_o) $display("----- DONE -----");

      $finish;
    end

endmodule : functional_tb
