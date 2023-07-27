module test();

   integer fd;
   logic [8-1:0] a;


   initial begin
      $display("Test");

      fd = $fopen("../hvl/data/ct10_fresh.bin", "r");

      while($fgets(a, fd)) begin
         $display("%x", a);
      end

      $finish();

 end

endmodule : test
