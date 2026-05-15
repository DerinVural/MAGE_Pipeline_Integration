module TopModule(input logic [31:0] in, output logic [31:0] out);

// Extract individual bytes
logic [7:0] b0 = in[7:0];
logic [7:0] b1 = in[15:8];
logic [7:0] b2 = in[23:16];
logic [7:0] b3 = in[31:24];

// Rearrange bytes to reverse order
assign out = {b3, b2, b1, b0};

endmodule