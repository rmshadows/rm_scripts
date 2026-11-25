#!/usr/bin/env bash
# ==============================================================================
# ext4-find-history
# 用途：只读扫描 ext4 Journal（日志环），提取指定目录历史上存在过的所有文件名
# 用法：sudo ext4-find-history /path/to/target_dir
# ==============================================================================
set -euo pipefail
export PATH="/sbin:/usr/sbin:$PATH"

if [[ $# -lt 1 ]]; then
    echo "用法: sudo $0 <目标目录路径>"
    exit 1
fi

TARGET_DIR=$(realpath "$1")
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "错误: 目标路径不存在或不是目录: $TARGET_DIR"
    exit 1
fi

DEV=$(df -P "$TARGET_DIR" | tail -1 | awk '{print $1}')
FSTYPE=$(df -PT "$TARGET_DIR" | tail -1 | awk '{print $2}')

if [[ "$FSTYPE" != "ext4" && "$FSTYPE" != "ext3" ]]; then
    echo "错误: 该目录所在分区不是 ext4/ext3 文件系统 (当前: $FSTYPE)"
    exit 1
fi

REAL_DEV=$(readlink -f "$DEV")
DIR_INO=$(stat -c %i "$TARGET_DIR")

echo "=================================================="
echo "目标目录: $TARGET_DIR"
echo "块设备  : $REAL_DEV ($DEV)"
echo "目录 Inode: $DIR_INO"
echo "=================================================="

JOURNAL_STAT=$(debugfs -R 'stat <8>' "$REAL_DEV" 2>/dev/null)
if ! echo "$JOURNAL_STAT" | grep -q "Inode: 8"; then
    echo "错误: 无法读取文件系统 Journal (Inode 8)"
    exit 1
fi

EXTENTS_LINE=$(echo "$JOURNAL_STAT" | grep -A 5 "EXTENTS:" | tr -d '
')
FS_BS=$(dumpe2fs -h "$REAL_DEV" 2>/dev/null | grep "^Block size:" | awk '{print $3}')
FS_BS=${FS_BS:-4096}

echo "文件系统块大小: ${FS_BS} 字节"
echo "正在扫描 Journal，请稍候..."

python3 - "$REAL_DEV" "$DIR_INO" "$FS_BS" "$EXTENTS_LINE" << 'EOF'
import sys, struct, re

dev_path   = sys.argv[1]
target_ino = int(sys.argv[2])
bs         = int(sys.argv[3])
extents_str= sys.argv[4]

ranges = []
for m in re.finditer(r'((d+)(?:-(d+))?):(d+)(?:-(d+))?', extents_str):
    s = int(m.group(3))
    e = int(m.group(4)) if m.group(4) else s
    ranges.append((s, e + 1))

if not ranges:
    print("未解析到 Journal 块范围")
    sys.exit(1)

tp = struct.pack('<I', target_ino)
unique_layouts = []
seen_names = set()
timeline = []

def parse_dir_entries(blk):
    res = []
    off = 0
    while off + 8 <= bs:
        ino, rec, nl, ft = struct.unpack('<IHBB', blk[off:off+8])
        if rec < 8 or rec % 4 or off + rec > bs or nl > 255 or ft > 7:
            break
        try:
            name = blk[off+8:off+8+nl].decode('utf-8')
        except Exception:
            break
        res.append((ino, name, ft))
        if rec == 0:
            break
        off += rec
    return res

with open(dev_path, 'rb', buffering=8*1024*1024) as f:
    for start_b, end_b in ranges:
        f.seek(start_b * bs)
        for cur_b in range(start_b, end_b):
            blk = f.read(bs)
            if not blk or len(blk) < bs:
                break
            if tp not in blk:
                continue
            
            entries = parse_dir_entries(blk)
            if not entries:
                continue
            
            if entries[0][0] == target_ino and entries[0][1] == '.':
                names = [e[1] for e in entries if e[1] not in ('.', '..')]
                names_tuple = tuple(names)
                if names_tuple not in unique_layouts:
                    unique_layouts.append(names_tuple)
                    for n in names:
                        if n not in seen_names:
                            seen_names.add(n)
                            timeline.append((cur_b, n))

print("
>>> 【历史出现过的文件名（按首次捕获顺序）】:")
for idx, (b, name) in enumerate(timeline, 1):
    print(f"  {idx:02d}. {name}")

print(f"
>>> 共提取出 {len(timeline)} 个不同文件名/临时文件/锁文件标记。")
EOF
