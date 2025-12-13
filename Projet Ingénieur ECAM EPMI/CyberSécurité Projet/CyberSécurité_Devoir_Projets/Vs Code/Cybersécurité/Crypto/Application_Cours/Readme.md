# Python Virtual Environment Setup

This repository contains a Python project that requires a virtual environment for isolation and dependency management.

## Creating a Python Virtual Environment

1. Open a terminal or command prompt in the project directory.
2. Run the following command to create a virtual environment named `myvenv`:

    ```bash
    python -m venv cyber_venv
    ```

    (Note: If you have multiple Python versions installed, use `python3` instead of `python`.)

3. Activate the virtual environment:

    - On Windows:

        ```bash
        .\myvenv\Scripts\activate
        ```

    - On macOS and Linux:

        ```bash
        source myvenv/bin/activate
        ```

    After activation, your command prompt or terminal prompt should change, indicating that the virtual environment is active.

## Installing Dependencies

1. Ensure your virtual environment is active.
2. Run the following command to install the project dependencies from the `requirements.txt` file:

    ```bash
    pip install -r requirements.txt
    ```

    This command installs the specified packages and their dependencies.

## Deactivating the Virtual Environment

When you're done working on the project, deactivate the virtual environment:

```bash
deactivate
```