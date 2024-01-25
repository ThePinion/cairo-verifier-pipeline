#!/usr/bin/env bash

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
cd ..
