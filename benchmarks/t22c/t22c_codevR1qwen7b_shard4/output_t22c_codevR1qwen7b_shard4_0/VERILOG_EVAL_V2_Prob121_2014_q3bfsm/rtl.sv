module TopModule(input logic clk, input logic reset, input logic x, output logic z);
    logic [2:0] y, y_next;

    // State assignments
    localparam STATE_000 = 3'b000;
    localparam STATE_001 = 3'b001;
    localparam STATE_010 = 3'b010;
    localparam STATE_011 = 3'b011;
    localparam STATE_100 = 3'b100;

    // Sequential block
    always_ff @(posedge clk) begin
        if (reset)
            y <= STATE_000;
        else
            y <= y_next;
    end

    // Combinational next state and output logic
    always_comb begin
        case (y)
            STATE_000: begin
                y_next = x ? STATE_001 : STATE_000;
                z = 0;
            end
            STATE_001: begin
                y_next = x ? STATE_100 : STATE_001;
                z = 0;
            end
            STATE_010: begin
                y_next = x ? STATE_001 : STATE_010;
                z = 0;
            end
            STATE_011: begin
                y_next = x ? STATE_010 : STATE_001;
                z = 1;
            end
            STATE_100: begin
                y_next = x ? STATE_100 : STATE_011;
                z = 1;
            end
            default: begin
                y_next = STATE_000;
                z = 0;
            end
        endcase
    end

endmodule