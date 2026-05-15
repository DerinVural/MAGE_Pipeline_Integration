module TopModule(
    input  logic [2:0] a,
    output logic [15:0] q
);

    // Combinational LUT implementation based on waveform analysis
    always @(*) begin
        case (a)
            3'd0: q = 16'h04D0;
            3'd1: q = 16'hAEE0;
            3'd2: q = 16'h27D4;
            3'd3: q = 16'h5A0E;
            3'd4: q = 16'h2066;
            3'd5: q = 16'h64CE;
            3'd6: q = 16'hC526;
            3'd7: q = 16'h2F19;
            default: q = 16'h0000;
        endcase
    end

endmodule