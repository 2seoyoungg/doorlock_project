module piezo_alarm(
    input  wire clk,
    input  wire rst,
    input  wire alarm_on,
    input  wire success_beep,
    input  wire fail_beep,
    output reg  piezo
);

    reg tone;

    reg [8:0] success_cnt;
    reg [8:0] fail_cnt;

    reg [7:0] alarm_beat;
    reg       alarm_gate;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tone        <= 1'b0;
            success_cnt <= 9'd0;
            fail_cnt    <= 9'd0;
            alarm_beat  <= 8'd0;
            alarm_gate  <= 1'b0;
            piezo       <= 1'b0;
        end else begin
            tone <= ~tone;

            if (success_beep) begin
                success_cnt <= 9'd300;
            end

            if (fail_beep) begin
                fail_cnt <= 9'd400;
            end

            if (alarm_on) begin
                success_cnt <= 9'd0;
                fail_cnt    <= 9'd0;

                if (alarm_beat >= 8'd200) begin
                    alarm_beat <= 8'd0;
                    alarm_gate <= ~alarm_gate;
                end else begin
                    alarm_beat <= alarm_beat + 8'd1;
                end

                piezo <= alarm_gate ? tone : 1'b0;
            end else if (success_cnt > 9'd0) begin
                success_cnt <= success_cnt - 9'd1;
                alarm_beat  <= 8'd0;
                alarm_gate  <= 1'b0;
                piezo       <= tone;
            end else if (fail_cnt > 9'd0) begin
                fail_cnt   <= fail_cnt - 9'd1;
                alarm_beat <= 8'd0;
                alarm_gate <= 1'b0;

                if ((fail_cnt > 9'd300) || (fail_cnt <= 9'd200 && fail_cnt > 9'd100))
                    piezo <= tone;
                else
                    piezo <= 1'b0;
            end else begin
                alarm_beat <= 8'd0;
                alarm_gate <= 1'b0;
                piezo      <= 1'b0;
            end
        end
    end

endmodule
