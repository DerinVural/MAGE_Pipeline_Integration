module TopModule (logic clk, logic load, logic [255:0] data, logic [255:0] q);
    // Grid size 16x16
    localparam int SIZE = 16;
    localparam int TOTAL = SIZE * SIZE;
    logic [TOTAL-1:0] q_reg;
    logic [TOTAL-1:0] q_next;
    initial begin
        q_reg = '0;
    end
    always @(posedge clk) begin
        if (load) begin
            q_reg <= data;
        end else begin
            q_reg <= q_next;
        end
    end
    assign q = q_reg;
    function automatic logic [5:0] count_neighbors(input int x, y);
        integer x_adj, y_adj;
        logic [5:0] count;
        begin
            count = 0;
            for (int dx = -1; dx <= 1; dx++) begin
                for (int dy = -1; dy <= 1; dy++) begin
                    if (dx == 0 && dy == 0) continue;
                    x_adj = (x + dx + SIZE) % SIZE;
                    y_adj = (y + dy + SIZE) % SIZE;
                    count += q_reg[y * SIZE + x_adj];
                end
            end
            count_neighbors = count;
        end
    endfunction
    generate
        genvar i, j;
        for (i = 0; i < SIZE; i = i + 1) begin: row
            for (j = 0; j < SIZE; j = j + 1) begin: col
                logic current_state;
                logic [5:0] neighbor_count;
                assign current_state = q_reg[i * SIZE + j];
                assign neighbor_count = count_neighbors(j, i);
                always @(*) begin
                    if (current_state) begin
                        if (neighbor_count <= 1 || neighbor_count >= 4) begin
                            q_next[i * SIZE + j] = 1'b0;
                        end else if (neighbor_count == 3) begin
                            q_next[i * SIZE + j] = 1'b1;
                        end else begin
                            q_next[i * SIZE + j] = current_state;
                        end
                    end else begin
                        if (neighbor_count == 3) begin
                            q_next[i * SIZE + j] = 1'b1;
                        end else begin
                            q_next[i * SIZE + j] = current_state;
                        end
                    end
                end
            end
        end
    endgenerate
endmodule