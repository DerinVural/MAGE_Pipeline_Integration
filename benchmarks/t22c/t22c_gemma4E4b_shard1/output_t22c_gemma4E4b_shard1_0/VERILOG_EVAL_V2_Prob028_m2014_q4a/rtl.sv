module TopModule (
    input logic d,
    input logic ena,
    output logic q
);

    // q must be declared as logic type because it is assigned within an always block
    logic q_reg;

    // Initialize q_reg to a known value (e.g., 0) to avoid X propagation
    initial begin
        q_reg = 1'b0;
    end

    // D Latch implementation using combinational assignment logic
    always @(*)
    begin
        if (ena) begin
            // Transparent mode: q follows d
            q_reg = d;
        end else begin
            // Hold mode: q retains its current value
            // Since q_reg holds the value from the previous evaluation cycle
            // (or the last time ena was high), we explicitly hold it.
            // In an always @(*) block, the value from the previous simulation step
            // is retained unless explicitly overwritten. To enforce the hold,
            // we assign q_reg = q_reg when ena is low.
            q_reg = q_reg;
        end
    end

    // Drive the output port
    assign q = q_reg;

endmodule