import os
import shutil

source_dir = 'runtime/avrai_runtime_os/lib/models'
target_dir = 'shared/avrai_core/lib/models'

# Move files!
print("Moving files to avrai_core...")
for item in os.listdir(source_dir):
    src_path = os.path.join(source_dir, item)
    dst_path = os.path.join(target_dir, item)
    if os.path.isdir(src_path):
        if not os.path.exists(dst_path):
            shutil.copytree(src_path, dst_path)
            print(f"Copied directory {item}")
        else:
            # Merge contents
            for root, _, files in os.walk(src_path):
                rel_path = os.path.relpath(root, src_path)
                target_root = os.path.join(dst_path, rel_path)
                os.makedirs(target_root, exist_ok=True)
                for f in files:
                    s_file = os.path.join(root, f)
                    d_file = os.path.join(target_root, f)
                    shutil.copy2(s_file, d_file)
            print(f"Merged directory {item}")
    else:
        # File
        shutil.copy2(src_path, dst_path)
        print(f"Copied file {item}")

# Clean up source directory
shutil.rmtree(source_dir)
print("Removed old models directory")
