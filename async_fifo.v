module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
)(
    output [DSIZE-1:0] rdata,
    output             wfull,
    output             rempty,

    input  [DSIZE-1:0] wdata,
    input              winc,
    input              wclk,
    input              wrst_n,

    input              rinc,
    input              rclk,
    input              rrst_n
);

    wire [ASIZE-1:0] waddr;
    wire [ASIZE-1:0] raddr;

    wire [ASIZE:0] wptr;
    wire [ASIZE:0] rptr;

    wire [ASIZE:0] wq2_rptr;
    wire [ASIZE:0] rq2_wptr;


    // ------------------------------------------------------------
    // Synchronize READ pointer into WRITE clock domain
    // ------------------------------------------------------------
    sync_r2w #(
        .ASIZE(ASIZE)
    ) sync_r2w_inst (
        .wq2_rptr(wq2_rptr),
        .rptr(rptr),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );


    // ------------------------------------------------------------
    // Synchronize WRITE pointer into READ clock domain
    // ------------------------------------------------------------
    sync_w2r #(
        .ASIZE(ASIZE)
    ) sync_w2r_inst (
        .rq2_wptr(rq2_wptr),
        .wptr(wptr),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );


    // ------------------------------------------------------------
    // FIFO memory
    // ------------------------------------------------------------
    fifo_mem #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE)
    ) fifo_mem_inst (
        .rdata(rdata),
        .wdata(wdata),
        .waddr(waddr),
        .raddr(raddr),
        .wclken(winc),
        .wfull(wfull),
        .wclk(wclk)
    );


    // ------------------------------------------------------------
    // Read pointer + EMPTY generation
    // ------------------------------------------------------------
    rptr_empty #(
        .ASIZE(ASIZE)
    ) rptr_empty_inst (
        .rempty(rempty),
        .raddr(raddr),
        .rptr(rptr),
        .rq2_wptr(rq2_wptr),
        .rinc(rinc),
        .rclk(rclk),
        .rrst_n(rrst_n)
    );


    // ------------------------------------------------------------
    // Write pointer + FULL generation
    // ------------------------------------------------------------
    wptr_full #(
        .ASIZE(ASIZE)
    ) wptr_full_inst (
        .wfull(wfull),
        .waddr(waddr),
        .wptr(wptr),
        .wq2_rptr(wq2_rptr),
        .winc(winc),
        .wclk(wclk),
        .wrst_n(wrst_n)
    );

endmodule
