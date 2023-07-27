`ifndef testbench2
`define testbench2
module testbench2;

    logic clk;
    logic rst;
    logic i_read_in;
    logic d_read_in,d_write_in;
    logic i_mem_resp;
    logic d_mem_resp;
    //Outputs
    logic i_read_out,d_read_out,d_write_out;

    always #5 clk = (clk === 1'b0);



arbiter dut (
    .clk(clk),
    .reset(rst),
    .i_read_in(i_read_in),
    .d_read_in(d_read_in),
    .d_write_in(d_write_in),
    .i_mem_resp(i_mem_resp),
    .d_mem_resp(d_mem_resp),
    //Outputs
    .i_read_out(i_read_out),.d_read_out(d_read_out),.d_write_out(d_write_out)
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, testbench, "+all");
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge clk); endclocking

task reset();
    rst <= 1'b0;
    ##(10);
    rst <= 1'b1;
    ##(1);
endtask : reset

task finish();
    repeat (2000) @(posedge clk);
    $finish;
endtask




// DO NOT MODIFY CODE ABOVE THIS LINE

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Fill the enquer until the signal says it is full
    // 256 loop 256
    //for(int i=0;i<256;i++)begin 
    //end 
/*
    logic clk;
    logic reset;
    logic i_read_in;
    logic d_read_in,d_write_in;
    logic i_mem_resp;
    logic d_mem_resp;


*/
    d_mem_resp = '0;
    i_mem_resp = '0;
    d_read_in<='0;
    d_write_in<='0;
    i_read_in <= '1; //should dequeue
    ##(1)
    i_mem_resp<= '1;
    d_read_in<= '1;
    ##(1)
    i_mem_resp<= '0;
    ##(1)
    d_mem_resp<='1;
    d_read_in<='1;
    ##(1)
    d_mem_resp<='0;
    ##(1)
    d_mem_resp<='1;
    d_read_in<='1;
    ##(1)
    d_mem_resp<='0;
    ##(1)
    i_mem_resp <='1;
    ##(1)
    i_mem_resp <= '0;


     

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    finish();
    $error("TB: Illegal Exit ocurred");
end


endmodule 
`endif
