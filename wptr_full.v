module wptr_full #(
    parameter ASIZE = 4
)(
    output reg             wfull,
    output     [ASIZE-1:0] waddr,
    output reg [ASIZE:0]   wptr,

    input      [ASIZE:0]   wq2_rptr,
    input                  winc,
    input                  wclk,
    input                  wrst_n
);

    reg [ASIZE:0] wbin;

    wire [ASIZE:0] wbinnext;
    wire [ASIZE:0] wgraynext;
    wire           wfull_val;


    // ------------------------------------------------------------
    // Binary write pointer + Gray write pointer
    // ------------------------------------------------------------

    always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n) begin
            wbin <= 0;
            wptr <= 0;
        end

        else begin
            wbin <= wbinnext;
            wptr <= wgraynext;
        end

    end


    // Binary address used for memory
    assign waddr = wbin[ASIZE-1:0];


    // Increment only when write requested and FIFO isn't full
    assign wbinnext =
                wbin + (winc & ~wfull);


    // Binary → Gray
    assign wgraynext =
                (wbinnext >> 1) ^ wbinnext;


    // ------------------------------------------------------------
    // FULL condition
    //
    // The synchronized read pointer is modified by
    // inverting the two MSBs before comparison.
    // ------------------------------------------------------------

    assign wfull_val =
                (wgraynext ==
                {
                    ~wq2_rptr[ASIZE:ASIZE-1],
                     wq2_rptr[ASIZE-2:0]
                });


    always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n)
            wfull <= 1'b0;

        else
            wfull <= wfull_val;

    end

endmodule