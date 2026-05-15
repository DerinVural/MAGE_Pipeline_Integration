module TopModule(
    input  logic [1:0] A,
    input  logic [1:0] B,
    output logic       z
);

    // The equality operator == returns 1 if both vectors are identical
    assign z = (A == B);

endmodule