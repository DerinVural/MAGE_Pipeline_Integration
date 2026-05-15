module TopModule (
    input  logic [3:0] x,
    output logic f
);

    // Combinational logic implementation based on the K-Map derived truth table.
    // The mapping is determined by treating x[3]x[2] as the row index and x[1]x[0] as the column index.
    always @* begin
        f = 1'b0;
        case (x) 
            // Row 00 (x[3]x[2]=00): 1, 0, 0, 1 (Cols 00, 01, 11, 10)
            4'b0000: f = 1'b1; // x[1]x[0] = 00
            4'b0001: f = 1'b0; // x[1]x[0] = 01
            4'b0011: f = 1'b0; // x[1]x[0] = 11
            4'b0010: f = 1'b1; // x[1]x[0] = 10

            // Row 01 (x[3]x[2]=01): 0, 0, 0, 0
            4'b0100: f = 1'b0;
            4'b0101: f = 1'b0;
            4'b0111: f = 1'b0;
            4'b0110: f = 1'b0;

            // Row 11 (x[3]x[2]=11): 1, 1, 1, 0 (Cols 00, 01, 11, 10)
            4'b1100: f = 1'b1; // x[1]x[0] = 00
            4'b1101: f = 1'b1; // x[1]x[0] = 01
            4'b1111: f = 1'b1; // x[1]x[0] = 11
            4'b1110: f = 1'b0; // x[1]x[0] = 10

            // Row 10 (x[3]x[2]=10): 1, 1, 0, 1 (Cols 00, 01, 11, 10)
            4'b1000: f = 1'b1; // x[1]x[0] = 00
            4'b1001: f = 1'b1; // x[1]x[0] = 01
            4'b1011: f = 1'b0; // x[1]x[0] = 11
            4'b1010: f = 1'b1; // x[1]x[0] = 10
            
            default: f = 1'b0;
        endcase
    end

endmodule