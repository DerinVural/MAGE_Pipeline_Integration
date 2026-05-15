module ModuleA (
    input  logic x,
    input  logic y,
    output logic z
);
    assign z = (x ^ y) & x;
endmodule

module ModuleB (
    input  logic x,
    input  logic y,
    output logic z
);
    assign z = ~(x ^ y);
endmodule

module TopModule (
    input  logic x,
    input  logic y,
    output logic z
);

    logic z_a1, z_b1, z_a2, z_b2;
    logic out_or, out_and;

    // Instantiate first pair
    ModuleA a1 (.x(x), .y(y), .z(z_a1));
    ModuleB b1 (.x(x), .y(y), .z(z_b1));

    // Instantiate second pair
    ModuleA a2 (.x(x), .y(y), .z(z_a2));
    ModuleB b2 (.x(x), .y(y), .z(z_b2));

    // Combinational logic for intermediate gates
    assign out_or  = z_a1 | z_b1;
    assign out_and = z_a2 & z_b2;

    // Final XOR gate
    assign z = out_or ^ out_and;

endmodule