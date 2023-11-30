`timescale 1ns / 1ps
module VGA(
    input wire clk,
    output reg HS,
    output reg VS,
    input wire [11:0] RGB_in, // RGB in hex. 4 bits = R, 4 bits = G, 4 bits = B
    output reg [3:0] R_out,
    output reg [3:0] G_out,
    output reg [3:0] B_out,
    input wire pixel,
    output reg [9:0] x,
    output reg [9:0] y
);

    reg [9:0] hsync_counter = 0; // Horizontal sync counter (lines)
    reg [9:0] vsync_counter = 0; // Vertical sync counter (frames)
    reg H_VIDEO;
    reg V_VIDEO;

    // Horizontal synchronization per line
    always @(posedge clk) begin
        if (hsync_counter == 799)
            hsync_counter <= 0;
        else
            hsync_counter <= hsync_counter + 1;

        case (hsync_counter)
            0: HS <= 1;
            703: HS <= 0;
        endcase

        if (hsync_counter >= 44 && hsync_counter < 684) begin
            H_VIDEO <= 1;
            x <= hsync_counter - 44;
        end else begin
            H_VIDEO <= 0;
            x <= 0;
        end
    end

    // Vertical synchronization per frame
    always @(posedge HS) begin
        if (vsync_counter == 525)
            vsync_counter <= 0;
        else
            vsync_counter <= vsync_counter + 1;

        case (vsync_counter)
            0: VS <= 1;
            522: VS <= 0;
        endcase

        if (vsync_counter >= 30 && vsync_counter < 510) begin
            V_VIDEO <= 1;
            y <= vsync_counter - 30;
        end else begin
            V_VIDEO <= 0;
            y <= 0;
        end
    end

    // Changing color values
    always @(posedge clk) begin
        if (V_VIDEO == 1 && H_VIDEO == 1) begin
            if (pixel == 1) begin // Display white
                R_out <= 15;
                G_out <= 15;
                B_out <= 15;
            end else begin // Display given color in hex
                R_out <= RGB_in[11:8];
                G_out <= RGB_in[7:4];
                B_out <= RGB_in[3:0];
            end
        end else begin // Do not display anything
            R_out <= 0;
            G_out <= 0;
            B_out <= 0;
        end
    end
endmodule
