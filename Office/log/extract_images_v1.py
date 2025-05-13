import zipfile
import os
import shutil

def extract_images_from_xlsx(xlsx_path, output_folder):
    temp_dir = "temp_extract"
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)
    os.mkdir(temp_dir)

    with zipfile.ZipFile(xlsx_path, 'r') as zip_ref:
        zip_ref.extractall(temp_dir)

    media_dir = os.path.join(temp_dir, 'xl', 'media')
    if not os.path.exists(media_dir):
        print("没有找到任何图片。")
        return

    for i, filename in enumerate(os.listdir(media_dir)):
        src = os.path.join(media_dir, filename)
        dst = os.path.join(output_folder, f'图片_{i+1}.png')
        shutil.copyfile(src, dst)

    shutil.rmtree(temp_dir)
    print("导出完成。")

# 使用方法
extract_images_from_xlsx("1.xlsx", "./导出图片")
