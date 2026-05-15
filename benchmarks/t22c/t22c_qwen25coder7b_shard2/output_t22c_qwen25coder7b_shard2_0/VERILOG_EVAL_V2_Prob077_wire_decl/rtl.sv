module TopModule(
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out,
    output logic out_n
);

// Intermediate wires
logic and1;
logic and2;
logic or1;

// Combinational logic
assign and1 = a & b;
assign and2 = c & d;
assign or1 = and1 | and2;
assign out = or1;
assign out_n = ~or1;

endmodule