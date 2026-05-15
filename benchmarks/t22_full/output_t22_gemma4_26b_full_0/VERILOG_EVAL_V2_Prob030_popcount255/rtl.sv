module TopModule(
    input  logic [254:0] in,
    output logic [7:0]   out
);

    // Combinational logic to count the number of '1's
    always @(*) begin
        // Initialize count to 0 to avoid latch generation
        // Using a temporary variable for accumulation
        logic [7:0] count;
        count = 8'd0;
        
        for (int i = 0; i < 255; i++) begin
            if (in[i]) begin
                count = count + 8'd1;
            end
        end
        
        out = count;
    end

endmodule