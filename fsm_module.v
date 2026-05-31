module fsm_module(
    input clk,
    input rst,

    input [3:0] digit_in,
    input key_valid,
    input enter,
    input change,
    input auto_open,

    output reg unlock_on,
    output reg alarm_on,
    output reg key_led,
    output reg [3:0] input_count_led,
    output reg [2:0] state
);

    parameter IDLE   = 3'd0,
              INPUT  = 3'd1,
              CHECK  = 3'd2,
              UNLOCK = 3'd3,
              ALARM  = 3'd4,
              CHANGE = 3'd5;

    reg [15:0] input_buffer;
    reg [15:0] saved_password;
    reg [1:0] digit_count;
    reg [1:0] fail_count;

    reg key_prev;
    reg enter_prev;
    reg change_prev;
    reg auto_open_prev;

    wire key_pulse;
    wire enter_pulse;
    wire change_pulse;
    wire auto_open_pulse;

    assign key_pulse = key_valid & ~key_prev;
    assign enter_pulse = enter & ~enter_prev;
    assign change_pulse = change & ~change_prev;
    assign auto_open_pulse = auto_open & ~auto_open_prev;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            key_prev <= 1'b0;
            enter_prev <= 1'b0;
            change_prev <= 1'b0;
            auto_open_prev <= 1'b0;
        end else begin
            key_prev <= key_valid;
            enter_prev <= enter;
            change_prev <= change;
            auto_open_prev <= auto_open;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            input_buffer <= 16'd0;
            saved_password <= 16'h1234;
            digit_count <= 2'd0;
            fail_count <= 2'd0;
            unlock_on <= 1'b0;
            alarm_on <= 1'b0;
            key_led <= 1'b0;
            input_count_led <= 4'b0000;
        end else begin
            key_led <= 1'b0;

            case (state)

                IDLE: begin
                    unlock_on <= 1'b0;
                    alarm_on <= 1'b0;
                    input_buffer <= 16'd0;
                    digit_count <= 2'd0;
                    input_count_led <= 4'b0000;

                    if (auto_open_pulse) begin
                        unlock_on <= 1'b1;
                        state <= UNLOCK;
                    end
                    else if (key_pulse) begin
                        input_buffer <= {12'd0, digit_in};
                        digit_count <= 2'd1;
                        input_count_led <= 4'b0001;
                        key_led <= 1'b1;
                        state <= INPUT;
                    end
                end

                INPUT: begin
                    if (auto_open_pulse) begin
                        unlock_on <= 1'b1;
                        input_buffer <= 16'd0;
                        digit_count <= 2'd0;
                        input_count_led <= 4'b0000;
                        state <= UNLOCK;
                    end
                    else if (key_pulse) begin
                        input_buffer <= {input_buffer[11:0], digit_in};
                        key_led <= 1'b1;

                        if (digit_count == 2'd0) begin
                            digit_count <= 2'd1;
                            input_count_led <= 4'b0001;
                        end
                        else if (digit_count == 2'd1) begin
                            digit_count <= 2'd2;
                            input_count_led <= 4'b0011;
                        end
                        else if (digit_count == 2'd2) begin
                            digit_count <= 2'd3;
                            input_count_led <= 4'b0111;
                        end
                        else begin
                            digit_count <= 2'd0;
                            input_count_led <= 4'b1111;
                        end
                    end

                    if (enter_pulse) begin
                        state <= CHECK;
                    end
                end

                CHECK: begin
                    if (input_buffer == saved_password) begin
                        unlock_on <= 1'b1;
                        alarm_on <= 1'b0;
                        fail_count <= 2'd0;
                        state <= UNLOCK;
                    end else begin
                        unlock_on <= 1'b0;

                        if (fail_count == 2'd2) begin
                            alarm_on <= 1'b1;
                            state <= ALARM;
                        end else begin
                            fail_count <= fail_count + 2'd1;
                            input_buffer <= 16'd0;
                            digit_count <= 2'd0;
                            input_count_led <= 4'b0000;
                            state <= IDLE;
                        end
                    end
                end

                UNLOCK: begin
                    unlock_on <= 1'b1;
                    alarm_on <= 1'b0;

                    if (change_pulse) begin
                        input_buffer <= 16'd0;
                        digit_count <= 2'd0;
                        input_count_led <= 4'b0000;
                        state <= CHANGE;
                    end
                    else if (enter_pulse) begin
                        unlock_on <= 1'b0;
                        state <= IDLE;
                    end
                end

                ALARM: begin
                    alarm_on <= 1'b1;
                    unlock_on <= 1'b0;
                    state <= ALARM;
                end

                CHANGE: begin
                    unlock_on <= 1'b1;
                    alarm_on <= 1'b0;

                    if (key_pulse) begin
                        input_buffer <= {input_buffer[11:0], digit_in};
                        key_led <= 1'b1;

                        if (digit_count == 2'd0) begin
                            digit_count <= 2'd1;
                            input_count_led <= 4'b0001;
                        end
                        else if (digit_count == 2'd1) begin
                            digit_count <= 2'd2;
                            input_count_led <= 4'b0011;
                        end
                        else if (digit_count == 2'd2) begin
                            digit_count <= 2'd3;
                            input_count_led <= 4'b0111;
                        end
                        else begin
                            digit_count <= 2'd0;
                            input_count_led <= 4'b1111;
                        end
                    end

                    if (enter_pulse) begin
                        saved_password <= input_buffer;
                        input_buffer <= 16'd0;
                        digit_count <= 2'd0;
                        input_count_led <= 4'b0000;
                        unlock_on <= 1'b0;
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
