module TopModule (
    input  logic [254:0] in,
    output logic [7:0]   out
);

    // Combinational population count
    always @(*) begin
        // Local variable to accumulate the count
        // We use an integer for easier arithmetic within the loop
        integer count;
        count = 0;
        
        for (int i = 0; i < 255; i++) begin
            if (in[i]) begin
                count = count + 1;
            end
        end
        
        // Assign the lower 8 bits to the output
        out = count[7:0];
    end

endmodule