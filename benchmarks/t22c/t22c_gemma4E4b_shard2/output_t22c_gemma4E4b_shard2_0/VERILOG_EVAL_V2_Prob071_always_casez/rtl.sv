module TopModule (
    input logic [7:0] in,
    output logic [2:0] pos
);

    // Implementation using an always block for combinational logic
    always @* begin
        // Default case: If no bits are high, pos should be 0
        pos = 3'b000;

        // Check priority from LSB (index 0) upwards
        if (in[0]) begin
            pos = 3'b000; // Index 0
        end else if (in[1]) begin
            pos = 3'b001; // Index 1
        end else if (in[2]) begin
            pos = 3'b010; // Index 2
        end else if (in[3]) begin
            pos = 3'b011; // Index 3
        end else if (in[4]) begin
            pos = 3'b100; // Index 4
        end else if (in[5]) begin
            pos = 3'b101; // Index 5
        end else if (in[6]) begin
            pos = 3'b110; // Index 6
        end else if (in[7]) begin
            pos = 3'b111; // Index 7
        end
    end

endmodule