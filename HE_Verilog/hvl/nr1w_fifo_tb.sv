`include "../hdl/he_headers.sv"

module nr1w_fifo_tb;

   bit clk, rst, valid, yumi;
   always #1 clk = clk === 1'b0;

   logic [`BIT_WIDTH-1:0] data_i;
   logic [`N_WRITE-1:0][`BIT_WIDTH-1:0] data_o;

   fifo_synch_1rnw dut(
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

   task enqueue_data(input logic [`BIT_WIDTH-1:0] data);
      data_i = {data};
      $display("Enqueueing %x", data_i);

      @(posedge clk) valid = 1'b1;
      @(posedge clk) valid = 1'b0;
   endtask // enqueue_data

   task dequeue();
      $display("data_o: %x", data_o);

      @(posedge clk) yumi = 1'b1;
      @(posedge clk) yumi = 1'b0;
   endtask // dequeue


   initial begin
      $display("Starting FIFO tests...");

      clear_signals();
      reset();

      // repeat(`N_WRITE) enqueue_data(3);
      for(int i = 0; i < 2*`N_WRITE; ++i) enqueue_data(i);

  //     enqueue_data(7);
//       enqueue_data(4);
      dequeue();
      dequeue();

      $finish;

   end

endmodule : nr1w_fifo_tb
