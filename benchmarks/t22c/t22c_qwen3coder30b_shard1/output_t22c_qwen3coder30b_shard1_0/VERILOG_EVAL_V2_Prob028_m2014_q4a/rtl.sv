module TopModule (
    input logic d,
    input logic ena,
    output logic q
);

    // Initialize q to 0 to avoid undefined values
    initial begin
        q = 0;
    end

    // Always block to implement D latch behavior
    always @(*) begin
        if (ena)
            q = d;
        // If ena is low, q retains its previous value
    end

endmodule