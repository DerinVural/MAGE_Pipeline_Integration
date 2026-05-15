module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam logic [1:0] STATE_A = 2'b00;
    localparam logic [1:0] STATE_B = 2'b01;

    // State registers
    logic [1:0] state;
    logic [1:0] next_state;

    // Initialize state to prevent X in simulation
    initial begin
        state = STATE_B;
    end

    // Sequential logic with asynchronous reset
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_B;
        end else begin
            state <= next_state;
        end
    end

    // Combinational logic for next state
    always @(*) begin
        next_state = state;
        case (state)
            STATE_B: begin
                if (in == 1'b0) begin
                    next_state = STATE_A;
                end else begin
                    next_state = STATE_B;
                end
            end
            STATE_A: begin
                if (in == 1'b0) begin
                    next_state = STATE_B;
                end else begin
                    next_state = STATE_A;
                end
            end
            default: begin
                next_state = STATE_B;
            end
        endcase
    end

    // Combinational logic for Moore output
    always @(*) begin
        if (state == STATE_B) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule