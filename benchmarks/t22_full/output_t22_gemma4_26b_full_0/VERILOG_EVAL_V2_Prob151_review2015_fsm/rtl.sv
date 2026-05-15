module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic data,
    input  logic done_counting,
    input  logic ack,
    output logic shift_ena,
    output logic counting,
    output logic done
);

    // State definitions
    localparam STATE_IDLE        = 4'd0;
    localparam STATE_S1         = 4'd1; // Found '1'
    localparam STATE_S2         = 4'd2; // Found '11'
    localparam STATE_S3         = 4'd3; // Found '110'
    localparam STATE_SHIFT      = 4'd4; // Assert shift_ena for 4 cycles
    localparam STATE_WAIT_COUNT  = 4'd5; // Assert counting, wait for done_counting
    localparam STATE_WAIT_ACK    = 4'd6; // Assert done, wait for ack

    logic [3:0] state;
    logic [3:0] state_next;
    logic [2:0] shift_cnt;
    logic [2:0] shift_cnt_next;

    // State register
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_IDLE;
        end else begin
            state <= state_next;
        end
    end

    // Counter register
    always @(posedge clk) begin
        if (reset) begin
            shift_cnt <= 3'd0;
        end else begin
            shift_cnt <= shift_cnt_next;
        end
    end

    // Next state logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_IDLE:
                if (data == 1'b1) state_next = STATE_S1;
                else state_next = STATE_IDLE;
            
            STATE_S1:
                if (data == 1'b1) state_next = STATE_S2;
                else if (data == 1'b0) state_next = STATE_IDLE;
                else state_next = STATE_S1;

            STATE_S2:
                if (data == 1'b0) state_next = STATE_S3;
                else if (data == 1'b1) state_next = STATE_S2;
                else state_next = STATE_IDLE;

            STATE_S3:
                if (data == 1'b1) state_next = STATE_SHIFT;
                else if (data == 1'b1) state_next = STATE_S1; // Should not happen logically but for safety
                else state_next = STATE_IDLE;

            STATE_SHIFT:
                if (shift_cnt == 3'd3) state_next = STATE_WAIT_COUNT;
                else state_next = STATE_SHIFT;

            STATE_WAIT_COUNT:
                if (done_counting == 1'b1) state_next = STATE_WAIT_ACK;
                else state_next = STATE_WAIT_COUNT;

            STATE_WAIT_ACK:
                if (ack == 1'b1) state_next = STATE_IDLE;
                else state_next = STATE_WAIT_ACK;

            default:
                state_next = STATE_IDLE;
        endcase
    end

    // Counter next-state logic
    always @(*) begin
        shift_cnt_next = shift_cnt;
        if (state == STATE_SHIFT) begin
            if (shift_cnt == 3'd3) shift_cnt_next = 3'd0;
            else shift_cnt_next = shift_cnt + 1'b1;
        end else begin
            shift_cnt_next = 3'd0;
        end
    end

    // Output logic
    always @(*) begin
        shift_ena = 1'b0;
        counting  = 1'b0;
        done      = 1'b0;

        if (state == STATE_SHIFT) begin
            shift_ena = 1'b1;
        end else if (state == STATE_WAIT_COUNT) begin
            counting = 1'b1;
        end else if (state == STATE_WAIT_ACK) begin
            done = 1'b1;
        end
    end

endmodule