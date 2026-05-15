module TopModule(
    input  logic [2:0] y,
    input  logic w,
    output logic Y1
);

    // The module implements the next-state logic for y[1].
    // Based on the state transitions and the state codes:
    // A: 000, B: 001, C: 010, D: 011, E: 100, F: 101
    
    always @(*) begin
        Y1 = 1'b0; // Default value
        case ({y, w})
            // State A (000)
            3'b000, 4'b0000: Y1 = 1'b0; // A --0--> B (001), y[1]=0
            3'b000, 4'b0001: Y1 = 1'b0; // A --1--> A (000), y[1]=0
            
            // State B (001)
            3'b001, 4'b0010: Y1 = 1'b1; // B --0--> C (010), y[1]=1
            3'b001, 4'b0011: Y1 = 1'b1; // B --1--> D (011), y[1]=1
            
            // State C (010)
            3'b010, 4'b0100: Y1 = 1'b0; // C --0--> E (100), y[1]=0
            3'b010, 4'b0101: Y1 = 1'b1; // C --1--> D (011), y[1]=1
            
            // State D (011)
            3'b011, 4'b0110: Y1 = 1'b0; // D --0--> F (101), y[1]=0
            3'b011, 4'b0111: Y1 = 1'b0; // D --1--> A (000), y[1]=0
            
            // State E (100)
            3'b100, 4'b1000: Y1 = 1'b0; // E --0--> E (100), y[1]=0
            3'b100, 4'b1001: Y1 = 1'b1; // E --1--> D (011), y[1]=1
            
            // State F (101)
            3'b101, 4'b1010: Y1 = 1'b1; // F --0--> C (010), y[1]=1
            3'b101, 4'b1011: Y1 = 1'b1; // F --1--> D (011), y[1]=1
            
            default: Y1 = 1'b0;
        endcase
    end

endmodule