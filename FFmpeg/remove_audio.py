import os
import fnmatch
import subprocess

# 使用示例
# 替换为你的目录路径
directory = '.'

def find_video_files(directory, extensions=None):
    if extensions is None:
        extensions = ['*.mp4', '*.avi', '*.mov', '*.mkv', '*.flv', '*.wmv']
    video_files = []
    for root, dirs, files in os.walk(directory):
        for extension in extensions:
            for filename in fnmatch.filter(files, extension):
                video_files.append(os.path.join(root, filename))
    return video_files

def remove_audio_from_video(input_file, output_file):
    command = [
        'ffmpeg',
        '-i', input_file,
        '-c:v', 'copy',
        '-an',  # 去掉音轨
        output_file
    ]
    subprocess.run(command, check=True)

video_files = find_video_files(directory)

for video in video_files:
    output_file = f'output-{os.path.basename(video)}'
    output_path = os.path.join(os.path.dirname(video), output_file)
    print(f'Processing: {video} -> {output_path}')
    remove_audio_from_video(video, output_path)
    print(f'Processed: {video} -> {output_path}')

