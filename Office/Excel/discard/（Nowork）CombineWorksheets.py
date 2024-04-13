"""
合并工作表
"""
import m_System

# 要合并的工作表
worksheetpath = "src"

if __name__ == '__main__':
    wbs = m_System.getSuffixFile("xlsx", worksheetpath, False)
    for i in wbs:
        print(i)
