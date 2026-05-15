module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    input  logic done_counting,
    input  logic ack,
    output logic shift_ena,
    output logic counting,
    output logic done
);

    localparam STATE_IDLE = 2'b00;
    localparam STATE_PATTERN_DETECTED = 2'b01;
    localparam STATE_WAIT_SHIFTS = 2'b10;
    localparam STATE_COUNTING = 2'b11;
    localparam STATE_DONE = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    always @(posedge clk) begin
        if (reset)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    always @(*) begin
        state_next = state;
        case (state)
        STATE_IDLE: begin
            if (data == 1 && data >> 1 == 0 && data >> 2 == 1 && data >> 3 == 1) begin
                state_next = STATE_PATTERN_DETECTED;
                shift_ena = 1;
            end else begin
                shift_ena = 0;
            end
        end
        STATE_PATTERN_DETECTED: begin
            state_next = STATE_WAIT_SHIFTS;
            shift_ena = 0;
        end
        STATE_WAIT_SHIFTS: begin
            if (shift_ena) begin
                state_next = STATE_COUNTING;
                shift_ena = 0;
            end else begin
                counting = 0;
            end
        end
        STATE_COUNTING: begin
            if (done_counting) begin
                state_next = STATE_DONE;
                counting = 0;
                done = 1;
            end else begin
                counting = 1;
                done = 0;
            end
        end
        STATE_DONE: begin
            if (ack) begin
                state_next = STATE_IDLE;
                done = 0;
            end else begin
                counting = 1;
                done = 1;
            end
        end
        endcase
    end

endmodule;