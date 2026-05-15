module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out_sop,
    output logic out_pos
);

    // Concatenate inputs to form a 4-bit vector where 'a' is MSB (a=MSB, d=LSB)
    logic [3:0] inputs = {a, b, c, d};

    // Combinational logic implementation using case statement
    always @* begin
        // Default assignments: Assume 0 for SOP and 1 for POS if not explicitly defined
        out_sop = 1'b0;
        out_pos = 1'b1;

        case (inputs)
            // Required 1s for out_sop (Minterms: 2, 7, 15)
            4'd2: begin
                out_sop = 1'b1;
            end
            4'd7: begin
                out_sop = 1'b1;
            end
            4'd15: begin
                out_sop = 1'b1;
            end

            // Required 0s for out_pos (Maxterms: 0, 1, 4, 5, 6, 9, 10, 13, 14)
            4'd0: begin
                out_pos = 1'b0;
            end
            4'd1: begin
                out_pos = 1'b0;
            end
            4'd4: begin
                out_pos = 1'b0;
            end
            4'd5: begin
                out_pos = 1'b0;
            end
            4'd6: begin
                out_pos = 1'b0;
            end
            4'd9: begin
                out_pos = 1'b0;
            end
            4'd10: begin
                out_pos = 1'b0;
            end
            4'd13: begin
                out_pos = 1'b0;
            end
            4'd14: begin
                out_pos = 1'b0;
            end

            // Don't Cares (3, 8, 11, 12). Values chosen to minimize the resulting expression.
            // For DC 3 (0011): SOP=0, POS=1 (No change from default)
            4'd3: begin
                out_sop = 1'b0;
                out_pos = 1'b1;
            end
            // For DC 8 (1000): SOP=0, POS=1 (No change from default)
            4'd8: begin
                out_sop = 1'b0;
                out_pos = 1'b1;
            end
            // For DC 11 (1011): Choosing SOP=1, POS=0 to help cover minterms
            4'd11: begin
                out_sop = 1'b1;
                out_pos = 1'b0;
            end
            // For DC 12 (1100): SOP=0, POS=1 (No change from default)
            4'd12: begin
                out_sop = 1'b0;
                out_pos = 1'b1;
            end

            default: begin
                // Should not happen
                out_sop = 1'b0;
                out_pos = 1'b1;
            end
        endcase
    end

endmodule