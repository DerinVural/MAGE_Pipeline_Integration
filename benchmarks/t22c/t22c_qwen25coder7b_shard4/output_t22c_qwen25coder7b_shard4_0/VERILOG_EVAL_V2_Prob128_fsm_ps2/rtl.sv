module DutModule (
    input logic clk,
    input logic reset,
    input logic [7:0] in,
    output logic done
);

    // Define states
    localparam IDLE = 2'b00;
    localparam FIRST_BYTE = 2'b01;
    localparam SECOND_BYTE = 2'b10;
    localparam DONE = 2'b11;

    // State register
    logic [1:0] state;
    always @(posedge clk or posedge reset) begin
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
                if (in[3])
                    state_next = FIRST_BYTE;
            end
            FIRST_BYTE: begin
                state_next = SECOND_BYTE;
            end
            SECOND_BYTE: begin
                state_next = DONE;
            end
            DONE: begin
                state_next = IDLE;
            end
        endcase
    end

    // Done signal generation
    always @(*) begin
        done = (state == DONE);
    end

endmodule