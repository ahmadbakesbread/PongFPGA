# 🎮 PongFPGA 🕹️

## Overview
Welcome to PongFPGA! This project brings the nostalgic joy of the classic Pong game into the modern era of hardware programming. Using an FPGA (Field Programmable Gate Array), we've recreated this iconic game, offering both fun and a great learning experience in FPGA and digital design.

## Features
- 🏓 Classic Pong gameplay.
- 📺 VGA output for a retro feel.
- 🎮 Support for two players with paddle control.
- 📊 Score tracking and display on-screen.
- 🧠 FPGA-based logic for real-time game processing.

## Repository Structure
- `Pong.v`: The heart of the game, written in Verilog.
- `PongFPGA.qpf` & `PongFPGA.qsf`: Quartus project files to get you started.
- `devkits/`: Essential development kit designs and setup instructions.
- `output_files/`: Compilation outputs and reports.

## Hardware Requirements
- Intel MAX 10 FPGA (Model: 10M50DAF484C6GES).
- DE10-Lite Development Board for hands-on experience.
- VGA display to bring the game to life.

## Software Requirements
- Quartus Prime (Version 22.1std.2 or later) for FPGA programming.

## Setup and Configuration
1. 📥 Clone the repository.
2. 🛠 Open `PongFPGA.qpf` with Quartus Prime.
3. 🔧 Follow the setup instructions in `devkits/readme.txt`.
4. 🚀 Compile and upload to your FPGA board.

## Let's Play!
- Connect your FPGA board to a VGA display.
- Grab a friend and use the switches to control your paddles.
- Enjoy the game as it unfolds on your screen!

## Contributing
Got ideas to make PongFPGA even better? Contributions are welcome! Check out our contributing guidelines for more information.

## License
This project is licensed under the Intel Program License Subscription Agreement. See the license file for details.
