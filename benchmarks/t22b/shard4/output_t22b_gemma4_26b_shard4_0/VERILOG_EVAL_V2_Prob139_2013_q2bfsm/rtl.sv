module TopModule (
    input  logic clk,
    input  logic resetn,
    input  logic x,
    input  logic y,
    output logic f,
    output logic g
);

    // State definitions
    localparam STATE_A         = 3'd0;
    localparam STATE_F_PULSE  = 3'd1;
    localparam STATE_MON_X    = 3'd2;
    localparam STATE_G_START  = 3'd3;
    localparam STATE_MON_Y    = 3'd4;
    localparam STATE_G_PERM_1 = 3'd5;
    localparam STATE_G_PERM_0 = 3'd6;

    logic [2:0] state;
    logic [2:0] state_next;

    // Pattern detection for x (1, 0, 1)
    logic [2:0] x_shift;
    // Timer for monitoring y
    logic [1:0] y_timer;

    // Sequential logic: State register
    always @(posedge clk) begin
        if (!resetn) begin
            state <= STATE_A;
        end else begin
            state <= state_next;
        end
    end

    // Sequential logic: Pattern and Timer registers
    always @(posedge clk) begin
        if (!resetn) begin
            x_shift <= 3'b000;
            y_timer <= 2'b00;
        end else begin
            // Update x shift register only in MON_X state
            if (state == STATE_MON_X) begin
                x_shift <= {x_shift[1:0], x};
            end else if (state == STATE_A || state == STATE_F_PULSE) begin
                x_shift <= 3'b000;
            end

            // Update y timer only in MON_Y state
            if (state == STATE_MON_Y) begin
                y_timer <= y_timer + 1'b1;
            end else if (state == STATE_A || state == STATE_F_PULSE || state == STATE_MON_X || state == STATE_G_START) begin
                y_timer <= 2'b00;
            end
        end
    end

    // Combinational logic: Next state
    always @(*) begin
        state_next = state;
        case (state)
            STATE_A:
                state_next = STATE_F_PULSE;

            STATE_F_PULSE:
                state_next = STATE_MON_X;

            STATE_MON_X:
                begin
                    // Check if the last three bits of x were 1, 0, 1
                    // Since x_shift is updated on the clock edge, we look at the current x
                    if ({x_shift[1:0], x} == 3'b101) begin
                        state_next = STATE_G_START;
                    end else begin
                        state_next = STATE_MON_X;
                    end
                end

            STATE_G_START:
                state_next = STATE_MON_Y;

            STATE_MON_Y:
                begin
                    if (y == 1'b1) begin
                        state_next = STATE_G_PERM_1;
                    end else if (y_timer == 2'd1) begin
                        // After two cycles (timer 0 and 1) if y was not 1
                        state_next = STATE_G_PERM_0;
                    end else begin
                        state_next = STATE_MON_Y;
                    end
                end

            STATE_G_PERM_1:
                state_next = STATE_G_PERM_1;

            STATE_G_PERM_0:
                state_next = STATE_G_PERM_0;

            default:
                state_next = STATE_A;
        endcase
    end

    // Combinational logic: Outputs
    always @(*) begin
        f = 1'b0;
        g = 1'b0;
        case (state)
            STATE_F_PULSE:  f = 1'b1;
            STATE_G_START:  g = 1'b1;
            STATE_MON_Y:    g = 1'b1;
            STATE_G_PERM_1: g = 1'b1;
            STATE_G_PERM_0: g = 1'b0;
            default:        g = 1'b0;
        endcase
    end

endmodule