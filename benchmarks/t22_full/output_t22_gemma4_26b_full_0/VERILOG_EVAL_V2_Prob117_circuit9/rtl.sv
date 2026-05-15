module TopModule(
    input  logic clk,
    input  logic a,
    output logic [2:0] q
);

    // The waveform indicates that when a is 1, q is forced to 4.
    // When a is 0, q increments on the clock edge and wraps from 6 to 0 (modulo 7).
    
    // Initialize q to 4 to match the first valid state seen in the waveform.
    initial begin
        q = 3'd4;
    end

    always @(posedge clk) begin
        if (a) begin
            q <= 3'd4;
        end else begin
            // Modulo 7 counter: 0, 1, 2, 3, 4, 5, 6, then back to 0
            if (q >= 3'd6) begin
                q <= 3'd0;
            end else begin
                q <= q + 3'd1;
            end
        end
    end

endmodule