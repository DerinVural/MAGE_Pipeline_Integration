module TopModule (
    input  logic clk,
    input  logic aresetn,
    input  logic x,
    output logic z
);

    // State enum
    localparam STATE_IDLE = 2'b00;
    localparam STATE_ONE =  2'b01;
    localparam STATE_TWO =  2'b10;
    localparam STATE_THREE = 2'b11;

    // State register
    logic [1:0] state;

    // Initialize state to IDLE
    initial state = STATE_IDLE;

    // Next state logic
    always @(*) begin
        case (state)
        STATE_IDLE:
            if (x)
                state = STATE_ONE;
            else
                state = STATE_IDLE;
        STATE_ONE:
            if (x)
                state = STATE_TWO;
            else
                state = STATE_ONE;
        STATE_TWO:
            if (x)
                state = STATE_THREE;
            else
                state = STATE_IDLE;
        STATE_THREE:
            if (x)
                state = STATE_IDLE;
            else
                state = STATE_ONE;
        default:
            state = STATE_IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        z = 1'b0;
        if (state == STATE_THREE)
            z = 1'b1;
    end

    // Reset logic
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            state <= STATE_IDLE;
        end
    end

endmodule