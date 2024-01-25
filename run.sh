#!/usr/bin/env bash

docker build --tag prover ./stone-prover

container_id=$(docker create prover)
docker cp -L ${container_id}:/bin/cpu_air_prover ./resources/
docker cp -L ${container_id}:/bin/cpu_air_verifier ./resources/

cd cairo-lang
python src/main.py -l recursive < ../resources/main_proof.json > ../resources/proof.txt
cd ..

cd cairo-verifier
scarb build && \
cargo run --release -- ./target/dev/cairo_verifier.sierra.json < ../resources/proof.txt
cd ..
