#!/usr/bin/python3
"""
返回系统配置
"""
import multiprocessing
import os
import shutil
from subprocess import Popen, PIPE
import re
from inputimeout import inputimeout, TimeoutOccurred
from natsort import natsorted

IS_WINDOWS = os.sep == "\\"


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


def checkAdministrator():
    """
    检查是否有管理员权限
    Returns:
        boolean： 有/无
    """
    if IS_WINDOWS:
        admin = execCommand("whoami /groups | find \"S-1-16-12288\" && echo YES_ADMIN")
        # print(admin)
        if "YES_ADMIN" in admin:
            return True
    else:
        if os.getuid() == 0:
            return True
    return False


def cpu_count():
    """
    返回CPU核心数
    Returns:
        int cpu核心数
    """
    return multiprocessing.cpu_count()


def isBomExist(text_file_path):
    """
    检查文件（UTF-8文本文档）头部是否包含有UTF-BOM
    Args:
        text_file_path: UTF-8文本文档路径

    Returns:
        boolean: 是否含有BOM
        True: 有
        False: 无
    """
    BOM = b'\xef\xbb\xbf'
    bomExisted = lambda s: True if s == BOM else False
    with open(text_file_path, 'rb') as r:
        if bomExisted(r.read(3)):
            print("{}: 检测到UTF-BOM...".format(text_file_path))
            return True
        else:
            return False


def getSuffixFile(suffix, directory=".", case_sensitive=True):
    """
    返回文件夹下的带后缀的文件
    使用os模块的walk函数，搜索出指定目录下的全部PDF文件
    获取同一目录下的所有xxx文件的绝对路径
    # https://www.jb51.net/article/216431.htm
    Args:
        suffix: 后缀
        directory: 文件夹名
        case_sensitive: 是否大小写敏感，默认为 True，表示大小写敏感

    Returns:
        列表
    """
    if not case_sensitive:
        suffix = suffix.lower()  # 将后缀转换为小写

    file_list = [os.path.join(root, filespath) \
                 for root, dirs, files in os.walk(directory) \
                 for filespath in files \
                 if (not case_sensitive and str(filespath).lower().endswith(suffix)) or \
                    (case_sensitive and str(filespath).endswith(suffix))  # 判断是否大小写敏感
                 ]
    if file_list:
        sorted_files = natsorted(file_list)
        return sorted_files
    else:
        return []


def removeBom(filepath):
    """
    existBom(f.read(3))
    移除UTF-8文件的BOM字节
    Args:
        filepath: 带有BOM的文本文档路径
    """
    with open(filepath, 'rb') as r:
        # 只有先读取三个字节，接下来的读取才是去掉BOM的内容
        r.read(3)
        if isBomExist(filepath):
            print("正在移除{}的BOM...".format(filepath))
            fbody = r.read()
            print(fbody)
            with open(filepath, 'wb') as f:
                f.write(fbody)


def fdExisted(file_or_dir, expect=0):
    """
    判断文件、目录是否以期待的方式存在
    Args:
        file_or_dir: 路径
        expect: 期待的类型 (0:不做约束 1:文件 2:文件夹)
    Returns:
        不符合期待类型也会返回 False
    """
    if expect not in [0, 1, 2]:
        print("期待值不在0-无限制，1-文件，2-文件夹之间")
        return False
    if expect in [1, 2]:
        if not os.path.exists(file_or_dir):
            # 文件不存在直接返回False
            return False
        else:
            if fileOrDirectory(file_or_dir) != expect:
                return False
        return True
    else:
        return os.path.exists(file_or_dir)


def fileOrDirectory(file_or_dir):
    """
    判断文件还是目录
    Args:
        file_or_dir: 路径

    Returns:
        -1:other (可能不存在)
        1:file
        2:dir
    """
    if os.path.isfile(file_or_dir):
        return 1
    elif os.path.isdir(file_or_dir):
        return 2
    else:
        return -1


