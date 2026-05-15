module TopModule (
    input  logic clk,
    input  logic areset,
    input  logic j,
    input  logic k,
    output logic out
);

    // State encoding: 0'b0 = OFF, 0'b1 = ON
    typedef enum logic [0:0] { 
        OFF, 
        ON 
    } state_t;

    // State registers and next state logic
    state_t state;
    state_t state_next;

    // Initialization to ensure 'state' is not 'X' before reset
    initial begin
        state = OFF;
    end

    // 1. Sequential Logic (State Register Update)
    always @(posedge clk or posedge areset) begin
        if (areset) begin
            // Asynchronous Reset to OFF
            state <= OFF;
        end else begin
            state <= state_next;
        end
    end

    // 2. Combinational Logic (Next State Logic)
    always @(*)
    begin
        state_next = state;

        case (state) 
            OFF: begin
                if (j == 0) begin
                    state_next = OFF;
                end else begin // j == 1
                    state_next = ON;
                end
            end
            ON: begin
                if (k == 0) begin
                    state_next = ON;
                end else begin // k == 1
                    state_next = OFF;
                end
            end
        endcase
    end

    // 3. Output Logic (Moore Machine: Output depends only on current state)
    // OFF (state=OFF) -> out=0
    // ON (state=ON) -> out=1
    assign out = (state == ON) ? 1'b1 : 1'b0;

endmodule