module TopModule (
    input  logic clk,
    input  logic load,
    input  logic [511:0] data,
    output logic [511:0] q
);

    logic [511:0] cells;

    initial begin
        cells = 0;
    end

    always @(posedge clk) begin
        if (load)
            cells = data;
        else begin
            for (int i = 0; i < 512; i++) begin
                int left = (i == 0) ? 0 : cells[(i-1)];
                int center = cells[i];
                int right = (i == 511) ? 0 : cells[(i+1)];
                q[i] = (left == 1 && center == 1 && right == 1) ? 0 :
                       (left == 1 && center == 1 && right == 0) ? 1 :
                       (left == 1 && center == 0 && right == 1) ? 1 :
                       (left == 1 && center == 0 && right == 0) ? 0 :
                       (left == 0 && center == 1 && right == 1) ? 1 :
                       (left == 0 && center == 1 && right == 0) ? 1 :
                       (left == 0 && center == 0 && right == 1) ? 1 :
                       (left == 0 && center == 0 && right == 0) ? 0 : 0;
            end
        end
    end

endmodule