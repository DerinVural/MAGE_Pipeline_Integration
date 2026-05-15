module TopModule (
    input  logic d,
    input  logic ena,
    output logic q
);

    // Initialize q to avoid unknown state at start of simulation
    initial begin
        q = 1'b0;
    end

    // D Latch implementation
    // When ena is high, q follows d. 
    // When ena is low, q retains its previous value.
    always_latch begin
        if (ena) begin
            q <= d;
        end
    end

endmodule