module TopModule (
    input  logic [2:0] vec,
    output logic [2:0] outv,
    output logic o2,
    output logic o1,
    output logic o0
);

    // Assign the full vector to outv
    assign outv = vec;

    // Split the vector into individual bits
    assign o2 = vec[2];
    assign o1 = vec[1];
    assign o0 = vec[0];

endmodule