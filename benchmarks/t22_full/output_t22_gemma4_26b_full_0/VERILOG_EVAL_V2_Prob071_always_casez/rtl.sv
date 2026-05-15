module TopModule(
    input  logic [7:0] in,
    output logic [2:0] pos
);

    // Combinational logic for priority encoder
    always @(*) begin
        // Default value if no bits are set
        pos = 3'd0;
        
        // Loop from 0 to 7 to find the least significant bit set to 1.
        // Since we want the first (LSB) bit, and a loop executes sequentially,
        // we can loop from 7 down to 0, so that the smallest index is the last one assigned.
        // Alternatively, loop from 0 up to 7 and assign 'pos' whenever in[i] is 1.
        // The last assignment in the loop will be the highest index. 
        // Wait, to get the LSB, if we loop 0 to 7, the HIGHEST index will overwrite. 
        // Let's loop from 7 down to 0. If in[7] is 1, pos = 7. If in[0] is 1, pos = 0.
        // The final value of pos will be the smallest index that was 1.
        for (int i = 7; i >= 0; i--) begin
            if (in[i]) begin
                pos = i[2:0];
            end
        end
    end

endmodule