def rmFD(file_or_dir, expect=0):
    """
    删除文件
    Args:
        file_or_dir: 路径
        expect: 期待类型： 1:文件 2:文件夹

    Returns:
        成功否
    """
    if expect not in [0, 1, 2]:
        print("期待值不在0-无限制，1-文件，2-文件夹之间")
        return False
    if not fdExisted(file_or_dir, expect):
        print("文件或文件夹不存在/与期待类型不符合：{}".format(file_or_dir))
        return False
    ftpye = fileOrDirectory(file_or_dir)
    if ftpye == 1:
        print("删除文件：{}".format(file_or_dir))
        os.remove(file_or_dir)
    elif ftpye == 2:
        print("删除文件夹：{}".format(file_or_dir))
        shutil.rmtree(file_or_dir)
    else:
        return False
    return True


def copyFD(src, dst):
    """
    复制文件或者文件夹 不会覆盖！
    Args:
        src:
        dst:

    Returns:

    """
    if not fdExisted(src):
        print("文件或文件夹不存在：{}".format(src))
        return False
    ftpye = fileOrDirectory(src)
    if ftpye == 1:
        print("复制文件 {} 到 {}".format(src, dst))
        shutil.copy(src, dst)
    elif ftpye == 2:
        print("复制文件夹 {} 到 {}".format(src, dst))
        shutil.copytree(src, dst)
    else:
        return False
    return True


def moveFD(src, dst):
    """
    移动文件或者文件夹
    Args:
        src:
        dst:

    Returns:

    """
    if not fdExisted(src):
        print("文件或文件夹不存在：{}".format(src))
        return False
    print("移动 {} 到 {}".format(src, dst))
    shutil.move(src, dst)
    return True


def renameFile(src, dst, copyFile=False, prefix=None, suffix=None, dstWithExt=False, ext=None):
    """
    重命名文件（可复制）
    Args:
        src:源文件
        dst:目标名称（可以不带扩展名，如果带扩展名请修改dstWithExt）
        copyFile:是否复制文件，默认否
        prefix:前缀
        suffix:后缀
        dstWithExt:目标名称是否带有扩展名，默认没有
        ext:指定扩展名

    Returns:
        返回结果
    """
    # 组合新文件名
    new_file_name = editFilename(src, dst, prefix, suffix, dstWithExt, ext)
    if copyFile:
        return copyFD(src, new_file_name)
    else:
        return moveFD(src, new_file_name)


def editFilename(src, dst, prefix=None, suffix=None, dstWithExt=False, ext=None):
    """
    编辑文件名，返回新的文件名
    Args:
        src:源文件
        dst:目标名称（可以不带扩展名，如果带扩展名请修改dstWithExt）
        prefix:前缀
        suffix:后缀
        dstWithExt:目标名称是否带有扩展名，默认没有
        ext:指定扩展名

    Returns:
        返回结果, 新文件的名称
    """
    # 获取文件夹名， 文件名和扩展名
    src_dir, src_name, src_ext = splitFilePath(src)
    if dstWithExt:
        # 如果带扩展名
        if dst is None:
            # 如果dst是None,则使用原文件名
            dst_dir, dst_name, dst_ext = src_dir, src_name, src_ext
        else:
            dst_dir, dst_name, dst_ext = splitFilePath(dst)
    else:
        # 不带扩展名
        if dst is None:
            # 如果dst是None,则使用原文件名
            dst_dir = src_dir
            dst_name = src_name
            dst_ext = src_ext
        else:
            # 不带扩展名，那扩展名沿用
            dst_dir, dst_name, dst_ext = splitFilePath(dst)
            dst_ext = src_ext
    # 处理前缀和后缀
    if prefix:
        dst_name = prefix + dst_name
    if suffix:
        dst_name += suffix
    # 处理扩展名
    if ext:
        dst_ext = ext if ext.startswith('.') else '.' + ext
    # 组合新文件名
    return os.path.join(dst_dir, "{}{}".format(dst_name, dst_ext))


