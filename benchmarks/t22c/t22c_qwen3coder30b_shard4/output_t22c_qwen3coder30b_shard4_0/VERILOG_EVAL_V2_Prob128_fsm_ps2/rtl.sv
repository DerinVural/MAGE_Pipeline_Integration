module TopModule (
    input clk,
    input reset,
    input [7:0] in,
    output logic done
);

    // Define states
    localparam IDLE   = 2'b00;
    localparam BYTE1  = 2'b01;
    localparam BYTE2  = 2'b10;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Initialize state
    initial begin
        state <= IDLE;
    end

    // Sequential logic
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= state_next;
    end

    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (in[3])
                    state_next = BYTE1;
                else
                    state_next = IDLE;
            end
            BYTE1: begin
                state_next = BYTE2;
            end
            BYTE2: begin
                state_next = IDLE;
            end
        endcase
    end

    // Output logic
    always @(*) begin
        case (state)
            IDLE:   done = 1'b0;
            BYTE1:  done = 1'b0;
            BYTE2:  done = 1'b1;
        endcase
    end

endmodule