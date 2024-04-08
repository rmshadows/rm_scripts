#!/usr/bin/python3
import os

def execCommand(cmd, mode=0, debug=False):
    """
    执行命令
    Args:
        cmd: str：命令
        mode: 模式 0默认返回命令行输出:os.popen(cmd).read() 1仅返回执行结果状态:os.system()
        debug: 是否显示运行详情
    Returns:
        执行结果
    """
    r = None
    try:
        if mode == 0:
            r = os.popen(cmd).read()
        elif mode == 1:
            r = os.system(cmd)
        if debug:
            print(r)
    except Exception as e:
        print(e)
    return r


# 去除换行
def remove_newlines(text):
    # 替换Unix和Linux系统的换行符
    text = text.replace('\n', '')
    # 替换Windows系统的换行符
    text = text.replace('\r\n', '')
    # 替换旧版Mac系统的换行符
    text = text.replace('\r', '')
    return text


# 读取文件列表
def readFiles(rfile="1.txt"):
    fileList = []
    with open(rfile, 'r', encoding='utf-8') as f:
        for line in f.readlines():
            line = remove_newlines(line)
            if line == "" or line[0:1] == "#"  or line == " ":
                continue
            fileList.append(line)
    return fileList


if __name__ == '__main__':
    dstd = "sresult"
    execCommand("mkdir -p {}".format(dstd))
    # 导入文件列表
    for f in readFiles("1.txt"):
        cmd = "cp \"{}\" \"{}\"".format(f, dstd)
        # print(cmd)
        execCommand(cmd, True)


    


