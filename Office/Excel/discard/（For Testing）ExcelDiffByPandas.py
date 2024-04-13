import pandas as pd


# 用法示例
file1 = "1.xlsx"
file2 = "2.xlsx"


def compare_excel_files(file1, file2):
    # 读取 Excel 文件
    df1 = pd.read_excel(file1)
    df2 = pd.read_excel(file2)
    
    # 比较两个 DataFrame
    if df1.equals(df2):
        print("两个 Excel 文件相同，没有差异。")
    else:
        print("两个 Excel 文件不同，存在差异。")
        
        # 查找不同之处
        diff_locations = (df1 != df2).any(axis=None)
        diff_cells = df1[df1 != df2].stack()
        print("不同之处：")
        print(diff_cells)
        
        # 可选：将不同之处保存到新的 Excel 文件
        diff_cells.to_excel("差异.xlsx", header=False)


if __name__ == '__main__':
    compare_excel_files(file1, file2)

