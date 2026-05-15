module TopModule (
    input  logic clock,
    input  logic a,
    output logic p,
    output logic q
);

    // State encoding
    localparam STATE_0 = 2'b00;
    localparam STATE_1 = 2'b01;
    localparam STATE_2 = 2'b10;
    localparam STATE_3 = 2'b11;

    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic for state transition
    always @(posedge clock) begin
        state <= state_next;
    end

    // Next state combinational logic
    always @(*) begin
        state_next = state;
        case (state)
            STATE_0: begin
                if (a) state_next = STATE_1;
                else    state_next = STATE_0;
            end
            STATE_1: begin
                if (a) state_next = STATE_1;
                else    state_next = STATE_2;
            end
            STATE_2: begin
                if (a) state_next = STATE_2;
                else    state_next = STATE_3;
            end
            STATE_3: begin
                if (a) state_next = STATE_0;
                else    state_next = STATE_3;
            end
            default: state_next = STATE_0;
        endcase
    end

    // Output combinational logic
    always @(*) begin
        p = 1'b0;
        q = 1'b0;
        case (state)
            STATE_0: begin
                p = 1'b0;
                q = 1'b0;
            end
            STATE_1: begin
                p = a;
                q = 1'b0;
            end
            STATE_2: begin
                p = 1'b1;
                q = 1'b1;
            end
            STATE_3: begin
                p = a;
                q = 1'b1;
            end
        endcase
    end

    // Initial state
    initial begin
        state = STATE_0;
    end

endmodule