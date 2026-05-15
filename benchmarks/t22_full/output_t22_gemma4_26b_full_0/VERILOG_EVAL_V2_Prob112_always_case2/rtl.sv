module TopModule(
    input  logic [3:0] in,
    output logic [1:0] pos
);

    // Combinational logic for priority encoder
    // Priority is given to the lowest index bit that is high.
    // If no bit is high, output is 0.
    always @(*) begin
        if (in[0]) begin
            pos = 2'd0;
        end else if (in[1]) begin
            pos = 2'd1;
        end else if (in[2]) begin
            pos = 2'd2;
        end else if (in[3]) begin
            pos = 2'd3;
        end else begin
            pos = 2'd0;
        end
    end

endmodule