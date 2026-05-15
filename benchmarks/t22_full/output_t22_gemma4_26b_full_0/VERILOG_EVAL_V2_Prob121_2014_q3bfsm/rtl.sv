module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    // State definitions
    localparam logic [2:0] STATE_000 = 3'b000;
    localparam logic [2:0] STATE_001 = 3'b001;
    localparam logic [2:0] STATE_010 = 3'b010;
    localparam logic [2:0] STATE_011 = 3'b011;
    localparam logic [2:0] STATE_100 = 3'b100;

    // State registers
    logic [2:0] state;
    logic [2:0] state_next;

    // Sequential logic: State transition
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_000;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        state_next = state; // Default hold state
        case (state)
            STATE_000:
                if (x == 1'b0) state_next = STATE_000;
                else           state_next = STATE_001;
            STATE_001:
                if (x == 1'b0) state_next = STATE_001;
                else           state_next = STATE_100;
            STATE_010:
                if (x == 1'b0) state_next = STATE_010;
                else           state_next = STATE_001;
            STATE_011:
                if (x == 1'b0) state_next = STATE_001;
                else           state_next = STATE_010;
            STATE_100:
                if (x == 1'b0) state_next = STATE_011;
                else           state_next = STATE_100;
            default:
                state_next = STATE_000;
        endcase
    end

    // Combinational logic: Output logic
    always @(*) begin
        if (state == STATE_011 || state == STATE_100) begin
            z = 1'b1;
        end else begin
            z = 1'b0;
        end
    end

endmodule