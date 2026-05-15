module top_level (
    input logic x,
    input logic y,
    output logic z
);

// Declaration of wires for outputs of submodules
wire mod_a1_z;
wire mod_a2_z;
wire mod_b1_z;
wire mod_b2_z;

// Instances of Module A and Module B
mod_a mod_a_inst1 (.x(x), .y(y), .z(mod_a1_z));
mod_a mod_a_inst2 (.x(x), .y(y), .z(mod_a2_z));
mod_b mod_b_inst1 (.x(x), .y(y), .z(mod_b1_z));
mod_b mod_b_inst2 (.x(x), .y(y), .z(mod_b2_z));

// Logic to combine outputs of Module A and B
assign z = mod_a1_z | mod_b1_z;

endmodule

module mod_a (
    input logic x,
    input logic y,
    output logic z
);

assign z = (x ^ y) & x;

endmodule

module mod_b (
    input logic x,
    input logic y,
    output logic z
);

// Karnaugh Map implementation for the Boolean function z = (x'y + xy')
assign z = (x & ~y) | (~x & y);

endmodule