module rptr_empty #(
    parameter ASIZE = 4
)(
    output reg             rempty,
    output     [ASIZE-1:0] raddr,
    output reg [ASIZE:0]   rptr,

    input      [ASIZE:0]   rq2_wptr,
    input                  rinc,
    input                  rclk,
    input                  rrst_n
);

    reg [ASIZE:0] rbin;

    wire [ASIZE:0] rbinnext;
    wire [ASIZE:0] rgraynext;
    wire           rempty_val;


    // ------------------------------------------------------------
    // Binary read pointer + Gray read pointer
    // ------------------------------------------------------------

    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin
            rbin <= 0;
            rptr <= 0;
        end

        else begin
            rbin <= rbinnext;
            rptr <= rgraynext;
        end

    end


    // Binary address used for memory
    assign raddr = rbin[ASIZE-1:0];


    // Increment only when read is requested and FIFO isn't empty
    assign rbinnext =
                rbin + (rinc & ~rempty);


    // Binary → Gray
    assign rgraynext =
                (rbinnext >> 1) ^ rbinnext;


    // ------------------------------------------------------------
    // EMPTY condition
    // ------------------------------------------------------------

    assign rempty_val =
                (rgraynext == rq2_wptr);


    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n)
            rempty <= 1'b1;

        else
            rempty <= rempty_val;

    end

endmodule