module top_tb();

   logic [`DEGREE_N-1:0][`BIT_WIDTH-1:0] ct00_i, ct01_i, ct10_i, ct11_i;

   initial begin
      $display("Starting tests...");

      // Load inputs
      fd_00 = $fopen("ct10_fresh.bin", "r");
      fd_01 = $fopen("ct11_fresh.bin", "r");
      fd_10 = $fopen("ct20_fresh.bin", "r");
      fd_11 = $fopen("ct21_fresh.bin", "r");

      for(int i = 0; i < `DEGREE_N; ++i)
        for(int j = 0; j < 8; ++j) begin // Endian-ness :(

        end
   end

endmodule // top_tb
