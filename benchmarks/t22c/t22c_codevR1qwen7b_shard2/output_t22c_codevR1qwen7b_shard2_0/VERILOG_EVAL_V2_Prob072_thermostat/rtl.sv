module TopModule (
    logic mode,
    logic too_cold,
    logic too_hot,
    logic fan_on,
    output logic heater,
    output logic aircon,
    output logic fan
);

    // Combinational logic for heater
    assign heater = mode ? too_cold : 1'b0;

    // Combinational logic for aircon
    assign aircon = ~mode & too_hot;

    // Combinational logic for fan
    assign fan = heater | aircon | fan_on;

endmodule