import os
import sys


def rename_dirs_and_files(root_path, name):
    for dirpath, dirnames, filenames in os.walk(root_path, topdown=True):
        # Skip .git directory
        if ".git" in dirnames:
            dirnames.remove(".git")

        # Rename files
        for filename in filenames:
            if "plugin-name" in filename:
                new_filename = filename.replace("plugin-name", name)
                os.rename(
                    os.path.join(dirpath, filename), os.path.join(dirpath, new_filename)
                )
                print(f"Renamed file: {filename} -> {new_filename}")

        # Rename directories
        for dirname in dirnames:
            if "plugin-name" in dirname:
                new_dirname = dirname.replace("plugin-name", name)
                old_dirpath = os.path.join(dirpath, dirname)
                new_dirpath = os.path.join(dirpath, new_dirname)
                os.rename(old_dirpath, new_dirpath)
                print(f"Renamed directory: {dirname} -> {new_dirname}")


def replace_in_files(root_path, name):
    for dirpath, dirnames, filenames in os.walk(root_path):
        # Skip .git directory
        if ".git" in dirnames:
            dirnames.remove(".git")

        for filename in filenames:
            filepath = os.path.join(dirpath, filename)
            if filepath == os.path.realpath(__file__):
                continue  # Skip the script file
            # Read the file content and replace
            with open(filepath, "r", encoding="utf-8", errors="ignore") as file:
                content = file.read()
                new_content = content.replace("plugin-name", name).replace(
                    "plugin_name", name.replace("-", "_")
                )
            # Write the modified content back
            with open(filepath, "w", encoding="utf-8", errors="ignore") as file:
                file.write(new_content)


# Get the directory of the script and use it as the root path
if __name__ == "__main__":
    root_path = os.path.dirname(os.path.realpath(__file__))

    rename_dirs_and_files(root_path, sys.argv[1])
    replace_in_files(root_path, sys.argv[1])
