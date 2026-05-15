module TopModule (
    input  logic a,
    input  logic b,
    input  logic c,
    output logic out
);

    // The K-map analysis yields the simplified expression: Out = a OR (~a AND (b OR c))
    // This covers: 
    // 1. All cases where a=1 (the entire bottom row).
    // 2. The cases where a=0 AND (b=1 OR c=1) (the three '1's in the top row).
    
    assign out = a | (~a & (b | c));

endmodule