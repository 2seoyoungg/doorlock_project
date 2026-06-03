// fnd_team_adapter.v (ASCII-only, comments removed for old Quartus)
// Wraps fnd_driver for the team FSM. Logic unchanged from original.
 
module fnd_team_adapter (
 
input wire clk,
input wire rst,
input wire [2:0] state,
input wire [3:0] input_count_led,
 
output wire [7:0] fnd_seg,
output wire [3:0] fnd_com
);
 
wire reset_n_int = ~rst;
 
wire [2:0] input_count_int =
{2'b00, input_count_led[0]}
+ {2'b00, input_count_led[1]}
+ {2'b00, input_count_led[2]}
+ {2'b00, input_count_led[3]};
 
fnd_driver #(
.SCAN_DIV (1),
.BLINK_DIV (100)
) U_FND (
.clk (clk),
.reset_n (reset_n_int),
.fsm_state (state),
.mask_enable (1'b1),
.input_count (input_count_int),
.digit_data (16'h0000),
.fnd_seg (fnd_seg),
.fnd_com (fnd_com)
);
 
endmodule
