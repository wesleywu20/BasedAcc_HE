`ifndef testbench
`define testbench

`include "../mult_constants.sv"

module testbench(multiplier_itf.testbench itf);

/* define dut to be half multiplier width based if macro defined */
`ifdef test_half_mult
    half_multiplier dut (
        .clk        ( itf.clk          ),
        .x          ( itf.multiplicand ),
        .y          ( itf.multiplier   ),
        .half_prod  ( itf.half_product )
    );
`endif

/* define dut to be full multiplier width based if macro defined */
`ifdef test_full_mult
    parallel_multiplier dut (
        .clk        ( itf.clk          ),
        .x          ( itf.multiplicand ),
        .y          ( itf.multiplier   ),
        .prod       ( itf.product      )
    );
`endif

/* define dut to be smaller multiplier width based if macro defined */
`ifdef test_param_mult
    param_multiplier dut (
        .clk        ( itf.clk             ),
        .x          ( itf.multiplicand    ),
        .y          ( itf.byte_multiplier ),
        .prod       ( itf.small_product   )
    );
`endif

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    /* assertions based on full multiplier width results */
    `ifdef test_full_mult
        ##(2);
        itf.multiplicand <= 64'h0;
        itf.multiplier <= 64'h0123456789ABCDEF;
        ##(2);
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);

        ##(5);
        itf.multiplicand <= 64'h1;
        itf.multiplier <= 64'h1111111111111111;
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);

        ##(5);
        itf.multiplicand <= 64'h123456789ABCDEF0;
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);

        ##(5);

        itf.multiplier <= 64'h2349082309482384;
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);

        ##(5);

        itf.multiplicand <= 64'h349;
        itf.multiplier <= 64'h123;
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);

        ##(5);

        itf.multiplicand <= 64'h69420;
        itf.multiplier <= 64'h42069;
        assert (itf.product == itf.multiplicand * itf.multiplier) $display("product same as sv * operator");
        else  $error("product differs from sv * operator\nproduct should be: %d\nproduct is: %d", itf.multiplicand * itf.multiplier, itf.product);
    `endif

    /* assertions based on lower half-product results */
    `ifdef test_half_mult
        ##(2);
        itf.multiplicand <= 64'h0;
        itf.multiplier <= 64'h0123456789ABCDEF;
        ##(2);
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);

        ##(5);
        itf.multiplicand <= 64'h1;
        itf.multiplier <= 64'h1111111111111111;
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);

        ##(5);
        itf.multiplicand <= 64'h123456789ABCDEF0;
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);

        ##(5);

        itf.multiplier <= 64'h2349082309482384;
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);

        ##(5);

        itf.multiplicand <= 64'h349;
        itf.multiplier <= 64'h123;
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);

        ##(5);

        itf.multiplicand <= 64'h69420;
        itf.multiplier <= 64'h42069;
        assert (itf.half_product == (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK) $display("half product same as sv * operator");
        else  $error("half product differs from sv * operator\nproduct should be: %d\nproduct is: %d", (itf.multiplicand * itf.multiplier) & `HALF_PROD_MASK, itf.half_product);
    `endif

    /* assertions based on small product results */
    `ifdef test_param_mult
        ##(2);
        itf.multiplicand <= 64'h0;
        itf.byte_multiplier <= 8'hFF;
        ##(2);
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %x\nproduct is: %x", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);

        ##(5);
        itf.multiplicand <= 64'h1;
        itf.byte_multiplier <= 8'hAF;
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %x\nproduct is: %x", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);

        ##(5);
        itf.multiplicand <= 64'h523456789ABCDEF0;
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %d\nproduct is: %d", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);

        ##(5);

        itf.byte_multiplier <= 8'hFF;
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %x\nproduct is: %x", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);

        ##(5);

        itf.multiplicand <= 64'h12345;
        itf.byte_multiplier <= 8'h12;
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %x\nproduct is: %x", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);

        ##(5);

        itf.multiplicand <= 64'h69420;
        itf.byte_multiplier <= 8'h69;
        assert (itf.small_product == {8'h0, itf.multiplicand} * itf.byte_multiplier) $display("small product same as sv * operator");
        else  $error("small product differs from sv * operator\nproduct should be: %x\nproduct is: %x", {8'h0, itf.multiplicand} * itf.byte_multiplier, itf.small_product);
    `endif

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
