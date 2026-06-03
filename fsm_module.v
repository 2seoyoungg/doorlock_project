module fsm_module #(
    parameter integer AUTO_LOCK_TICKS     = 10000,
    parameter integer INPUT_TIMEOUT_TICKS = 10000,
    parameter integer ALARM_TIMEOUT_TICKS = 5000
)(
    input  wire       clk,
    input  wire       rst,

    input  wire [3:0] digit_in,
    input  wire       key_valid,
    input  wire       enter,
    input  wire       change,
    input  wire       auto_open,

    output reg        unlock_on,
    output reg        alarm_on,
    output reg        key_led,
    output reg        success_beep,
    output reg        fail_beep,
    output reg  [3:0] input_count_led,
    output reg  [2:0] state
);

    localparam IDLE   = 3'd0;
    localparam INPUT  = 3'd1;
    localparam CHECK  = 3'd2;
    localparam UNLOCK = 3'd3;
    localparam ALARM  = 3'd4;
    localparam CHANGE = 3'd5;

    reg [15:0] input_buffer;
    reg [15:0] saved_password;
    reg [2:0]  digit_count;
    reg [1:0]  fail_count;
    reg [12:0] alarm_cnt;

    reg key_prev;
    reg enter_prev;
    reg change_prev;
    reg auto_open_prev;

    wire key_pulse;
    wire enter_pulse;
    wire change_pulse;
    wire auto_open_pulse;

    wire auto_lock_enable;
    wire auto_lock_timeout;

    wire input_timer_enable;
    wire input_timer_clear;
    wire input_timeout;

    assign key_pulse       = key_valid & ~key_prev;
    assign enter_pulse     = enter & ~enter_prev;
    assign change_pulse    = change & ~change_prev;
    assign auto_open_pulse = auto_open & ~auto_open_prev;

    assign auto_lock_enable = (state == UNLOCK);

    auto_lock_timer #(
        .TIMEOUT_TICKS(AUTO_LOCK_TICKS)
    ) AUTO_LOCK_TIMER (
        .clk(clk),
        .rst(rst),
        .enable(auto_lock_enable),
        .timeout(auto_lock_timeout)
    );

    assign input_timer_enable = (state == INPUT) || (state == CHANGE);
    assign input_timer_clear  = rst || key_pulse || enter_pulse || auto_open_pulse;

    auto_lock_timer #(
        .TIMEOUT_TICKS(INPUT_TIMEOUT_TICKS)
    ) INPUT_TIMEOUT_TIMER (
        .clk(clk),
        .rst(input_timer_clear),
        .enable(input_timer_enable),
        .timeout(input_timeout)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_prev       <= 1'b0;
            enter_prev     <= 1'b0;
            change_prev    <= 1'b0;
            auto_open_prev <= 1'b0;
        end else begin
            key_prev       <= key_valid;
            enter_prev     <= enter;
            change_prev    <= change;
            auto_open_prev <= auto_open;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state           <= IDLE;
            input_buffer    <= 16'd0;
            saved_password  <= 16'h1234;
            digit_count     <= 3'd0;
            fail_count      <= 2'd0;
            alarm_cnt       <= 13'd0;
            unlock_on       <= 1'b0;
            alarm_on        <= 1'b0;
            key_led         <= 1'b0;
            success_beep    <= 1'b0;
            fail_beep       <= 1'b0;
            input_count_led <= 4'b0000;
        end else begin
            key_led      <= 1'b0;
            success_beep <= 1'b0;
            fail_beep    <= 1'b0;

            case (state)
                IDLE: begin
                    unlock_on       <= 1'b0;
                    alarm_on        <= 1'b0;
                    alarm_cnt       <= 13'd0;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;

                    if (auto_open_pulse) begin
                        unlock_on    <= 1'b1;
                        success_beep <= 1'b1;
                        state        <= UNLOCK;
                    end else if (key_pulse) begin
                        input_buffer    <= {12'd0, digit_in};
                        digit_count     <= 3'd1;
                        input_count_led <= 4'b0001;
                        key_led         <= 1'b1;
                        state           <= INPUT;
                    end
                end

                INPUT: begin
                    if (input_timeout) begin
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        unlock_on       <= 1'b0;
                        state           <= IDLE;
                    end else if (auto_open_pulse) begin
                        unlock_on       <= 1'b1;
                        success_beep    <= 1'b1;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= UNLOCK;
                    end else if (key_pulse) begin
                        key_led <= 1'b1;

                        if (digit_count < 3'd4) begin
                            input_buffer <= {input_buffer[11:0], digit_in};
                            digit_count  <= digit_count + 3'd1;

                            case (digit_count + 3'd1)
                                3'd1: input_count_led <= 4'b0001;
                                3'd2: input_count_led <= 4'b0011;
                                3'd3: input_count_led <= 4'b0111;
                                default: input_count_led <= 4'b1111;
                            endcase
                        end
                    end else if (enter_pulse && digit_count == 3'd4) begin
                        state <= CHECK;
                    end
                end

                CHECK: begin
                    if (input_buffer == saved_password) begin
                        unlock_on    <= 1'b1;
                        alarm_on     <= 1'b0;
                        fail_count   <= 2'd0;
                        success_beep <= 1'b1;
                        state        <= UNLOCK;
                    end else begin
                        unlock_on <= 1'b0;
                        fail_beep <= 1'b1;

                        if (fail_count == 2'd2) begin
                            alarm_on  <= 1'b1;
                            alarm_cnt <= 13'd0;
                            state     <= ALARM;
                        end else begin
                            fail_count      <= fail_count + 2'd1;
                            input_buffer    <= 16'd0;
                            digit_count     <= 3'd0;
                            input_count_led <= 4'b0000;
                            state           <= IDLE;
                        end
                    end
                end

                UNLOCK: begin
                    unlock_on <= 1'b1;
                    alarm_on  <= 1'b0;
                    alarm_cnt <= 13'd0;

                    if (auto_lock_timeout) begin
                        unlock_on       <= 1'b0;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end else if (change_pulse) begin
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= CHANGE;
                    end else if (enter_pulse) begin
                        unlock_on       <= 1'b0;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end
                end

                ALARM: begin
                    unlock_on <= 1'b0;

                    if (alarm_cnt >= ALARM_TIMEOUT_TICKS - 1) begin
                        alarm_cnt       <= 13'd0;
                        alarm_on        <= 1'b0;
                        fail_count      <= 2'd0;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        state           <= IDLE;
                    end else begin
                        alarm_cnt <= alarm_cnt + 13'd1;
                        alarm_on  <= 1'b1;
                        state     <= ALARM;
                    end
                end

                CHANGE: begin
                    unlock_on <= 1'b1;
                    alarm_on  <= 1'b0;
                    alarm_cnt <= 13'd0;

                    if (input_timeout) begin
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        unlock_on       <= 1'b0;
                        state           <= IDLE;
                    end else if (key_pulse) begin
                        key_led <= 1'b1;

                        if (digit_count < 3'd4) begin
                            input_buffer <= {input_buffer[11:0], digit_in};
                            digit_count  <= digit_count + 3'd1;

                            case (digit_count + 3'd1)
                                3'd1: input_count_led <= 4'b0001;
                                3'd2: input_count_led <= 4'b0011;
                                3'd3: input_count_led <= 4'b0111;
                                default: input_count_led <= 4'b1111;
                            endcase
                        end
                    end else if (enter_pulse && digit_count == 3'd4) begin
                        saved_password  <= input_buffer;
                        input_buffer    <= 16'd0;
                        digit_count     <= 3'd0;
                        input_count_led <= 4'b0000;
                        unlock_on       <= 1'b0;
                        success_beep    <= 1'b1;
                        state           <= IDLE;
                    end
                end

                default: begin
                    state           <= IDLE;
                    input_buffer    <= 16'd0;
                    digit_count     <= 3'd0;
                    input_count_led <= 4'b0000;
                    unlock_on       <= 1'b0;
                    alarm_on        <= 1'b0;
                    alarm_cnt       <= 13'd0;
                end
            endcase
        end
    end

endmodule
