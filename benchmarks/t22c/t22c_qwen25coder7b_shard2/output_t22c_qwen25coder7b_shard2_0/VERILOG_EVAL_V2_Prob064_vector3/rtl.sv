module TopModule (
    input logic [4:0] a,
    input logic [4:0] b,
    input logic [4:0] c,
    input logic [4:0] d,
    input logic [4:0] e,
    input logic [4:0] f,
    output logic [7:0] w,
    output logic [7:0] x,
    output logic [7:0] y,
    output logic [7:0] z
);

// Concatenate the inputs and append two 1-bits
logic [31:0] concatenated;
assign concatenated = {a, b, c, d, e, f, 2'b11};

// Split the concatenated vector into outputs
assign w = concatenated[31:24];
assign x = concatenated[23:16];
assign y = concatenated[15:8];
assign z = concatenated[7:0];

endmodule