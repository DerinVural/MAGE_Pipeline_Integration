module TopModule (
    input logic clk,
    input logic reset,
    input logic [31:0] in,
    output logic [31:0] out,
    output logic [511:0] wavedrom_title,
    output logic wavedrom_enable
);

    localparam DETECTED = 32'b1;
    localparam IDLE = 32'b0;

    logic [31:0] prev_in;
    logic [31:0] output_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_in <= 0;
            output_reg <= IDLE;
        end else begin
            prev_in <= in;
            if (prev_in && !in) begin
                output_reg <= DETECTED;
            end else begin
                output_reg <= IDLE;
            end
        end
    end

    assign out = output_reg;
    assign wavedrom_title = "Example";
    assign wavedrom_enable = 1'b1;

endmodule