def splitFileNameAndExt(file_path):
    """
    给定路径分离出文件夹、文件名、扩展名
    Args:
        file_path:

    Returns:
        如果是文件夹返回None
    """
    file_path = os.path.abspath(file_path)
    if not os.path.isdir(file_path):
        # 获取所在文件夹路径、文件名和扩展名
        folder_path, file_name_ext = os.path.split(file_path)
        # 分离文件名和扩展名
        file_name, file_ext = os.path.splitext(file_name_ext)
        # print(f"{file_path} => 目录：[{folder_path}] 文件名：[{file_name}] 扩展名：[{file_ext}]")
        return folder_path, file_name, file_ext
    else:
        return None


def splitFilePath(file_path):
    """
    给定路径分离出文件夹、文件名、扩展名
    如果是文件夹，返回上级文件夹的绝对路径、上级文件夹名称和当前文件夹名称
    Args:
        file_path: 绝对路径

    Returns:
        tuple: (folder_path, file_name, file_ext) 如果是文件
        tuple: (parent_folder_path, parent_folder_name, current_folder_name) 如果是文件夹
    """
    file_path = os.path.abspath(file_path)
    if not os.path.isdir(file_path):
        # 获取所在文件夹路径、文件名和扩展名
        folder_path, file_name_ext = os.path.split(file_path)
        # 分离文件名和扩展名
        file_name, file_ext = os.path.splitext(file_name_ext)
        return folder_path, file_name, file_ext
    else:
        # 获取当前文件夹的名称
        current_folder_name = os.path.basename(file_path)
        # 获取上级文件夹路径
        parent_folder_path = os.path.dirname(file_path)
        # 获取上级文件夹的名称
        parent_folder_name = os.path.basename(parent_folder_path)
        return parent_folder_path, parent_folder_name, current_folder_name


