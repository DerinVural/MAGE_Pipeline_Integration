module TopModule (
    input  logic a,
    input  logic b,
    input  logic sel_b1,
    input  logic sel_b2,
    output logic out_assign,
    output logic out_always
);

    // 1. Implementation using continuous assign statement
    // Choose b if both sel_b1 and sel_b2 are true. Otherwise, choose a.
    assign out_assign = (sel_b1 && sel_b2) ? b : a;

    // 2. Implementation using procedural if statement
    // Use always @(*) for combinational logic as required.
    always @* begin
        if (sel_b1 && sel_b2) begin
            out_always = b;
        end else begin
            out_always = a;
        end
    end

endmodule