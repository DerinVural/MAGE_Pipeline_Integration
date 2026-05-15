module TopModule (
    input clk,
    input resetn,
    input x,
    input y,
    output f,
    output g
);

    // Define states
    localparam STATE_A = 3'd0;
    localparam STATE_B = 3'd1;
    localparam STATE_C = 3'd2;
    localparam STATE_D = 3'd3;
    localparam STATE_E = 3'd4;
    localparam STATE_F = 3'd5;

    // State register
    logic [2:0] state;
    logic [2:0] state_next;

    // Internal signals for outputs
    logic f_int;
    logic g_int;

    // Initialize state register
    initial begin
        state = STATE_A;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (!resetn)
            state <= STATE_A;
        else
            state <= state_next;
    end

    // Next state logic
    always @(*) begin
        case (state)
            STATE_A: begin
                if (resetn)
                    state_next = STATE_B;
                else
                    state_next = STATE_A;
            end
            STATE_B: begin
                state_next = STATE_C;
            end
            STATE_C: begin
                if (x == 1'b1)
                    state_next = STATE_D;
                else
                    state_next = STATE_A;
            end
            STATE_D: begin
                if (x == 1'b0)
                    state_next = STATE_E;
                else
                    state_next = STATE_A;
            end
            STATE_E: begin
                if (x == 1'b1)
                    state_next = STATE_F;
                else
                    state_next = STATE_A;
            end
            STATE_F: begin
                if (y == 1'b1)
                    state_next = STATE_F;
                else
                    state_next = STATE_E;
            end
            default: state_next = STATE_A;
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            STATE_A:
                begin
                    f_int = 1'b0;
                    g_int = 1'b0;
                end
            STATE_B:
                begin
                    f_int = 1'b1;
                    g_int = 1'b0;
                end
            STATE_C:
                begin
                    f_int = 1'b0;
                    g_int = 1'b0;
                end
            STATE_D:
                begin
                    f_int = 1'b0;
                    g_int = 1'b0;
                end
            STATE_E:
                begin
                    f_int = 1'b0;
                    g_int = 1'b1;
                end
            STATE_F:
                begin
                    f_int = 1'b0;
                    g_int = 1'b1;
                end
            default:
                begin
                    f_int = 1'b0;
                    g_int = 1'b0;
                end
        endcase
    end

    // Assign outputs
    assign f = f_int;
    assign g = g_int;

endmodule