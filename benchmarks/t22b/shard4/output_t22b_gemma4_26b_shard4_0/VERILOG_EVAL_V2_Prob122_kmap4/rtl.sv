module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    input  logic d,
    output logic out
);

    // Combinational logic implementation using a case statement
    // The K-map mapping is derived from the provided table:
    // ab \ cd | 00 | 01 | 11 | 10
    // --------------------------
    // 00      | 0  | 1  | 0  | 1 
    // 01      | 1  | 0  | 1  | 0 
    // 11      | 0  | 1  | 0  | 1 
    // 10      | 1  | 0  | 1  | 0 

    always @(*) begin
        case ({a, b, c, d})
            4'b00_00: out = 1'b0;
            4'b00_01: out = 1'b1;
            4'b00_11: out = 1'b0;
            4'b00_10: out = 1'b1;

            4'b01_00: out = 1'b1;
            4'b01_01: out = 1'b0;
            4'b01_11: out = 1'b1;
            4'b01_10: out = 1'b0;

            4'b11_00: out = 1'b0;
            4'b11_01: out = 1'b1;
            4'b11_11: out = 1'b0;
            4'b11_10: out = 1'b1;

            4'b10_00: out = 1'b1;
            4'b10_01: out = 1'b0;
            4'b10_11: out = 1'b1;
            4'b10_10: out = 1'b0;

            default:   out = 1'b0;
        endcase
    end

endmodule