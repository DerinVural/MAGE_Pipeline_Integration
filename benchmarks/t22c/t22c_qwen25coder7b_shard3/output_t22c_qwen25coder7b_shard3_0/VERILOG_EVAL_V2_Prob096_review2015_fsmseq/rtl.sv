module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic data,
    output logic start_shifting
);

    // Define states
    localparam IDLE     = 2'b00;
    localparam FIRST_ONE = 2'b01;
    localparam SECOND_ONE = 2'b10;
    localparam THIRD_ONE = 2'b11;

    // State register
    logic [1:0] state;
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= state_next;
    end

    // Next state logic
    logic [1:0] state_next;
    always @(*) begin
        state_next = state;
        case (state)
            IDLE: begin
                if (data == 1'b1)
                    state_next = FIRST_ONE;
            end
            FIRST_ONE: begin
                if (data == 1'b1)
                    state_next = SECOND_ONE;
                else
                    state_next = IDLE;
            end
            SECOND_ONE: begin
                if (data == 1'b0)
                    state_next = IDLE;
                else if (data == 1'b1)
                    state_next = THIRD_ONE;
            end
            THIRD_ONE: begin
                state_next = THIRD_ONE; // Stay in this state
            end
        endcase
    end

    // Output logic
    always @(*) begin
        start_shifting = (state == THIRD_ONE);
    end

endmodule