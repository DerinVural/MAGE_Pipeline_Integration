module TopModule (
    input clk,
    input reset,
    input data,
    input done_counting,
    input ack,
    output reg shift_ena,
    output reg counting,
    output reg done
);

    // Define states
    localparam S_IDLE      = 3'd0;
    localparam S_DETECT    = 3'd1;
    localparam S_SHIFT     = 3'd2;
    localparam S_COUNTING  = 3'd3;
    localparam S_DONE      = 3'd4;

    // Current and next state variables
    logic [2:0] current_state;
    logic [2:0] next_state;

    // Shift register for pattern matching
    logic [3:0] shift_reg;

    // State register
    always @(posedge clk) begin
        if (reset)
            current_state <= S_IDLE;
        else
            current_state <= next_state;
    end

    // Next state logic
    always @(*) begin
        case (current_state)
            S_IDLE: begin
                if (shift_reg == 4'b1101)
                    next_state = S_DETECT;
                else
                    next_state = S_IDLE;
            end
            S_DETECT: begin
                next_state = S_SHIFT;
            end
            S_SHIFT: begin
                next_state = S_COUNTING;
            end
            S_COUNTING: begin
                if (done_counting)
                    next_state = S_DONE;
                else
                    next_state = S_COUNTING;
            end
            S_DONE: begin
                if (ack)
                    next_state = S_IDLE;
                else
                    next_state = S_DONE; // Stay in S_DONE until ack
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Output logic
    always @(*) begin
        case (current_state)
            S_IDLE: begin
                shift_ena = 1'b0;
                counting = 1'b0;
                done = 1'b0;
            end
            S_DETECT: begin
                shift_ena = 1'b0;
                counting = 1'b0;
                done = 1'b0;
            end
            S_SHIFT: begin
                shift_ena = 1'b1;
                counting = 1'b0;
                done = 1'b0;
            end
            S_COUNTING: begin
                shift_ena = 1'b0;
                counting = 1'b1;
                done = 1'b0;
            end
            S_DONE: begin
                shift_ena = 1'b0;
                counting = 1'b0;
                done = 1'b1;
            end
            default: begin
                shift_ena = 1'b0;
                counting = 1'b0;
                done = 1'b0;
            end
        endcase
    end

    // Shift register logic
    always @(posedge clk) begin
        if (reset) begin
            shift_reg <= 4'b0000;
        end else begin
            shift_reg <= {shift_reg[2:0], data};
        end
    end

endmodule