def displaySystemInfo():
    """
    打印系统信息
    Returns:
        None
    """
    # 非Windows系统请注释掉
    # import wmi
    import socket
    if IS_WINDOWS:
        # 非Windows系统请注释掉
        import wmi
        w = wmi.WMI()
        # 获取电脑使用者信息
        for CS in w.Win32_ComputerSystem():
            # print(CS)
            try:
                print("电脑名称: %s" % CS.Caption)
                print("使用者: %s" % CS.UserName)
                print("制造商: %s" % CS.Manufacturer)
                print("系统信息: %s" % CS.SystemFamily)
                print("工作组: %s" % CS.Workgroup)
                print("机器型号: %s" % CS.model)
            except Exception as e:
                print(e)
            print("")
        # 获取操作系统信息
        for OS in w.Win32_OperatingSystem():
            # print(OS)
            print("操作系统: %s" % OS.Caption)
            print("语言版本: %s" % OS.MUILanguages)
            print("系统位数: %s" % OS.OSArchitecture)
            print("注册人: %s" % OS.RegisteredUser)
            print("系统驱动: %s" % OS.SystemDevice)
            print("系统目录: %s" % OS.SystemDirectory)
            print("")
        # 获取电脑IP和MAC信息
        for address in w.Win32_NetworkAdapterConfiguration(ServiceName="e1dexpress"):
            # print(address)
            print("IP地址: %s" % address.IPAddress)
            print("MAC地址: %s" % address.MACAddress)
            print("网络描述: %s" % address.Description)
            print("")
        # 获取电脑CPU信息
        for processor in w.Win32_Processor():
            # print(processor)
            print("CPU型号: %s" % processor.Name.strip())
            print("CPU核数: %s" % processor.NumberOfCores)
            print("")
        # 获取BIOS信息
        for BIOS in w.Win32_BIOS():
            # print(BIOS)
            print("使用日期: %s" % BIOS.Description)
            print("主板型号: %s" % BIOS.SerialNumber)
            print("当前语言: %s" % BIOS.CurrentLanguage)
            print("")
        # 获取内存信息
        for memModule in w.Win32_PhysicalMemory():
            totalMemSize = int(memModule.Capacity)
            print("内存厂商: %s" % memModule.Manufacturer)
            print("内存型号: %s" % memModule.PartNumber)
            print("内存大小: %.2fGB" % (totalMemSize / 1024 ** 3))
            print("")
        # 获取磁盘信息
        for disk in w.Win32_DiskDrive():
            diskSize = int(disk.size)
            print("磁盘名称: %s" % disk.Caption)
            print("硬盘型号: %s" % disk.Model)
            print("磁盘大小: %.2fGB" % (diskSize / 1024 ** 3))
        # 获取显卡信息
        for xk in w.Win32_VideoController():
            print("显卡名称: %s" % xk.name)
            print("")
        # 获取计算机名称和IP
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
        print("计算机名称: %s" % hostname)
        print("IP地址: %s" % ip)
    else:
        # 获取主机名,也可以使用 uname -n 命令获取
        hostname = Popen(["hostname"], stdout=PIPE)
        hostname = hostname.stdout.read().decode().strip()
        print("%s: %s" % ("主机名", hostname))
        # 获取操作系统版本
        RELEASE_FILE = execCommand("ls /etc/*-release").replace("\n", "")
        with open(RELEASE_FILE) as f:
            osversion = f.read().strip()
        print("%s:\n%s\n" % ("系统版本", osversion))
        # 获取操作系统内核版本
        oscoreversion = Popen(["uname", "-r"], stdout=PIPE)
        oscoreversion = oscoreversion.stdout.read().decode().strip()
        print("%s: %s" % ("系统内核版本", oscoreversion))
        # 获取CPU相关信息,如果存在多种不同CPU，那么CPU型号统计的为最后一种型号,这种情况少见
        corenumber = []
        with open("/proc/cpuinfo") as cpuinfo:
            for i in cpuinfo:
                if i.startswith("processor"):
                    corenumber.append(i.strip())
                if i.startswith("model name"):
                    cpumode = i.split(":")[1].strip()
        print("%s: %s" % ("CPU生厂商", cpumode)),
        print("%s: %s" % ("CPU总核心数", len(corenumber)))
        # 获取内存相关信息
        with open("/proc/meminfo") as meminfo:
            for i in meminfo:
                if i.startswith("MemTotal"):
                    totalmem = i.split(":")[1].strip()
        print("%s: %s" % ("总内存", totalmem))
        # 获取服务器硬件相关信息
        biosinfo = Popen(["dmidecode", "-t", "system"], stdout=PIPE)
        biosinfo = biosinfo.stdout.readlines()
        manufacturer = ""
        serialnumber = ""
        for i in biosinfo:
            i = i.decode()
            if "Manufacturer" in i:
                manufacturer = i.split(":")[1].strip()
            if "Serial Number" in i:
                serialnumber = i.split(":")[1].strip()
        print("%s: %s" % ("服务器生厂商", manufacturer))
        print("%s: %s" % ("服务器序列号", serialnumber))

        # 获取网卡信息,包括网卡名，IP地址，MAC地址
        # 定义存储格式，以网卡名为key，mac地址和ip地址为一个列表，这个列表又为这网卡名的value
        def add(dic, key, value):
            dic.setdefault(key, []).append(value)

        ipinfo = Popen(["ip", "addr"], stdout=PIPE)
        ipinfo = ipinfo.stdout.readlines()
        dict1 = {}
        for i in ipinfo:
            i = i.decode()
            if re.search(r"^\d", i):
                devname = i.split(": ")[1]
                continue
            if re.findall("ether", i):
                devmac = i.split()[1]
                add(dict1, devname, devmac)
                continue
            if re.findall("global", i):
                devip = i.split()[1]
                add(dict1, devname, devip)
                continue
        for i in dict1.keys():
            if len(dict1[i]) == 1:
                imac = dict1[i][0]
                iip = "该网卡未获取IP(请检查网卡是否启用或联网)"
            else:
                imac = dict1[i][0]
                iip = dict1[i][1]
            print("网卡名: {}    MAC:{}    IP: {}".format(i, imac, iip))


def javabyte2pythonbyte(javabyte):
    """
    Java byte 转 Python byte
    Args:
        javabyte:

    Returns:

    """
    return javabyte % 256


def pythonbyte2javabyte(pythonbyte):
    """
    Python byte转Java byte
    Args:
        pythonbyte:

    Returns:

    """
    return int(pythonbyte) - 256 if int(pythonbyte) > 127 else int(pythonbyte)


