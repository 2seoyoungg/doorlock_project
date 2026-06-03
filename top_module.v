module top_module(
    input  wire        clk_1khz,
    input  wire        RESET_N,
    input  wire [12:0] TACT_SW,

    output wire [15:0] LEDR,
    output wire [7:0]  FND_SEG,
    output wire [3:0]  FND_COM,

    output wire        piezo
);

    wire rst;
    assign rst = ~RESET_N;

    wire        key_valid;
    wire [3:0]  digit_in;
    wire        enter;
    wire        change;
    wire        auto_open;

    input_manager #(.CLK_FREQ_HZ(1000), .DEBOUNCE_MS(20)) U_INPUT (
        .clk(clk_1khz),
        .reset_n(RESET_N),
        .tact_sw(TACT_SW),
        .digit_in(digit_in),
        .key_valid(key_valid),
        .enter(enter),
        .change(change),
        .auto_open(auto_open)
    );

    wire unlock_on, alarm_on, key_led;
    wire success_beep, fail_beep;
    wire [3:0] input_count_led;
    wire [2:0] state;

    fsm_module #(
        .AUTO_LOCK_TICKS(10000),
        .INPUT_TIMEOUT_TICKS(10000),
        .ALARM_TIMEOUT_TICKS(5000)
    ) FSM (
        .clk(clk_1khz),
        .rst(rst),
        .digit_in(digit_in),
        .key_valid(key_valid),
        .enter(enter),
        .change(change),
        .auto_open(auto_open),
        .unlock_on(unlock_on),
        .alarm_on(alarm_on),
        .key_led(key_led),
        .success_beep(success_beep),
        .fail_beep(fail_beep),
        .input_count_led(input_count_led),
        .state(state)
    );

    fnd_team_adapter U_FND (
        .clk(clk_1khz),
        .rst(rst),
        .state(state),
        .input_count_led(input_count_led),
        .fnd_seg(FND_SEG),
        .fnd_com(FND_COM)
    );

    wire [2:0] input_cnt;
    assign input_cnt = {2'b00, input_count_led[0]} + {2'b00, input_count_led[1]}
                     + {2'b00, input_count_led[2]} + {2'b00, input_count_led[3]};

    reg [9:0] blink_cnt;
    reg       blink;

    always @(posedge clk_1khz or posedge rst) begin
        if (rst) begin
            blink_cnt <= 10'd0;
            blink     <= 1'b0;
        end else if (blink_cnt >= 10'd166) begin
            blink_cnt <= 10'd0;
            blink     <= ~blink;
        end else begin
            blink_cnt <= blink_cnt + 10'd1;
        end
    end

    led_controller U_LED (
        .clk(clk_1khz),
        .rst_n(RESET_N),
        .state(state),
        .input_cnt(input_cnt),
        .blink(blink),
        .led(LEDR)
    );

    piezo_alarm U_PIEZO (
        .clk(clk_1khz),
        .rst(rst),
        .alarm_on(alarm_on),
        .success_beep(success_beep),
        .fail_beep(fail_beep),
        .piezo(piezo)
    );

endmodule
