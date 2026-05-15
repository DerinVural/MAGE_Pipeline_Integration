module TopModule(
    input  logic [3:0] x,
    output logic f
);

    // The K-map is implemented using a case statement.
    // We map the x[3:0] bits to the truth table derived from the K-map.
    // x[4] maps to x[3], x[3] maps to x[2], x[2] maps to x[1], x[1] maps to x[0].
    // Row is x[2]x[3], Col is x[0]x[1].

    always @(*) begin
        case (x)
            // Row 00 (x[2]=0, x[3]=0)
            4'b0000: f = 1'b0; // d
            4'b0001: f = 1'b0; // Col 10
            4'b0010: f = 1'b0; // Col 01
            4'b0011: f = 1'b0; // d
            
            // Row 01 (x[2]=0, x[3]=1)
            4'b0100: f = 1'b0; // Col 00
            4'b0101: f = 1'b0; // Col 10
            4'b0110: f = 1'b0; // d
            4'b0111: f = 1'b1; // Col 11
            
            // Row 11 (x[2]=1, x[3]=1)
            4'b1100: f = 1'b1; // Col 00
            4'b1101: f = 1'b1; // d
            4'b1110: f = 1'b1; // Col 01
            4'b1111: f = 1'b1; // d
            
            // Row 10 (x[2]=1, x[3]=0)
            4'b1000: f = 1'b1; // Col 00
            4'b1001: f = 1'b1; // d
            4'b1010: f = 1'b1; // Col 01
            4'b1011: f = 1'b0; // Col 11
            
            default: f = 1'b0;
        endcase
    end

endmodule