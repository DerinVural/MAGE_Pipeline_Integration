module TopModule(
    input  logic [6:1] y,
    input  logic w,
    output logic Y2,
    output logic Y4
);

    // The state mapping based on one-hot and testbench y[6:1]:
    // y[1] = State A
    // y[2] = State B
    // y[3] = State C
    // y[4] = State D
    // y[5] = State E
    // y[6] = State F

    // Next state B (Y2) is reached from A when w=0
    // A (y[1]) --0--> B (y[2])
    assign Y2 = y[1] & ~w;

    // Next state D (Y4) is reached from:
    // B (y[2]) --1--> D (y[4])
    // C (y[3]) --1--> D (y[4])
    // E (y[5]) --1--> D (y[4])
    // F (y[6]) --1--> D (y[4])
    assign Y4 = (y[2] & w) | (y[3] & w) | (y[5] & w) | (y[6] & w);

endmodule