module TopModule (
    input  logic clk,
    input  logic enable,
    input  logic S,
    input  logic A,
    input  logic B,
    input  logic C,
    output logic Z
);

    // 8-bit Shift Register (Q[7] is LSB, Q[0] is MSB, as per specification: S feeds Q[0])
    // Note: The problem states Q[0] is the MSB that shifts in first. This means the register structure should be: 
    // {S, Q[7:1]} where S is the new MSB (Q[0]).
    logic [7:0] Q;

    // Sequential Logic for Shift Register
    always @(posedge clk)
    begin
        if (enable)
        begin
            // Shift operation: S shifts into Q[0], and Q[i] gets Q[i-1]
            // Q_next = {S, Q[7:1]}
            Q <= {S, Q[7:1]};
        end
        // If enable is low, Q holds its value (implicit in behavioral modeling without 'else' for registered data)
    end

    // Combinational Logic for Readout (8-to-1 Multiplexer based on A, B, C)
    // Address mapping: ABC=000 -> Q[0]; ABC=111 -> Q[7]
    always @(*)
    begin
        Z = 1'b0; // Default assignment
        case ({A, B, C})
            3'b000: Z = Q[0]; // Address 0 -> Q[0]
            3'b001: Z = Q[1]; // Address 1 -> Q[1]
            3'b010: Z = Q[2]; // Address 2 -> Q[2]
            3'b011: Z = Q[3]; // Address 3 -> Q[3]
            3'b100: Z = Q[4]; // Address 4 -> Q[4]
            3'b101: Z = Q[5]; // Address 5 -> Q[5]
            3'b110: Z = Q[6]; // Address 6 -> Q[6]
            3'b111: Z = Q[7]; // Address 7 -> Q[7]
            default: Z = 1'b0;
        endcase
    end

    // Initialization block to set Q to a known state (e.g., all zeros)
    initial begin
        Q = 8'b00000000;
    end

endmodule