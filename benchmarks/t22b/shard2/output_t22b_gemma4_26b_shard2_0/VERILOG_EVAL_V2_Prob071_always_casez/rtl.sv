module TopModule (
    input  logic [7:0] in,
    output logic [2:0] pos
);

    // Combinational logic for priority encoder
    // We want the LSB (lowest index) to have highest priority.
    // By iterating from MSB down to LSB, the assignment for the 
    // lowest index will overwrite previous assignments.
    always @(*) begin
        pos = 3'd0;
        for (int i = 7; i >= 0; i = i - 1) begin
            if (in[i]) begin
                pos = i[2:0];
            end
        end
    end

endmodule