module TopModule(
    input  logic clk,
    input  logic areset,
    input  logic in,
    output logic out
);

    // State encoding
    localparam STATE_A = 1'b0;
    localparam STATE_B = 1'b1;

    // State register
    logic state;

    // Sequential logic for state transitions
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= STATE_B;
        end else begin
            case (state) 
                STATE_A: begin
                    if (in == 1'b0) begin
                        state <= STATE_B;
                    end else begin
                        state <= STATE_A;
                    end
                end
                STATE_B: begin
                    if (in == 1'b0) begin
                        state <= STATE_A;
                    end else begin
                        state <= STATE_B;
                    end
                end
                default: state <= STATE_B;
            endcase
        end
    end

    // Combinational logic for Moore output
    always @(*) begin
        case (state) 
            STATE_A: out = 1'b0;
            STATE_B: out = 1'b1;
            default: out = 1'b1;
        endcase
    end

endmodule