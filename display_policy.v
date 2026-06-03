module display_policy (
    input wire [2:0] fsm_state,
    input wire mask_enable,
    input wire [2:0] input_count,
    input wire [15:0] digit_data,
    input wire blink_tick,
    output reg [15:0] disp_digits
);

    localparam [3:0] C_N     = 4'b0110;
    localparam [3:0] C_E     = 4'b0111;
    localparam [3:0] C_O     = 4'b1000;
    localparam [3:0] C_P     = 4'b1001;

    localparam [3:0] C_STAR  = 4'b1010;
    localparam [3:0] C_DASH  = 4'b1011;
    localparam [3:0] C_BLANK = 4'b1100;
    localparam [3:0] C_F     = 4'b1101;
    localparam [3:0] C_A     = 4'b1110;
    localparam [3:0] C_L     = 4'b1111;

    localparam [2:0] ST_IDLE   = 3'b000;
    localparam [2:0] ST_INPUT  = 3'b001;
    localparam [2:0] ST_CHECK  = 3'b010;
    localparam [2:0] ST_UNLOCK = 3'b011;
    localparam [2:0] ST_ALARM  = 3'b100;
    localparam [2:0] ST_CHANGE = 3'b101;

    reg [15:0] masked;

    always @* begin
        masked = {C_BLANK, C_BLANK, C_BLANK, C_BLANK};

        if (input_count >= 3'd1) masked[15:12] = C_STAR;
        if (input_count >= 3'd2) masked[11: 8] = C_STAR;
        if (input_count >= 3'd3) masked[ 7: 4] = C_STAR;
        if (input_count >= 3'd4) masked[ 3: 0] = C_STAR;
    end

    always @* begin
        disp_digits = {C_BLANK, C_BLANK, C_BLANK, C_BLANK};

        case (fsm_state)
            ST_IDLE: begin
                disp_digits = {C_DASH, C_DASH, C_DASH, C_DASH};
            end

            ST_INPUT, ST_CHANGE: begin
                if (mask_enable)
                    disp_digits = masked;
                else
                    disp_digits = digit_data;
            end

            ST_CHECK: begin
                if (blink_tick)
                    disp_digits = {C_STAR, C_STAR, C_STAR, C_STAR};
                else
                    disp_digits = {C_BLANK, C_BLANK, C_BLANK, C_BLANK};
            end

            ST_UNLOCK: begin
                disp_digits = {C_O, C_P, C_E, C_N};
            end

            ST_ALARM: begin
                disp_digits = {C_F, C_A, 4'b0001, C_L};
            end

            default: begin
                disp_digits = {C_BLANK, C_BLANK, C_BLANK, C_BLANK};
            end
        endcase
    end

endmodule
