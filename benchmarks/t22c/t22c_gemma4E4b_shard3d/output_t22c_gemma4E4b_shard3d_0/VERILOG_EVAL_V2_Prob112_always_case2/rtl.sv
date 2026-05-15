module TopModule(
    input  logic [3:0] in,
    output logic [1:0] pos
);

    // Combinational logic implementation using an always block
    always @* begin
        // Default assignment: If no input is high, output zero as per requirement.
        pos = 2'b00;

        // Priority check: Check from MSB (highest priority) down to LSB (lowest priority)
        if (in[3]) begin
            pos = 2'b11; // Corresponds to index 3
        end else if (in[2]) begin
            pos = 2'b10; // Corresponds to index 2
        end else if (in[1]) begin
            pos = 2'b01; // Corresponds to index 1
        end else if (in[0]) begin
            pos = 2'b00; // Corresponds to index 0
        end
        // The 'else' case is implicitly handled by the default assignment above (pos = 2'b00)
    end

endmodule