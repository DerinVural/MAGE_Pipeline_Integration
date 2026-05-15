module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic j,
    input  logic k,
    output logic out
);

    // State definitions
    localparam STATE_OFF = 1'b0;
    localparam STATE_ON  = 1'b1;

    // State register
    logic state;

    // Initialize state to avoid X in simulation
    initial begin
        state = STATE_OFF;
    end

    // Sequential logic for state transitions
    always @(posedge clk) begin
        if (reset) begin
            state <= STATE_OFF;
        end else begin
            case (state) 
                STATE_OFF: begin
                    if (j) begin
                        state <= STATE_ON;
                    end else begin
                        state <= STATE_OFF;
                    end
                end
                STATE_ON: begin
                    if (k) begin
                        state <= STATE_OFF;
                    end else begin
                        state <= STATE_ON;
                    end
                end
                default: begin
                    state <= STATE_OFF;
                end
            endcase
        end
    end

    // Combinational logic for Moore output
    always @(*) begin
        if (state == STATE_ON) begin
            out = 1'b1;
        end else begin
            out = 1'b0;
        end
    end

endmodule