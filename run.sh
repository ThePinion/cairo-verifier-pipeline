#!/usr/bin/env bash

echo "Building Docker image..."
docker build --tag prover ./stone-prover
read -p "Press enter to continue"

echo "Creating Docker container..."
container_id=$(docker create prover)
echo "Copying cpu_air_prover from Docker container to local resources..."
docker cp -L ${container_id}:/bin/cpu_air_prover ./resources/
echo "Copying cpu_air_verifier from Docker container to local resources..."
docker cp -L ${container_id}:/bin/cpu_air_verifier ./resources/
read -p "Press enter to continue"

cd ./resources
cairo-compile main.cairo --output main_compiled.json --proof_mode
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
./cpu_air_prover \
    --out_file=main_proof.json \
    --private_input_file=main_private_input.json \
    --public_input_file=main_public_input.json \
    --prover_config_file=cpu_air_prover_config.json \
    --parameter_file=cpu_air_params.json \
    -generate_annotations
read -p "Press enter to continue"

echo "Changing directory to cairo-lang..."
cd cairo-lang
echo "Running python script..."
python src/main.py -l recursive < ../resources/main_proof.json > ../resources/proof.txt
echo "Changing directory back to parent..."
cd ..
read -p "Press enter to continue"

echo "Changing directory to cairo-verifier..."
cd cairo-verifier
echo "Building and running cargo..."
scarb build && \
cargo run --release -- ./target/dev/cairo_verifier.sierra.json < ../resources/proof.txt
if [ $? -eq 0 ]
then
  echo "Successfully verified proof."
else
  echo "Failed to verify proof."
fi
read -p "Press enter to continue"
echo "Changing directory back to parent..."
cd ..

echo "Script execution completed."
