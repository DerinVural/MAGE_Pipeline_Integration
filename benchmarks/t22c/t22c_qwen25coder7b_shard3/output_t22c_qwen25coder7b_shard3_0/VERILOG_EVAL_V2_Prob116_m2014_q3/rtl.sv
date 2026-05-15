module TopModule (
    logic [3:0] x,
    logic f
);

    // Combinational logic based on Karnaugh map
    always @(*) begin
        f = (x == 4'b0100 ||
            x == 4'b0010 ||
            x == 4'b1110 ||
            x == 4'b1010 ||
            x == 4'b1100); // From the Karnaugh map
    end

endmodule