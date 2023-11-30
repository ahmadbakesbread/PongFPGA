`timescale 1ns / 1ps
module Pong(
    input wire clk,  // MAX10_CLK1_50

    output wire VGA_HS,
    output wire VGA_VS,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B,

    input wire [9:0] SW,
    output wire [6:0] HEX5,
    output wire [6:0] HEX4,
    output wire [6:0] HEX1,
    output wire [6:0] HEX0
);

    // Constants
    parameter ballSize = 16;
    parameter paletHeight = 128;
    parameter paletWidth = 16;

    // Colors
    parameter ballColor = 12'hC3F;    // RGB: 4 bits each
    parameter lPaletColor = 12'h4BF;  // Left paddle color
    parameter rPaletColor = 12'hF44;  // Right paddle color
    parameter backgroundColor = 12'hFFF;  // Background color

    // VGA signals
    wire [9:0] VGA_x, VGA_y;
    wire pixel;
    reg [11:0] color;

    // Paddle and Ball positions
    reg [9:0] lPalet = 0;  // Left paddle position
    reg [9:0] rPalet = 0;  // Right paddle position
    reg [9:0] ball_x = 20; // Ball position X
    reg [9:0] ball_y = 300;// Ball position Y

    // Game logic signals
    reg [1:0] ballDir = 2'b00; // Ball direction (00: right-up, 01: right-down, 10: left-up, 11: left-down)
    reg [19:0] gameTickCounter = 0;
    wire gameTick;
    reg [3:0] lScore = 0;    // Left score
    reg [3:0] rScore = 0;    // Right score

    // Assign gameTick (100 Hz)
    assign gameTick = (gameTickCounter == 500000); // Assuming 50 MHz clock

    // VGA instantiation
    VGA vga_inst (
        .clk(clk),
        .HS(VGA_HS),
        .VS(VGA_VS),
        .RGB_in(color),
        .R_out(VGA_R),
        .G_out(VGA_G),
        .B_out(VGA_B),
        .pixel(pixel),
        .x(VGA_x),
        .y(VGA_y)
    );

    // Display (7-segment) instantiation
    display display_inst (
        .seg0(rScore),
        .seg1(4'b0000),
        .seg2(4'b0000),
        .seg3(4'b0000),
        .seg4(4'b0000),
        .seg5(lScore),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .HEX2(HEX2),
        .HEX3(HEX3),
        .HEX4(HEX4),
        .HEX5(HEX5)
    );

    // Game tick counter
    always @(posedge clk) begin
        if (gameTickCounter >= 500000)
            gameTickCounter <= 0;
        else
            gameTickCounter <= gameTickCounter + 1;
    end

    // Paddle movement logic
    always @(posedge gameTick) begin
        if (SW[9]) begin // Move left paddle up
            if (lPalet > 0)
                lPalet <= lPalet - 1;
        end else begin // Move left paddle down
            if (lPalet < 480 - paletHeight)
                lPalet <= lPalet + 1;
        end

        if (SW[0]) begin // Move right paddle up
            if (rPalet > 0)
                rPalet <= rPalet - 1;
        end else begin // Move right paddle down
            if (rPalet < 480 - paletHeight)
                rPalet <= rPalet + 1;
        end
    end

    // Ball movement logic
    always @(posedge gameTick) begin
        // Update ball position based on direction
        case (ballDir)
            2'b00: begin // Right-Up
                ball_x <= ball_x + 1;
                ball_y <= ball_y - 1;
            end
            2'b01: begin // Right-Down
                ball_x <= ball_x + 1;
                ball_y <= ball_y + 1;
            end
            2'b10: begin // Left-Up
                ball_x <= ball_x - 1;
                ball_y <= ball_y - 1;
            end
            2'b11: begin // Left-Down
                ball_x <= ball_x - 1;
                ball_y <= ball_y + 1;
            end
        endcase

        // Collision detection with walls
        if (ball_y <= 0 || ball_y >= 480 - ballSize)
            ballDir[0] <= ~ballDir[0]; // Invert Y direction

        // Collision detection with paddles
        if (ball_x <= paletWidth && (ball_y >= lPalet && ball_y <= lPalet + paletHeight) ||
            ball_x >= 640 - paletWidth - ballSize && (ball_y >= rPalet && ball_y <= rPalet + paletHeight))
            ballDir[1] <= ~ballDir[1]; // Invert X direction

        // Scoring logic
        if (ball_x <= 0) begin
            rScore <= rScore + 1;
            ball_x <= 320;
            ball_y <= 240;
            ballDir <= 2'b00; // Reset to right-up
        end

        if (ball_x >= 640 - ballSize) begin
            lScore <= lScore + 1;
            ball_x <= 320;
            ball_y <= 240;
            ballDir <= 2'b10; // Reset to left-up
        end
    end

    // Pixel rendering logic
    always @(*) begin
        if ((VGA_x >= ball_x) && (VGA_x < ball_x + ballSize) && (VGA_y >= ball_y) && (VGA_y < ball_y + ballSize)) begin
            color = ballColor;
        end else if ((VGA_x <= paletWidth) && (VGA_y >= lPalet) && (VGA_y <= lPalet + paletHeight)) begin
            color = lPaletColor;
        end else if ((VGA_x >= 640 - paletWidth) && (VGA_y >= rPalet) && (VGA_y <= rPalet + paletHeight)) begin
            color = rPaletColor;
        end else begin
            color = backgroundColor;
        end
    end

endmodule
