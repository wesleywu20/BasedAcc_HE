`define DEBUG 1

// ************************* Input Properties *************************
`define BIT_WIDTH 64
`define DEGREE_N 16
`define TILE_N 4
`define N_WRITE `TILE_N
`define WRITE_SIZE 1
`define READ_SIZE `TILE_N

// ************************* Encryption Parameters *************************
`define _t 16
`define _Q 1048193
// `define _Q 288230376151711681
// `define _T 256
`define _T 256
`define T_ `_T
`define RELIN_N $clog2(`_T)
// `define _Q 10
// `define _T 10
`define L_ 7 // int(math.floor(math.log(_Q, _T)))
