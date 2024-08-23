import os
import shutil


def restore_files(mapping_file):
    with open(mapping_file, 'r', encoding='utf-8') as file:
        for line in file:
            # 去除每行两端的空白字符并跳过空行
            line = line.strip()
            if not line:
                continue

            # 分割原路径和目标路径
            original_path, renamed_path = line.split()
            
            # 检查目标路径文件是否存在
            if os.path.exists(renamed_path):
                # 创建原路径的目录结构
                original_dir = os.path.dirname(original_path)
                if not os.path.exists(original_dir):
                    os.makedirs(original_dir)

                # 复制文件到原路径
                # shutil.move(renamed_path, original_path)
                shutil.copy(renamed_path, original_path)
                print(f"文件已还原: {renamed_path} -> {original_path}")
            else:
                print(f"目标文件不存在: {renamed_path}")


if __name__ == "__main__":
    mapping_file = "mapping.txt"  # 替换为你的映射文件路径
    restore_files(mapping_file)

