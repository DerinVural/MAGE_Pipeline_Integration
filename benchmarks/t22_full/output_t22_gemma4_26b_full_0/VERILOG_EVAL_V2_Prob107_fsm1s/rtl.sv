module TopModule(
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State definitions
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register
    logic current_state;

    // Sequential logic for state transitions
    always @(posedge clk) begin
        if (reset) begin
            current_state <= STATE_B;
        end else begin
            case (current_state)
                STATE_B: begin
                    if (in == 1'b0) begin
                        current_state <= STATE_A;
                    end else begin
                        current_state <= STATE_B;
                    end
                end
                STATE_A: begin
                    if (in == 1'b0) begin
                        current_state <= STATE_B;
                    end else begin
                        current_state <= STATE_A;
                    end
                end
                default: current_state <= STATE_B;
            endcase
        end
    end

    // Combinational logic for Moore output
    always @(*)
    begin
        case (current_state)
            STATE_B: out = 1'b1;
            STATE_A: out = 1'b0;
            default: out = 1'b1;
        endcase
    end

endmodule