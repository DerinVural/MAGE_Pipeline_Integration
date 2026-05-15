module TopModule (
    input  logic clock,
    input  logic a,
    output logic p,
    output logic q
);

    // Register to store previous value of 'a'
    logic a_prev;

    // Sequential logic to store previous value of 'a'
    always @(posedge clock) begin
        a_prev <= a;
    end

    // Combinational logic to determine outputs p and q
    always @(*) begin
        // Based on the pattern observed in the waveforms
        // p = a_prev
        // q = a_prev & a
        p = a_prev;
        q = a_prev & a;
    end

endmodule