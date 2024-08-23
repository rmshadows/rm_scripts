#!/usr/bin/python3
# 脚本：考评文件随机命名
import os
import random
import string

import m_System


def generate_random_string(length=8):
    """生成指定长度的随机字符串"""
    letters = string.ascii_letters + string.digits
    return ''.join(random.choice(letters) for _ in range(length))


if __name__ == '__main__':
    dirn = "output"
    # 新建输出文件夹
    if not os.path.exists(dirn):
        os.mkdir(dirn)
    # 找图片文件
    pics_relpath = []
    for extn in ["png", "jpg", "jpeg"]:
        for f in m_System.getSuffixFile(extn):
            # ./xx1镇xx2村/9拆除搭盖钢棚/9.3-0.5IMG_20240703_102233.jpg
            pics_relpath.append(f)
    # 记录对应关系
    flog = []
    for pic in pics_relpath:
        rdn = generate_random_string(25)
        fext = m_System.splitFileNameAndExt(pic)[2]
        nfp = os.path.join(dirn, f"{rdn}{fext}")
        print(f"{pic} -> {nfp}")
        flog.append(f"{pic}\t{nfp}")
        m_System.copyFD(pic, nfp)
    # 输出日志
    m_System.write_to_file("mapping.txt", flog)
