module TopModule(
    input  logic mode,
    input  logic too_cold,
    input  logic too_hot,
    input  logic fan_on,
    output logic heater,
    output logic aircon,
    output logic fan
);

    // Heating mode: mode = 1
    // Cooling mode: mode = 0

    // Heater is on only in heating mode and when it is too cold
    assign heater = (mode == 1'b1) && (too_cold == 1'b1);

    // Aircon is on only in cooling mode and when it is too hot
    assign aircon = (mode == 1'b0) && (too_hot == 1'b1);

    // Fan is on if heater is on, or aircon is on, or user requests fan_on
    assign fan = heater || aircon || fan_on;

endmodule