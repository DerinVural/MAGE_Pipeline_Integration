module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic start_shifting
);

    // State definitions
    localparam STATE_IDLE  = 3'b000;
    localparam STATE_S1    = 3'b001;
    localparam STATE_S11   = 3'b010;
    localparam STATE_S110  = 3'b011;
    localparam STATE_FOUND = 3'b100;

    // State register
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Initialize state to avoid X
    initial begin
        current_state = STATE_IDLE;
    end

    // Sequential logic: State transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            STATE_IDLE:
                if (data == 1'b1) 
                    next_state = STATE_S1;
                else 
                    next_state = STATE_IDLE;

            STATE_S1:
                if (data == 1'b1) 
                    next_state = STATE_S11;
                else 
                    next_state = STATE_IDLE;

            STATE_S11:
                if (data == 1'b0) 
                    next_state = STATE_S110;
                else 
                    next_state = STATE_S11;

            STATE_S110:
                if (data == 1'b1) 
                    next_state = STATE_FOUND;
                else 
                    next_state = STATE_IDLE;

            STATE_FOUND:
                next_state = STATE_FOUND;

            default:
                next_state = STATE_IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        if (current_state == STATE_FOUND) begin
            start_shifting = 1'b1;
        end else begin
            start_shifting = 1'b0;
        end
    end

endmodule