module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic x,
    output logic z
);

    // One-hot encoding for two states: A and B
    // State A: 2'b01
    // State B: 2'b10
    localparam STATE_A = 2'b01;
    localparam STATE_B = 2'b10;

    logic [1:0] state;
    logic [1:0] next_state;

    // Sequential logic with asynchronous active-high reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_A;
        end else begin
            state <= next_state;
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            STATE_A: begin
                if (x) begin
                    next_state = STATE_B;
                end else begin
                    next_state = STATE_A;
                end
            end
            STATE_B: begin
                // B --x=0--> B, B --x=1--> B
                next_state = STATE_B;
            end
            default: begin
                next_state = STATE_A;
            end
        endcase
    end

    // Mealy output logic (depends on state and input x)
    always @(*) begin
        z = 1'b0;
        case (state)
            STATE_A: begin
                if (x) z = 1'b1;
                else    z = 1'b0;
            end
            STATE_B: begin
                if (x) z = 1'b0;
                else    z = 1'b1;
            end
            default: z = 1'b0;
        endcase
    end

endmodule