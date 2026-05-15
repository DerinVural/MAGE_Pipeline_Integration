module TopModule (
    input  logic ring,
    input  logic vibrate_mode,
    output logic ringer,
    output logic motor
);

    // Combinational logic to determine ringer and motor state
    // Ringer is active only if there is a ring and vibrate_mode is NOT active.
    assign ringer = ring && !vibrate_mode;

    // Motor is active only if there is a ring and vibrate_mode IS active.
    assign motor = ring && vibrate_mode;

endmodule