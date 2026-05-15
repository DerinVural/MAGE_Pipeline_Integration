module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register
    logic state;

    // Initialize state to a known value to avoid X in simulation
    initial begin
        state = STATE_B;
    end

    // Sequential logic for state transitions
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_B;
        end else begin
            case (state)
                STATE_B: begin
                    if (in == 1'b0) begin
                        state <= STATE_A;
                    end else begin
                        state <= STATE_B;
                    end
                end
                STATE_A: begin
                    if (in == 1'b0) begin
                        state <= STATE_B;
                    end else begin
                        state <= STATE_A;
                    end
                end
                default: begin
                    state <= STATE_B;
                end
            endcase
        end
    end

    // Combinational logic for output (Moore machine: output depends only on state)
    always @(*) begin
        case (state)
            STATE_B: out = 1'b1;
            STATE_A: out = 1'b0;
            default: out = 1'b1;
        endcase
    end

endmodule