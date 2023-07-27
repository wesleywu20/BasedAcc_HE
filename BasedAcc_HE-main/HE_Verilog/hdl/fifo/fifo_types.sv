package fifo_types;

typedef enum {
    // Asserting reset_n @(negedge) should result in ready_o @(posedge)
    RESET_DOES_NOT_CAUSE_READY_O, 
    // When asserting yumi @(negedge), data_o should be the CORRECT value
    INCORRECT_DATA_O_ON_YUMI_I
} error_e;

typedef struct {
    error_e err;
    time ltime;
} error_report_t;

endpackage : fifo_types
