module TopModule (
    input  logic [2:0] in,
    output logic [1:0] out
);

    // Implementation of Population Count (counting set bits in 'in')
    always @(*)
    begin
        // Default value to handle any unlisted or undefined states (though with 3-bit input, all are covered)
        out = 2'b00;

        case (in)
            3'b000: out = 2'b00; // Count 0
            3'b001, 3'b010, 3'b100: out = 2'b01; // Count 1
            3'b011, 3'b101, 3'b110: out = 2'b10; // Count 2
            3'b111: out = 2'b11; // Count 3
            default: out = 2'b00; // Safety net
        endcase
    end

endmodule