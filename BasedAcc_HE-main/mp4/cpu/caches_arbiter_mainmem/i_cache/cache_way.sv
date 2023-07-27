//Cashe way module 
//Contain the lru array,valid,dirty,tag and data array
module cache_way (
    input clk,
    input rst,

    input logic [31:0]    mem_address,
    input logic [31:0] mem_byte_enable256,

    input logic [255:0] data_in,

    input logic valid_in,

    input logic read_all,
    input logic load_tag,
    input logic load_valid,


    output logic [255:0] data_out,
    output logic [23:0] tag_out,
    output logic valid_out
   
);

logic [2:0] rindex,windex;
logic [23:0] tag_in;

assign rindex = mem_address[7:5];
assign windex = rindex;
assign tag_in = mem_address[31:8];

data_array data(
    .*,
    .read(read_all),
    .write_en(mem_byte_enable256),
    .rindex(rindex),
    .windex(windex),
    .datain(data_in),
    .dataout(data_out)
);

array #(3,24)tag_array//array 8 x tagBits
(
    .*,
    .read(read_all),
    .load(load_tag),
    .rindex(rindex),
    .windex(windex),
    .datain(tag_in),
    .dataout(tag_out)
);



array #(3,1)valid
(
    .*,
    .read(read_all),
    .load(load_valid),
    .rindex(rindex),
    .windex(windex),
    .datain(valid_in),
    .dataout(valid_out)

);

endmodule : cache_way
