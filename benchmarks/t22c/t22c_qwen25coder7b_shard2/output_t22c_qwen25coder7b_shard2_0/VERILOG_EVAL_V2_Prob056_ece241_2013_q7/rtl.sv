module TopModule (
    input wire clk,
    input wire j,
    input wire k,
    output wire Q
);

    // Register to hold the current state of Q
    logic Qold;
    always @(posedge clk) begin
        if (j == 1'b1 && k == 1'b1)
            Qold <= ~Qold;
        else if (j == 1'b1 && k == 1'b0)
            Qold <= 1'b1;
        else if (j == 1'b0 && k == 1'b1)
            Qold <= 1'b0;
        else
            Qold <= Qold;
    end

    // Assign the output Q
    assign Q = Qold;

endmodule;