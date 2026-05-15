module TopModule (
    input  logic clk,
    input  logic reset,
    input  logic x,
    output logic z
);

    // State definition
    localparam S_000 = 3'b000;
    localparam S_001 = 3'b001;
    localparam S_010 = 3'b010;
    localparam S_011 = 3'b011;
    localparam S_100 = 3'b100;
    localparam S_OTHER = 3'b000; // Safety default for unlisted states

    // State registers
    logic [2:0] state;
    logic [2:0] next_state;

    // State register updates (Sequential Logic)
    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= S_000;
        end
        else
        begin
            state <= next_state;
        end
    end

    // Initialization for known state (Requirement #3)
    initial
    begin
        state = S_000;
    end

    // Next State and Output Logic (Combinational Logic)
    always @(*)
    begin
        // Default assignments
        next_state = state;
        z = 1'b0; // Default output is 0

        case (state)
            S_000:
            begin
                if (x == 0) next_state = S_000; // Table: 000, 000 | 0
                else next_state = S_001;      // Table: 000, 001 | 0
                z = 1'b0;
            end
            S_001:
            begin
                if (x == 0) next_state = S_001; // Table: 001, 001 | 0
                else next_state = S_100;      // Table: 001, 100 | 0
                z = 1'b0;
            end
            S_010:
            begin
                if (x == 0) next_state = S_010; // Table: 010, 010 | 0
                else next_state = S_001;      // Table: 010, 001 | 0
                z = 1'b0;
            end
            S_011:
            begin
                if (x == 0) next_state = S_001; // Table: 011, 001 | 1
                else next_state = S_010;      // Table: 011, 010 | 1
                z = 1'b1;
            end
            S_100:
            begin
                if (x == 0) next_state = S_011; // Table: 100, 011 | 1
                else next_state = S_100;      // Table: 100, 100 | 1
                z = 1'b1;
            end
            default:
            begin
                next_state = S_OTHER; // Transition to safe state
                z = 1'b0;
            end
        endcase
    end

endmodule