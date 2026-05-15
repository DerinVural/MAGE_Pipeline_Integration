module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic j,
    input  logic k,
    output logic out
);

    // State definitions
    localparam STATE_OFF = 1'b0;
    localparam STATE_ON  = 1'b1;

    // State register
    logic state;
    logic state_next;

    // Sequential logic for state transition
    // Asynchronous active-high reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_OFF;
        end else begin
            state <= state_next;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        state_next = state;
        case (state) 
            STATE_OFF: begin
                if (j == 1'b1) begin
                    state_next = STATE_ON;
                end else begin
                    state_next = STATE_OFF;
                end
            end
            STATE_ON: begin
                if (k == 1'b1) begin
                    state_next = STATE_OFF;
                end else begin
                    state_next = STATE_ON;
                end
            end
            default: state_next = STATE_OFF;
        endcase
    end

    // Combinational logic for Moore output
    always @(*) begin
        case (state) 
            STATE_OFF: out = 1'b0;
            STATE_ON:  out = 1'b1;
            default:   out = 1'b0;
        endcase
    end

endmodule