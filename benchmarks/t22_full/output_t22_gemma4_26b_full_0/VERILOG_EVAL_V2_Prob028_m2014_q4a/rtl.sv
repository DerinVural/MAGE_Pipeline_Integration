module TopModule(
    input  logic d,
    input  logic ena,
    output logic q
);

    // Initialize q to a known value to avoid X in simulation
    initial begin
        q = 1'b0;
    end

    // D latch implementation
    // When ena is high, q follows d. 
    // When ena is low, q holds its previous value.
    always @(*) begin
        if (ena) begin
            q = d;
        end
    end

endmodule