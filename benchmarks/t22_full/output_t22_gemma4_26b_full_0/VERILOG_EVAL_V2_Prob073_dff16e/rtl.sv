module TopModule(
    input  logic       clk,
    input  logic       resetn,
    input  logic [1:0] byteena,
    input  logic [15:0] d,
    output logic [15:0] q
);

    // Sequential logic for the 16-bit register with byte enables
    always @(posedge clk) begin
        if (!resetn) begin
            // Synchronous active-low reset
            q <= 16'h0000;
        end else begin
            // Byte-enable logic
            // byteena[0] controls the lower byte d[7:0]
            if (byteena[0]) begin
                q[7:0] <= d[7:0];
            end
            
            // byteena[1] controls the upper byte d[15:8]
            if (byteena[1]) begin
                q[15:8] <= d[15:8];
            end
        end
    end

endmodule