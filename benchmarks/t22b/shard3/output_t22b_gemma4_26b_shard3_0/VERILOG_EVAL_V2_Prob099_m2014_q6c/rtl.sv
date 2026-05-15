module TopModule (
    input  logic [6:1] y,
    input  logic w,
    output logic Y2,
    output logic Y4
);

    // Combinational logic for next-state bits Y2 and Y4
    // Y2 is the signal representing the next state being B (y[2])
    // Y4 is the signal representing the next state being D (y[4])

    always @(*) begin
        // Y2: Next state is B (y[2])
        // From the transitions: A --0--> B
        // Since A is y[1], Y2 = y[1] & ~w
        Y2 = y[1] & (~w);

        // Y4: Next state is D (y[4])
        // From the transitions:
        // B --1--> D (y[2] & w)
        // C --1--> D (y[3] & w)
        // E --1--> D (y[5] & w)
        // F --1--> D (y[6] & w)
        Y4 = (y[2] | y[3] | y[5] | y[6]) & w;
    end

endmodule