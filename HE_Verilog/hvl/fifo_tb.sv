module fifo_tb;

   bit clk, rst, valid, yumi;
   always #1 clk = clk === 1'b0;

   logic [7:0] data_i, data_o;

   fifo_synch_1r1w dut(
                       .clk_i(clk),
                       .reset_n_i(rst),
                       .data_i(data_i),
                       .valid_i(valid),
                       .ready_o(),
                       .valid_o(),
                       .data_o(data_o),
                       .next_data_o(),
                       .yumi_i(yumi)
                       );

   task clear_signals();
      rst = 1'b1;
      valid = 1'b0;
      yumi = 1'b0;
   endtask // clear_signals

   task reset();
      @(posedge clk) rst = 1'b0;
      @(posedge clk) rst = 1'b1;
   endtask // reset

   task enqueue_data(input logic [7:0] data);
      data_i = data;
      $display("Enqueuing %x", data);

      @(posedge clk) valid = 1'b1;
      @(posedge clk) valid = 1'b0;
   endtask // enqueue_data

   task dequeue();
      @(posedge clk) $display("%x", data_o);
      yumi = 1'b1;
      @(posedge clk) yumi = 1'b0;
   endtask // dequeue


   initial begin
      $display("Starting FIFO tests...");

      clear_signals();
      reset();

      repeat(5) enqueue_data($urandom() % 256);
      repeat(5) dequeue();


      $finish;

   end

endmodule : fifo_tb
