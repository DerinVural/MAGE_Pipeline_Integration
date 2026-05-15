module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic j,
    input  logic k,
    output logic out
);

    // State encoding
    localparam STATE_OFF = 1'b0;
    localparam STATE_ON  = 1'b1;

    // State registers
    logic current_state;
    logic next_state;

    // Sequential logic: State transition
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_OFF;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic: Next state logic
    always @(*) begin
        next_state = current_state; // Default hold state
        case (current_state) 
            STATE_OFF: begin
                if (j == 1'b1) begin
                    next_state = STATE_ON;
                end else begin
                    next_state = STATE_OFF;
                end
            end
            STATE_ON: begin
                if (k == 1'b1) begin
                    next_state = STATE_OFF;
                end else begin
                    next_state = STATE_ON;
                end
            end
            default: begin
                next_state = STATE_OFF;
            end
        endcase
    end

    // Combinational logic: Output logic (Moore machine)
    always @(*) begin
        case (current_state) 
            STATE_OFF: out = 1'b0;
            STATE_ON:  out = 1'b1;
            default:   out = 1'b0;
        endcase
    end

endmodule