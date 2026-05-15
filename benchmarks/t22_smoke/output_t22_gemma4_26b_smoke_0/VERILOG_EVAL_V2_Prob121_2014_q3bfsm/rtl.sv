module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    // State encoding
    localparam STATE_000 = 3'b000;
    localparam STATE_001 = 3'b001;
    localparam STATE_010 = 3'b010;
    localparam STATE_011 = 3'b011;
    localparam STATE_100 = 3'b100;

    // State registers
    logic [2:0] state;
    logic [2:0] next_state;

    // Sequential logic
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_000;
        end else begin
            state <= next_state;
        end
    end

    // Next state combinational logic
    always @(*) begin
        next_state = state; // Default hold state
        case (state)
            STATE_000:
                if (x == 1'b0) next_state = STATE_000;
                else           next_state = STATE_001;
            STATE_001:
                if (x == 1'b0) next_state = STATE_001;
                else           next_state = STATE_100;
            STATE_010:
                if (x == 1'b0) next_state = STATE_010;
                else           next_state = STATE_001;
            STATE_011:
                if (x == 1'b0) next_state = STATE_001;
                else           next_state = STATE_010;
            STATE_100:
                if (x == 1'b0) next_state = STATE_011;
                else           next_state = STATE_100;
            default:
                next_state = STATE_000;
        endcase
    end

    // Output combinational logic
    always @(*) begin
        case (state)
            STATE_011: z = 1'b1;
            STATE_100: z = 1'b1;
            default:   z = 1'b0;
        endcase
    end

endmodule