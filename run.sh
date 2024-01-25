#!/usr/bin/env bash

docker build --tag prover ./stone-prover

container_id=$(docker create prover)
docker cp -L ${container_id}:/bin/cpu_air_prover ./stone-prover/e2e_test/
docker cp -L ${container_id}:/bin/cpu_air_verifier ./stone-prover/e2e_test/
