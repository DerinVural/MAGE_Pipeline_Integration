module TopModule (
    input logic [7:0] in,
    output logic [31:0] out
);

    logic [23:0] sign_extension;

    assign sign_extension = {24{in[7]}},
           out = {sign_extension, in};

endmodule