#!/usr/bin/env python3

import os
import getpass

# list of environment variables to check
ENV_VARS = ["WWW_CLOUDFRONT_ID", "WWW_S3_BUCKET_NAME",
            "ROOT_CLOUDFRONT_ID", "ROOT_S3_BUCKET_NAME",
            "STAGE_CLOUDFRONT_ID", "STAGE_S3_BUCKET_NAME"]

def determine_rc_file():
    """
    Determine the operating system and select the appropriate shell rc file.
    """
    user_shell = os.environ.get('SHELL', '')

    # Default rc file based on shell type
    if 'bash' in user_shell:
        rc_file = "~/.bashrc"
    elif 'zsh' in user_shell:
        rc_file = "~/.zshrc"
    else:
        print("Unsupported shell, script currently supports bash and zsh shells.")
        exit(1)

    return os.path.expanduser(rc_file)

def check_and_set_env_var(var_name, rc_file):
    """
    Check if an environment variable is set and not null.
    If not set, prompts user to set it. If already set, asks user if they want to reset it.
    """
    value = os.getenv(var_name)

    # Print the current value
    if value is None:
        value = "<undefined>"

    print(f"| {var_name:<24} | {value:<24} |")

    return value

def update_env_var(var_name, rc_file):
    """
    Update the value of an environment variable
    """
    new_val = getpass.getpass(prompt=f"Enter the new value for {var_name}: ")
    with open(rc_file, 'a') as f:
        f.write(f"\nexport {var_name}=\"{new_val}\"\n")
    os.environ[var_name] = new_val
    print(f"{var_name} has been updated!\n")

def main():
    # Determine the rc file
    rc_file = determine_rc_file()

    print(f"\n{'Environment Variables Configuration':^64}\n")
    print("| Entry | Name                      | Current Value              |")
    print("|-------|---------------------------|----------------------------|")

    # Check and set environment variables
    undefined_vars = []
    for i, var in enumerate(ENV_VARS, start=1):
        print(f"| {i:<5}", end="")
        value = check_and_set_env_var(var, rc_file)
        if value == "<undefined>":
            undefined_vars.append(var)

    # Prompt for undefined variables
    for var in undefined_vars:
        print(f"\nThe variable {var} is not set.")
        update_env_var(var, rc_file)

    # Redefine variables if user wishes
    while True:
        var_num = input("\nEnter the entry number of the variable you want to redefine (or 'q' to quit): ").strip().lower()
        if var_num == 'q':
            break

        if var_num.isdigit() and 1 <= int(var_num) <= len(ENV_VARS):
            update_env_var(ENV_VARS[int(var_num) - 1], rc_file)
        else:
            print("Invalid input. Please enter a valid entry number.")

    print("\nConfiguration completed. Please restart your shell or source your rc file to reflect the changes.\n")

if __name__ == "__main__":
    main()
