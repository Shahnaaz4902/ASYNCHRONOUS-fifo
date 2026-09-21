module sync_w2r #(
    parameter ASIZE = 4
)(
    output reg [ASIZE:0] rq2_wptr,

    input      [ASIZE:0] wptr,
    input                rclk,
    input                rrst_n
);

    reg [ASIZE:0] rq1_wptr;


    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n) begin
            rq1_wptr <= 0;
            rq2_wptr <= 0;
        end

        else begin
            rq1_wptr <= wptr;
            rq2_wptr <= rq1_wptr;
        end

    end

endmodule