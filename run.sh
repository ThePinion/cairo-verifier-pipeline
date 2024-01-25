#!/usr/bin/env bash

# Function to display messages in bold blue
display_message() {
    echo -e "\e[1;34m$1\e[0m"
}

# Start of the script
display_message "[START] Starting the script..."

# Building Docker Image
display_message "[INFO] Building Docker image..."
docker build --tag prover ./stone-prover
if [ $? -eq 0 ]; then
    display_message "[SUCCESS] Docker image built successfully."
else
    display_message "[ERROR] Docker image build failed."
    exit 1
fi
read -p "Press enter to continue"

# Creating Docker Container
display_message "[INFO] Creating Docker container..."
container_id=$(docker create prover)
if [ -z "$container_id" ]; then
    display_message "[ERROR] Docker container creation failed."
    exit 1
else
    display_message "[SUCCESS] Docker container created with ID: $container_id"
fi

# Copying from Docker Container
display_message "[INFO] Copying cpu_air_prover from Docker container to local resources..."
docker cp -L ${container_id}:/bin/cpu_air_prover ./resources/
if [ $? -eq 0 ]; then
    display_message "[SUCCESS] Copy completed for cpu_air_prover."
else
    display_message "[ERROR] Copy failed for cpu_air_prover."
    exit 1
fi

display_message "[INFO] Copying cpu_air_verifier from Docker container to local resources..."
docker cp -L ${container_id}:/bin/cpu_air_verifier ./resources/
if [ $? -eq 0 ]; then
    display_message "[SUCCESS] Copy completed for cpu_air_verifier."
else
    display_message "[ERROR] Copy failed for cpu_air_verifier."
    exit 1
fi
read -p "Press enter to continue"

# Cairo-lang Installation
display_message "[INFO] Activating virtual environment and installing cairo-lang..."
source .venv/bin/activate
pip install --upgrade pip
pip install cairo-lang/cairo-lang-0.12.0

# Compiling and Running Cairo Program
display_message "[INFO] Changing directory to resources..."
cd ./resources

display_message "[INFO] Compiling Cairo program..."
cairo-compile main.cairo --output main_compiled.json --proof_mode
display_message "[SUCCESS] Cairo program compiled."

display_message "[INFO] Running Cairo program..."
cairo-run \
    --program=main_compiled.json \
    --layout=recursive \
    --program_input=main_input.json \
    --air_public_input=main_public_input.json \
    --air_private_input=main_private_input.json \
    --trace_file=main_trace.json \
    --memory_file=main_memory.json \
    --print_output \
    --proof_mode
display_message "[SUCCESS] Cairo program run completed."

display_message "[INFO] Running cpu_air_prover..."
./cpu_air_prover \
    --out_file=main_proof.json \
    --private_input_file=main_private_input.json \
    --public_input_file=main_public_input.json \
    --prover_config_file=cpu_air_prover_config.json \
    --parameter_file=cpu_air_params.json \
    -generate_annotations
display_message "[SUCCESS] cpu_air_prover execution completed."

display_message "[INFO] Changing directory back to parent and deactivating virtual environment..."
cd ..
deactivate
read -p "Press enter to continue"

# Running Python Script in cairo-lang Directory
display_message "[INFO] Changing directory to cairo-lang and running python parser..."
cd cairo-lang
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
python src/main.py -l recursive < ../resources/main_proof.json > ../resources/proof.txt
display_message "[SUCCESS] Python script execution completed."

display_message "[INFO] Changing directory back to parent and deactivating virtual environment..."
deactivate
cd ..
read -p "Press enter to continue"

# Building and Running Cargo in cairo-verifier
display_message "[INFO] Changing directory to cairo-verifier and building cargo..."
cd cairo-verifier
scarb build && \
cargo run --release -- ./target/dev/cairo_verifier.sierra.json < ../resources/proof.txt
if [ $? -eq 0 ]; then
    display_message "[SUCCESS] Successfully verified proof."
else
    display_message "[ERROR] Failed to verify proof."
    exit 1
fi
cd ..

# End of the script
display_message "[END] Script execution completed."
