module TopModule (
    input  logic clk,
    input  logic in,
    input  logic reset,
    output logic [7:0] out_byte,
    output logic done
);

    // Define states
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA_CAPTURE = 2'b10;
    localparam DONE = 2'b11;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Internal registers
    logic [7:0] byte_reg;
    logic [2:0] bit_count;

    // Initial block to set initial conditions
    initial begin
        state = IDLE;
        byte_reg = 8'b0;
        bit_count = 3'b0;
    end

    // Clock edge trigger for sequential logic
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= state_next;
    end

    // Next state logic
    always @(*) begin
        state_next = state;
        case (state)
            IDLE: begin
                state_next = (in == 0) ? START : IDLE;
            end
            START: begin
                if (bit_count == 7)
                    state_next = DATA_CAPTURE;
                else
                    state_next = START;
            end
            DATA_CAPTURE: begin
                byte_reg = {byte_reg[6:0], in};
                if (bit_count == 7)
                    state_next = DONE;
                else
                    state_next = START;
            end
            DONE: begin
                state_next = IDLE;
            end
        endcase
    end

    // Output logic
    always @(*) begin
        out_byte = byte_reg;
        done = (state == DONE);
    end

endmodule