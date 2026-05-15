module TopModule (
    input [3:0] x,
    output logic f
);

    always @(*) begin
        // Using the Karnaugh map to derive the expression
        // f = x[3]'x[2]'x[0] + x[3]'x[2]x[1]' + x[3]x[2]'x[1]'x[0]' + x[3]x[2]'x[1]x[0] + x[3]x[2]x[1]'x[0]' + x[3]x[2]x[1]x[0]' + x[3]x[2]x[1]x[0]
        // Simplifying using K-map groupings:
        // Group 1: x[3]'x[2]'x[0] + x[3]x[2]'x[1]'x[0]' 
        // Group 2: x[3]'x[2]x[1]' + x[3]x[2]'x[1]x[0]
        // Group 3: x[3]x[2]x[1]'x[0]' + x[3]x[2]x[1]x[0] + x[3]x[2]x[1]x[0] 
        // Final simplified expression:
        f = (x[3] & ~x[2] & x[0]) |
            (~x[3] & x[2] & ~x[1]) |
            (x[3] & x[2] & ~x[1] & ~x[0]) |
            (x[3] & x[2] & x[1] & ~x[0]) |
            (x[3] & x[2] & x[1] & x[0]);
    end

endmodule