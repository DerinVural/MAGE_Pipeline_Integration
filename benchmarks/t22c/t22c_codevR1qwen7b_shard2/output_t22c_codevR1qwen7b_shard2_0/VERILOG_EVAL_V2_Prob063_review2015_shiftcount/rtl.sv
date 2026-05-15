module TopModule (clk, shift_ena, count_ena, data, q);
    input logic clk;
    input logic shift_ena;
    input logic count_ena;
    input logic data;
    output logic [3:0] q;

    logic [3:0] q_reg;
    logic shift_ena_reg;
    logic count_ena_reg;
    logic data_reg;

    // Initialize registers
    initial begin
        q_reg = 4'b0000;
        shift_ena_reg = 0;
        count_ena_reg = 0;
        data_reg = 0;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (shift_ena_reg) begin
            q_reg <= {data_reg, q_reg[3:1]};
        end else if (count_ena_reg) begin
            q_reg <= q_reg - 1;
        end
    end

    // Update registered inputs to avoid glitches
    always @(posedge clk) begin
        shift_ena_reg <= shift_ena;
        count_ena_reg <= count_ena;
        data_reg <= data;
    end

    // Assign output
    assign q = q_reg;

endmodule