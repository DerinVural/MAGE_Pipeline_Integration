module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic in,
    output logic out
);

    // State Encoding
    localparam STATE_A = 2'b00;
    localparam STATE_B = 2'b01;
    localparam STATE_C = 2'b10;
    localparam STATE_D = 2'b11;

    // State Registers and Wires
    logic [1:0] current_state;
    logic [1:0] next_state;
    logic out_reg;

    // Initialization (Ensures known state before clock edges)
    initial begin
        current_state = STATE_A;
    end

    // State Register Logic (Synchronous Reset)
    always @(posedge clk)
    begin
        if (reset) begin
            current_state <= STATE_A; // Synchronous active high reset
        end else begin
            current_state <= next_state;
        end
    end

    // Next State Logic (Combinational)
    always_comb
    begin
        next_state = current_state; // Default assignment

        case (current_state)
            STATE_A:
                next_state = in ? STATE_B : STATE_A;
            STATE_B:
                next_state = in ? STATE_C : STATE_B;
            STATE_C:
                next_state = in ? STATE_D : STATE_A;
            STATE_D:
                next_state = in ? STATE_B : STATE_C;
            default:
                next_state = STATE_A; // Safety default
        endcase
    end

    // Output Logic (Moore Machine - Combinational based on current_state)
    always_comb
    begin
        case (current_state)
            STATE_A: out_reg = 1'b0;
            STATE_B: out_reg = 1'b0;
            STATE_C: out_reg = 1'b0;
            STATE_D: out_reg = 1'b1;
            default: out_reg = 1'b0; // Safety default
        endcase
    end

    // Output assignment
    assign out = out_reg;

endmodule