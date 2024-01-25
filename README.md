# Project Setup Instructions

Follow these steps to set up the project:

1. **Create a virtual environment**  
   Run the following command to create a new virtual environment in the directory `.venv`:

```bash
python -m venv .venv
```

2. **Activate the virtual environment**
   To activate the virtual environment, use the following command:

```bash
source .venv/bin/activate
```

3. **Install cairo-lang**
   This project requires a modified version of cairo-lang. Install it using the following command:

```bash
pip install --upgrade pip
pip install cairo-lang/cairo-lang-0.12.0
```

4. **Run the project**
   After setting up the environment and installing the required packages, you can run the project with:

```bash
./run.sh
```
