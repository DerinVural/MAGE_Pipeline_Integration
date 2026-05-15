module TopModule (
    input clk,
    input resetn,
    input [2:0] r,
    output [2:0] g
);

    // Define state codes
    localparam ST_A = 2'b00;
    localparam ST_B = 2'b01;
    localparam ST_C = 2'b10;
    localparam ST_D = 2'b11;

    // Current and next state signals
    logic [1:0] state;
    logic [1:0] state_next;

    // State register
    always @(posedge clk) begin
        if (!resetn)
            state <= ST_A;
        else
            state <= state_next;
    end

    // State transition logic
    always @(*) begin
        case (state)
            ST_A:
                if (r[0])
                    state_next = ST_B;
                else if (r[1])
                    state_next = ST_C;
                else if (r[2])
                    state_next = ST_D;
                else
                    state_next = ST_A;
            
            ST_B:
                if (r[0])
                    state_next = ST_B;
                else
                    state_next = ST_A;
            
            ST_C:
                if (r[1])
                    state_next = ST_C;
                else
                    state_next = ST_A;
            
            ST_D:
                if (r[2])
                    state_next = ST_D;
                else
                    state_next = ST_A;
        endcase
    end

    // Output logic
    assign g[0] = (state == ST_B);
    assign g[1] = (state == ST_C);
    assign g[2] = (state == ST_D);

endmodule