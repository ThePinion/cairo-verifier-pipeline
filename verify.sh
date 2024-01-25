#!/usr/bin/env bash

# Function to display messages in bold blue
display_message() {
    echo -e "\e[1;34m$1\e[0m"
}

# Start of the specific task
display_message "[INFO] Changing directory to cairo-verifier..."
cd cairo-verifier

# Building and Running Cargo
display_message "[INFO] Building and running cargo..."
scarb build && \
cargo run --release -- ./target/dev/cairo_verifier.sierra.json < ../resources/proof.txt

# Checking the result of the cargo run
if [ $? -eq 0 ]; then
    display_message "[SUCCESS] Successfully verified proof."
else
    display_message "[ERROR] Failed to verify proof."
    exit 1
fi

# Returning to the previous directory
display_message "[INFO] Changing directory back to parent..."
cd ..
