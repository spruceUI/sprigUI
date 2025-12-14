import json
import sys

def merge_selected(old, new, path=""):
    """
    Recursively copy 'selected' values from old into new.
    Logs every update.
    """
    if isinstance(old, dict) and isinstance(new, dict):
        for key in old:
            old_val = old[key]
            new_val = new.get(key)

            current_path = f"{path}/{key}" if path else key

            if key == "selected" and old_val is not None:
                values = new.get("options")
                if isinstance(values, list) and old_val in values:
                    print(f"Copying '{current_path}': {new_val} -> {old_val}")
                    new[key] = old_val
                else:
                    print(f"Skipping invalid '{current_path}': {old_val}")

def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <existing_config> <new_config>")
        sys.exit(1)

    existing_config = sys.argv[1]
    new_config = sys.argv[2]

    # Load JSON files
    with open(existing_config, "r", encoding="utf-8") as f:
        old_json = json.load(f)

    with open(new_config, "r", encoding="utf-8") as f:
        new_json = json.load(f)

    # Merge selected values
    merge_selected(old_json, new_json)

    # Write merged result back into new_config
    with open(new_config, "w", encoding="utf-8") as f:
        json.dump(new_json, f, indent=4)

    print(f"Merged selected values written to {new_config}")

if __name__ == "__main__":
    main()
