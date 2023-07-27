`include "../hdl/he_headers.sv"

module multi_fifo_tb;

   bit clk, rst, valid, yumi, valid_o;
   always #1 clk = clk === 1'b0;

   logic [`WRITE_SIZE-1:0][`BIT_WIDTH-1:0] data_i;
   logic [`READ_SIZE-1:0][`BIT_WIDTH-1:0] data_o;

   param_fifo #(.WIDTH(`BIT_WIDTH), .READ_SIZE(`READ_SIZE), .WRITE_SIZE(`WRITE_SIZE), .PTR_WIDTH(8))
   dut(
                 .clk_i(clk),
                 .reset_n_i(rst),
                 .data_i(data_i),
                 .valid_i(valid),
                 .ready_o(),
                 .valid_o(valid_o),
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
      data_i = {`WRITE_SIZE{data}};
      for(int i = 0; i < `WRITE_SIZE; ++i) begin
         data_i[i] += i;
         // $display("Enqueueing %x", data_i[i]);
      end
      // $display("Enqueueing %x", data);


      @(posedge clk) valid = 1'b1;
      @(posedge clk) valid = 1'b0;
   endtask // enqueue_data

   task dequeue();
      @(posedge clk) for(int i = 0; i < `READ_SIZE; ++i)
        $write("%x ", data_o[i]);
      $write("\n");

      yumi = 1'b1;
      @(posedge clk) yumi = 1'b0;
      @(posedge clk);

   endtask // dequeue

   task enqueue_dequeue_sync(input logic [`BIT_WIDTH-1:0] data);
      data_i = {`WRITE_SIZE{data}};
      for(int i = 0; i < `WRITE_SIZE; ++i) begin
         data_i[i] += i;
      end

      @(posedge clk) for(int i = 0; i < `READ_SIZE; ++i)
        $write("%x ", data_o[i]);
      $write("\n");

      valid = 1'b1;
      yumi = 1'b1;

      @(posedge clk);
      valid = 1'b0;
      yumi = 1'b0;
   endtask // enqueue_dequeue_sync

   initial begin
      $display("Starting FIFO tests...");

      clear_signals();
      reset();

      // for(int i = 0; i < 2*`READ_SIZE; i+= `WRITE_SIZE) enqueue_data(i);
      enqueue_data(4);
      enqueue_data(0);
      enqueue_data(2);
      enqueue_dequeue_sync(6);
      dequeue();



//       repeat(`N_WRITE) dequeue();

      @(posedge clk) while(valid_o) dequeue();


      $finish;

   end

endmodule : multi_fifo_tb
