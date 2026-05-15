module TopModule (
    input  logic mode,
    input  logic too_cold,
    input  logic too_hot,
    input  logic fan_on,
    output logic heater,
    output logic aircon,
    output logic fan
);

    // Combinational logic for heater
    // In heating mode (mode=1), turn heater on when too_cold=1
    // In cooling mode (mode=0), heater is always off
    assign heater = mode && too_cold;

    // Combinational logic for aircon
    // In cooling mode (mode=0), turn aircon on when too_hot=1
    // In heating mode (mode=1), aircon is always off
    assign aircon = (!mode) && too_hot;

    // Combinational logic for fan
    // Turn on fan if heater is on, aircon is on, or user requests it via fan_on
    assign fan = heater || aircon || fan_on;

endmodule