def javabytes2pythonbytes(javabytes):
    """
    Java byte数组转PythonByte数组
    Args:
        javabytes:

    Returns:

    """
    return bytes(i % 256 for i in javabytes)
    # return bytes(map(javabyte2pythonbyte, javabytes))


def pythonbytes2javabytes(pythonbytes):
    """
    Python byte数组转Java byte数组
    https://www.jianshu.com/p/b793b81088de
    Args:
        pythonbytes:

    Returns:

    """
    return [int(i) - 256 if int(i) > 127 else int(i) for i in pythonbytes]


def inputTimeout(str_msg, int_timeout_second):
    """
    输入超时模块
    Args:
        str_msg: 询问信息
        int_timeout_second: 超时时间

    Returns:
        输入,超时返回None
    """
    try:
        c = inputimeout(prompt=str_msg, timeout=int_timeout_second)
    except TimeoutOccurred:
        c = None
    finally:
        return c
        

def remove_newlines(text):
    """
    去换行符
    Args:
        text:

    Returns:

    """
    # 替换Unix和Linux系统的换行符
    text = text.replace('\n', '')
    # 替换Windows系统的换行符
    text = text.replace('\r\n', '')
    # 替换旧版Mac系统的换行符
    text = text.replace('\r', '')
    return text


def trim_spaces(string):
    """
    使用 strip() 方法去除字符串前后的空格
    Args:
        string:

    Returns:

    """
    trimmed_string = string.strip()
    # 将中间的空格保留
    result = ' '.join(trimmed_string.split())
    return result


def check_prefix_suffix(string, prefix=None, suffix=None):
    """
    检查字符串是否以特定前缀或后缀开头或结尾。

    Args:
        string (str): 要检查的字符串。
        prefix (str): 要检查的前缀。如果为None，则不检查前缀。
        suffix (str): 要检查的后缀。如果为None，则不检查后缀。

    Returns:
        bool: 如果字符串以指定的前缀开头且以指定的后缀结尾，则返回True；否则返回False。
    """
    if prefix is not None and not string.startswith(prefix):
        return False
    if suffix is not None and not string.endswith(suffix):
        return False
    return True


def readFileAsList(filepath, separator="\t", comment="#", ignoreNone=True, encoding="UTF-8"):
    """
    读取文件到列表
    Args:
        filepath: 文件路径
        separator: 分隔符
        comment: 注释
        ignoreNone: 忽略空行
        encoding: 编码

    Returns:

    """
    lst = []
    with open(filepath, "r", encoding=encoding) as ff:
        for line in ff.readlines():
            line = remove_newlines(line)
            if check_prefix_suffix(line, comment):
                # 遇到注释
                continue
            if line == "" and ignoreNone:
                # 为空且要求忽略
                continue
            lst.append(line.split(separator))
    return lst


def get_relative_path(path1, path2="."):
    """
    给定两个路径，返回前者相对于后者的相对路径
    Args:
        path1: 第一个路径（目标路径）
        path2: 第二个路径（基准路径）

    Returns:
        前者相对于后者的相对路径
    """
    # 将路径转换为标准化的绝对路径
    abs_path1 = os.path.abspath(path1)
    abs_path2 = os.path.abspath(path2)
    # 分割路径为列表
    path1_list = os.path.normpath(abs_path1).split(os.sep)
    path2_list = os.path.normpath(abs_path2).split(os.sep)
    # 找到第一个不同的目录索引
    index = 0
    for dir1, dir2 in zip(path1_list, path2_list):
        if dir1 != dir2:
            break
        index += 1
    # 构造相对路径
    relative_path = os.sep.join(['..' for _ in range(len(path2_list) - index)] + path1_list[index:])
    return relative_path


if __name__ == '__main__':
    print("是否是管理员：{}".format(checkAdministrator()))
    # execCommand("ls", 0, True)
    print("CPU核心数: {}".format(cpu_count()))
    # print("gitignore文件是否有UTF-8 BOM: {}".format(isBomExist("gitignore")))
    # 列出py文件
    # for f in getSuffixFile("py"):
    #     print(f)
