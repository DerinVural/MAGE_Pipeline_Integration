module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic j,
    input  logic k,
    output logic out
);

    // Define states
    localparam OFF = 2'b00;
    localparam ON = 2'b01;

    // State register
    logic [1:0] state;
    logic [1:0] state_next;

    // Sequential logic to update state
    always @(posedge clk) begin
        if (reset)
            state <= OFF;
        else
            state <= state_next;
    end

    // Combinational logic to determine next state
    always @(*) begin
        state_next = state;
        case(state)
            OFF: begin
                if (j)
                    state_next = ON;
            end
            ON: begin
                if (k)
                    state_next = OFF;
            end
        endcase
    end

    // Combinational logic to determine output
    always @(*) begin
        out = (state == ON);
    end

endmodule;