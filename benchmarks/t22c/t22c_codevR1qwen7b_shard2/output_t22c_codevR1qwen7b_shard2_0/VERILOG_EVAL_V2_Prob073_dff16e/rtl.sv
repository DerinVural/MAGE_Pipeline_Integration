module TopModule (input logic clk, input logic resetn, input logic [1:0] byteena, input logic [15:0] d, output logic [15:0] q);

    // Upper byte: bits [15:8]
    logic [7:0] q_upper_reg;
    logic [7:0] q_lower_reg;

    // Upper byte write enable: byteena[1]
    always @(posedge clk) begin
        if (!resetn) begin
            q_upper_reg <= 8'h0;
        end else begin
            if (byteena[1]) begin
                q_upper_reg <= d[15:8];
            end
        end
    end

    // Lower byte write enable: byteena[0]
    always @(posedge clk) begin
        if (!resetn) begin
            q_lower_reg <= 8'h0;
        end else begin
            if (byteena[0]) begin
                q_lower_reg <= d[7:0];
            end
        end
    end

    // Assign outputs after reset initialization
    assign q = {q_upper_reg, q_lower_reg};

endmodule;