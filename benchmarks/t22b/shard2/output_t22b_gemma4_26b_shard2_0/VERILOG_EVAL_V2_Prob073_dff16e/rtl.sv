module TopModule (
    input  logic        clk,
    input  logic        resetn,
    input  logic [1:0]  byteena,
    input  logic [15:0] d,
    output logic [15:0] q
);

    // Sequential logic for 16 D-flip-flops
    always @(posedge clk) begin
        if (!resetn) begin
            // Synchronous active-low reset
            q <= 16'h0;
        end else begin
            // Implement byte-level write enables
            // Upper byte: d[15:8]
            if (byteena[1]) begin
                q[15:8] <= d[15:8];
            end
            
            // Lower byte: d[7:0]
            if (byteena[0]) begin
                q[7:0] <= d[7:0];
            end
        end
    end

endmodule