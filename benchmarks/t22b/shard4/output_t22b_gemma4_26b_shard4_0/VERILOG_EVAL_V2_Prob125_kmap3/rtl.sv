module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    always @(*) begin
        case ({a, b, c, d})
            // cd = 00
            4'b01_00: out = 1'b1; // Don't care (d)
            4'b00_00: out = 1'b0;
            4'b10_00: out = 1'b1;
            4'b11_00: out = 1'b1;

            // cd = 01
            4'b01_01: out = 1'b0;
            4'b00_01: out = 1'b0;
            4'b10_01: out = 1'b1; // Don't care (d)
            4'b11_01: out = 1'b1; // Don't care (d)

            // cd = 11
            4'b01_11: out = 1'b0;
            4'b00_11: out = 1'b1;
            4'b10_11: out = 1'b1;
            4'b11_11: out = 1'b1;

            // cd = 10
            4'b01_10: out = 1'b0;
            4'b00_10: out = 1'b1;
            4'b10_10: out = 1'b1;
            4'b11_10: out = 1'b1;

            default:   out = 1'b1;
        endcase
    end

endmodule