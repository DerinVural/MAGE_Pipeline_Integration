module TopModule (
    input logic a,
    input logic b,
    input logic c,
    input logic d,
    output logic q
);

    // Implementing the combinational logic based on the truth table
    // q = 1 when (a=0,b=1,c=0,d=1) OR (a=0,b=1,c=1,d=0) OR (a=0,b=1,c=1,d=1) OR 
    //       (a=1,b=0,c=0,d=1) OR (a=1,b=0,c=1,d=0) OR (a=1,b=0,c=1,d=1) OR 
    //       (a=1,b=1,c=0,d=1) OR (a=1,b=1,c=1,d=0) OR (a=1,b=1,c=1,d=1)
    
    always @(*) begin
        q = (a == 1'b0 && b == 1'b1 && c == 1'b0 && d == 1'b1) ||
            (a == 1'b0 && b == 1'b1 && c == 1'b1 && d == 1'b0) ||
            (a == 1'b0 && b == 1'b1 && c == 1'b1 && d == 1'b1) ||
            (a == 1'b1 && b == 1'b0 && c == 1'b0 && d == 1'b1) ||
            (a == 1'b1 && b == 1'b0 && c == 1'b1 && d == 1'b0) ||
            (a == 1'b1 && b == 1'b0 && c == 1'b1 && d == 1'b1) ||
            (a == 1'b1 && b == 1'b1 && c == 1'b0 && d == 1'b1) ||
            (a == 1'b1 && b == 1'b1 && c == 1'b1 && d == 1'b0) ||
            (a == 1'b1 && b == 1'b1 && c == 1'b1 && d == 1'b1);
    end

endmodule