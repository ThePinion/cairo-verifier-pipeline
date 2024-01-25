#!/usr/bin/env bash

echo -e "\e[34mStarting the script...\e[0m"

echo -e "\e[34mBuilding Docker image...\e[0m"
docker build --tag prover ./stone-prover
echo -e "\e[34mDocker image built successfully.\e[0m"
read -p "Press enter to continue"

echo -e "\e[34mCreating Docker container...\e[0m"
container_id=$(docker create prover)
echo -e "\e[34mDocker container created with ID: $container_id\e[0m"

echo -e "\e[34mCopying cpu_air_prover from Docker container to local resources...\e[0m"
docker cp -L ${container_id}:/bin/cpu_air_prover ./resources/
echo -e "\e[34mCopy completed for cpu_air_prover.\e[0m"

echo -e "\e[34mCopying cpu_air_verifier from Docker container to local resources...\e[0m"
docker cp -L ${container_id}:/bin/cpu_air_verifier ./resources/
echo -e "\e[34mCopy completed for cpu_air_verifier.\e[0m"
read -p "Press enter to continue"

source .venv/bin/activate
pip install --upgrade pip
pip install cairo-lang/cairo-lang-0.12.0

echo -e "\e[34mChanging directory to resources...\e[0m"
cd ./resources

echo -e "\e[34mCompiling Cairo program...\e[0m"
cairo-compile main.cairo --output main_compiled.json --proof_mode
echo -e "\e[34mCairo program compiled.\e[0m"

echo -e "\e[34mRunning Cairo program...\e[0m"
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
echo -e "\e[34mCairo program run completed.\e[0m"

echo -e "\e[34mRunning cpu_air_prover...\e[0m"
./cpu_air_prover \
    --out_file=main_proof.json \
    --private_input_file=main_private_input.json \
    --public_input_file=main_public_input.json \
    --prover_config_file=cpu_air_prover_config.json \
    --parameter_file=cpu_air_params.json \
    -generate_annotations
echo -e "\e[34mcpu_air_prover execution completed.\e[0m"

echo -e "\e[34mChanging directory back to parent...\e[0m"
cd ..
deactivate
read -p "Press enter to continue"

echo -e "\e[34mChanging directory to cairo-lang...\e[0m"
cd cairo-lang
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo -e "\e[34mRunning python script...\e[0m"
python src/main.py -l recursive < ../resources/main_proof.json > ../resources/proof.txt
echo -e "\e[34mPython script execution completed.\e[0m"

echo -e "\e[34mChanging directory back to parent...\e[0m"
deactivate
cd ..
read -p "Press enter to continue"

echo -e "\e[34mChanging directory to cairo-verifier...\e[0m"
cd cairo-verifier

echo -e "\e[34mBuilding and running cargo...\e[0m"
scarb build && \
cargo run --release -- ./target/dev/cairo_verifier.sierra.json < ../resources/proof.txt
if [ $? -eq 0 ]
then
  echo -e "\e[34mSuccessfully verified proof.\e[0m"
else
  echo -e "\e[34mFailed to verify proof.\e[0m"
fi
read -p "Press enter to continue"

echo -e "\e[34mChanging directory back to parent...\e[0m"
cd ..

echo -e "\e[34mScript execution completed.\e[0m"
