# shred 待办

文件系统范围：先做 ext4，再 NTFS、FAT32。

## ext4

1. **内容覆盖删除** — `shred_folder.sh` 已在本目录；与下面两项的分工写进用法说明即可。
2. **残留检查**（下一步）
   - 先修 `ext4-find-history.sh`（转义、正则、挂载态读设备）
   - 用户自选：目录项/文件名、文件内容、或两者；默认偏目录项/文件名
3. **目录与日志整理** — 收口 `ext4-wipe-online.sh` / `ext4-wipe-offline.sh`：表述降调；offline 重建 journal + `e2fsck -D`；online 标明能力边界；用残留检查脚本做前后对比
4. **统一入口与说明** — 三种用法、是否需卸载、和 `shred_folder.sh` 的先后顺序、自检步骤

## 之后

5. **NTFS** — 内容覆盖删除；MFT/文件名残留检查；对应整理脚本（写明 MFT/日志能力边界）
6. **FAT32** — 同上：内容、目录项/FAT 残留检查、整理（短名/长名、簇残留）

## 建议顺序

修 find → 补自选检查项 → 收口两个 wipe → 写用法 → NTFS / FAT32
