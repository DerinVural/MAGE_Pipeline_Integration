module TopModule(
    input  logic [4:0] a,
    input  logic [4:0] b,
    input  logic [4:0] c,
    input  logic [4:0] d,
    input  logic [4:0] e,
    input  logic [4:0] f,
    output logic [7:0] w,
    output logic [7:0] x,
    output logic [7:0] y,
    output logic [7:0] z
);

    // Concatenate all inputs and the two 1-bit LSBs into a single 32-bit vector
    logic [31:0] full_stream;
    assign full_stream = {a, b, c, d, e, f, 2'b00};

    // Split the 32-bit vector into four 8-bit outputs
    assign w = full_stream[31:24];
    assign x = full_stream[23:16];
    assign y = full_stream[15:8];
    assign z = full_stream[7:0];

endmodule