module top_module(
    input clk_1khz,
    input [12:0] TACT_SW,

    output [7:0] LEDR
);

    wire rst;
    wire enter;
    wire change;
    wire auto_open;

    wire key_valid;
    wire [3:0] digit_in;

    wire unlock_on;
    wire alarm_on;
    wire key_led;
    wire [3:0] input_count_led;
    wire [2:0] state;

    assign rst = 1'b0;

    assign enter     = TACT_SW[10];
    assign change    = TACT_SW[11];
    assign auto_open = TACT_SW[12];

    assign key_valid = TACT_SW[0] | TACT_SW[1] | TACT_SW[2] | TACT_SW[3] |
                       TACT_SW[4] | TACT_SW[5] | TACT_SW[6] | TACT_SW[7] |
                       TACT_SW[8] | TACT_SW[9];

    assign digit_in =
        TACT_SW[0] ? 4'd0 :
        TACT_SW[1] ? 4'd1 :
        TACT_SW[2] ? 4'd2 :
        TACT_SW[3] ? 4'd3 :
        TACT_SW[4] ? 4'd4 :
        TACT_SW[5] ? 4'd5 :
        TACT_SW[6] ? 4'd6 :
        TACT_SW[7] ? 4'd7 :
        TACT_SW[8] ? 4'd8 :
        TACT_SW[9] ? 4'd9 :
                     4'd0;

    fsm_module FSM(
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
        .input_count_led(input_count_led),
        .state(state)
    );

    assign LEDR[0] = input_count_led[0];
    assign LEDR[1] = input_count_led[1];
    assign LEDR[2] = input_count_led[2];
    assign LEDR[3] = input_count_led[3];

    assign LEDR[4] = key_led;
    assign LEDR[5] = unlock_on;
    assign LEDR[6] = alarm_on;
    assign LEDR[7] = auto_open;

endmodule
