module TopModule(
    input logic clk,
    input logic areset,
    input logic train_valid,
    input logic train_taken,
    output logic [1:0] state
);

    // Parameters for states
    localparam STATE_00 = 2'b00;
    localparam STATE_01 = 2'b01;
    localparam STATE_10 = 2'b10;
    localparam STATE_11 = 2'b11;

    // Registers for state
    logic [1:0] state_reg;
    logic [1:0] state_next;

    // Initial state assignment
    initial begin
        state_reg = STATE_01; // Weakly not taken
    end

    // Sequential logic
    always @(posedge clk) begin
        if (areset)
            state_reg <= STATE_01;
        else
            state_reg <= state_next;
    end

    // Combinational logic
    always @(*) begin
        state_next = state_reg;
        case ({train_valid, train_taken})
            2'b01: begin
                if (state_reg == STATE_11)
                    state_next = STATE_11; // Saturated at 3
                else
                    state_next = state_reg + 1;
            end
            2'b10: begin
                if (state_reg == STATE_00)
                    state_next = STATE_00; // Saturated at 0
                else
                    state_next = state_reg - 1;
            end
            default: begin
                // Do nothing, keep the current state
            end
        endcase
    end

    // Assign output
    assign state = state_reg;

endmodule