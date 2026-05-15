module TopModule (
    input  logic [2:0] vec,
    output logic [2:0] outv,
    output logic o2,
    output logic o1,
    output logic o0
);

    // Assign the input vector directly to the output vector
    assign outv = vec;

    // Split the input vector into individual outputs:
    // o0 connects to position 0 (LSB)
    assign o0 = vec[0];
    // o1 connects to position 1
    assign o1 = vec[1];
    // o2 connects to position 2 (MSB)
    assign o2 = vec[2];

endmodule