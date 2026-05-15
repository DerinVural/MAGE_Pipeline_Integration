module A (
    input  logic x,
    input  logic y,
    output logic z
);

    assign z = (x ^ y) & x;

endmodule


module B (
    input  logic x,
    input  logic y,
    output logic z
);

    // Based on waveform:
    // When x=0 and y=0, z=1
    // When x=1 and y=0, z=0
    // When x=0 and y=1, z=0
    // When x=1 and y=1, z=1
    assign z = (x == 0 && y == 0) ? 1 : 
              (x == 1 && y == 0) ? 0 : 
              (x == 0 && y == 1) ? 0 : 
              1;

endmodule


module TopModule (
    input  logic x,
    input  logic y,
    output logic z
);

    // Internal wires
    wire z_a1, z_b1, z_a2, z_b2;
    wire or_out, and_out;

    // First A submodule
    A a1 (.x(x), .y(y), .z(z_a1));
    // First B submodule
    B b1 (.x(x), .y(y), .z(z_b1));
    // Second A submodule
    A a2 (.x(x), .y(y), .z(z_a2));
    // Second B submodule
    B b2 (.x(x), .y(y), .z(z_b2));

    // OR gate
    assign or_out = z_a1 | z_b1;
    // AND gate
    assign and_out = z_a2 & z_b2;
    // Final XOR
    assign z = or_out ^ and_out;

endmodule