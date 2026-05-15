module TopModule(
    input  logic ring,
    input  logic vibrate_mode,
    output logic ringer,
    output logic motor
);

    // Combinational logic for cellphone controller
    // If ring is 1, we either turn on the motor or the ringer.
    // If vibrate_mode is 1, motor = 1 and ringer = 0.
    // If vibrate_mode is 0, motor = 0 and ringer = 1.
    // If ring is 0, both are 0.

    always @(*) begin
        if (ring) begin
            if (vibrate_mode) begin
                motor = 1'b1;
                ringer = 1'b0;
            end else begin
                motor = 1'b0;
                ringer = 1'b1;
            end
        end else begin
            motor = 1'b0;
            ringer = 1'b0;
        end
    end

endmodule