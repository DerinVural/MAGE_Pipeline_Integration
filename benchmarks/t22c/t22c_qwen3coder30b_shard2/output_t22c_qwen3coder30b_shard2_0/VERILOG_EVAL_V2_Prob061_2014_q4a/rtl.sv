module TopModule (
    input clk,
    input w,
    input R,
    input E,
    input L,
    output logic Q
);

    // Sequential logic
    always @(posedge clk) begin
        if (L)
            Q <= R;
        else if (E)
            Q <= w;
        // else Q remains unchanged
    end

endmodule