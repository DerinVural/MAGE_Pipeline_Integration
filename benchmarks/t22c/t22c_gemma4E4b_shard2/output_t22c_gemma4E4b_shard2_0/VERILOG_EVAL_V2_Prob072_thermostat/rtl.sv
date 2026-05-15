module TopModule(
    input  logic mode,
    input  logic too_cold,
    input  logic too_hot,
    input  logic fan_on,
    output logic heater,
    output logic aircon,
    output logic fan
);

    // Logic for Heater:
    // Heater is on only in heating mode (mode=1) AND when too cold.
    assign heater = mode && too_cold;

    // Logic for Air Conditioner:
    // AC is on only in cooling mode (mode=0) AND when too hot.
    assign aircon = (~mode) && too_hot;

    // Logic for Fan:
    // Fan is on if Heater is on OR AC is on OR fan_on is requested.
    assign fan = heater || aircon || fan_on;

endmodule