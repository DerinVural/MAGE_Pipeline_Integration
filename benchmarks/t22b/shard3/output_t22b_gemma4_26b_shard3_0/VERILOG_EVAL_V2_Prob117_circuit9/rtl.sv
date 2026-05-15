module TopModule (
    input  logic clk,
    input  logic a,
    output logic [2:0] q
);

    logic [2:0] q_reg;

    initial begin
        q_reg = 3'b100;
    end

    always @(posedge clk) begin
        if (a == 1'b1) begin
            q_reg <= 3'b100;
        end else begin
            if (q_reg == 3'b110) begin
                q_reg <= 3'b000;
            end else begin
                q_reg <= q_reg + 3'b001;
            end
        end
    end

    assign q = q_reg;

endmodule