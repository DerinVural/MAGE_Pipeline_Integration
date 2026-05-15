module TopModule (
    input logic ring,
    input logic vibrate_mode,
    output logic ringer,
    output logic motor
);

    assign ringer = (!vibrate_mode) && ring;
    assign motor = vibrate_mode;

endmodule