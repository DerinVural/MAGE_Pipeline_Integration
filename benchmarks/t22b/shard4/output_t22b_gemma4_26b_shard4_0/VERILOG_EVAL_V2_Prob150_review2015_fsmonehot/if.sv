module TopModule (
    input  logic        d,
    input  logic        done_counting,
    input  logic        ack,
    input  logic [9:0]  state,
    output logic        B3_next,
    output logic        S_next,
    output logic        S1_next,
    output logic        Count_next,
    output logic        Wait_next,
    output logic        done,
    output logic        counting,
    output logic        shift_ena
);
endmodule