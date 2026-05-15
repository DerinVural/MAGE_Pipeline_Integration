module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic x,
    output logic z
);

    // State variables using One-Hot Encoding
    logic sa;
    logic sb;

    // Initialize state variables to a known value (State A: sa=1, sb=0) before reset takes effect
    initial begin
        sa = 1'b0;
        sb = 1'b0;
    end

    // State Registers (Sequential Logic - Asynchronous Reset)
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Reset to State A
            sa <= 1'b1;
            sb <= 1'b0;
        end else begin
            case ({sa, sb})
                2'b10: begin // Current State A
                    if (x == 1'b0) begin
                        // A --x=0 (z=0)--> A
                        sa <= 1'b1;
                        sb <= 1'b0;
                    end else begin
                        // A --x=1 (z=1)--> B
                        sa <= 1'b0;
                        sb <= 1'b1;
                    end
                end
                2'b01: begin // Current State B
                    if (x == 1'b0) begin
                        // B --x=0 (z=1)--> B
                        sa <= 1'b0;
                        sb <= 1'b1;
                    end else begin
                        // B --x=1 (z=0)--> B
                        sa <= 1'b0;
                        sb <= 1'b1;
                    end
                end
                default: begin
                    // Safety state fallback, should not be reached
                    sa <= 1'b1;
                    sb <= 1'b0;
                end
            endcase
        end
    end

    // Output Logic (Mealy Machine - Combinational Logic)
    logic z_out;
    always @(*)
    begin
        z_out = 1'b0; // Default value

        if (sa && !sb) begin // State A
            if (x == 1'b0) begin // A --x=0 (z=0)--> A
                z_out = 1'b0;
            end else begin // A --x=1 (z=1)--> B
                z_out = 1'b1;
            end
        end else if (!sa && sb) begin // State B
            if (x == 1'b0) begin // B --x=0 (z=1)--> B
                z_out = 1'b1;
            end else begin // B --x=1 (z=0)--> B
                z_out = 1'b0;
            end
        end
        // If neither state is active (shouldn't happen post-reset), z_out remains 0
    end

    assign z = z_out;

endmodule