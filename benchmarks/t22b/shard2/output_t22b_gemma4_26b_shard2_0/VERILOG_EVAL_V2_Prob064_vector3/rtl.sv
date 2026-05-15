module TopModule (
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

    // Internal signal to hold the 32-bit concatenation
    logic [31:0] combined;

    // Concatenate the inputs and the two LSB bits
    assign combined = {a, b, c, d, e, f, 2'b00};

    // Split the 32-bit signal into four 8-bit outputs
    assign {w, x, y, z} = combined;

endmodule