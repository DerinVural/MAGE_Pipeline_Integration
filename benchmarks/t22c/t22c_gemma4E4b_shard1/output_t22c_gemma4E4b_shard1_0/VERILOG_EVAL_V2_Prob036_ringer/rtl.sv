module TopModule (
    input  logic ring,
    input  logic vibrate_mode,
    output logic ringer,
    output logic motor
);

    // Logic implementation:
    // If ring is active (1):
    //   If vibrate_mode is 1, motor=1, ringer=0.
    //   If vibrate_mode is 0, ringer=1, motor=0.
    // If ring is inactive (0), both outputs must be 0 (implicitly handled by AND gates).

    // Ringer is active only when ring is high AND vibrate_mode is low.
    assign ringer = ring & ~vibrate_mode;

    // Motor is active only when ring is high AND vibrate_mode is high.
    assign motor = ring & vibrate_mode;

endmodule