#!/usr/bin/python3
"""
列表、字典处理
"""
import itertools

from natsort import natsorted


def averageSplitList(list2split:list, n:int):
    """
    平均分配到列表
    e.g.:
    [1,2,3,4,5,6,7] 3
    [1,2,3] [4,5,6] [7]
    Args:
        list2split: 列表
        n: 平分后每份列表包含的个数n

    Returns:

    """
    for i in range(0, len(list2split), n):
        yield list2split[i:i + n]


def splitListInto(list2split:list, n:int):
    """
    将列表强制分为n个
    e.g.:
    [1,2,3,4,5,6,7,8,9] 4
    [[1, 2], [3, 4], [5, 6], [7, 8, 9]]
    https://www.pythonheidong.com/blog/article/1090214/7731b9881faa69629e0d/
    Args:
        list2split: 列表
        n: 份数

    Returns:
        分隔后的列表
    """
    if not isinstance(list2split, list) or not isinstance(n, int):
        return []
    ls_len = len(list2split)
    if n <= 0 or 0 == ls_len:
        return []
    if n > ls_len:
        return []
    elif n == ls_len:
        return [[i] for i in list2split]
    else:
        j = ls_len // n
        k = ls_len % n
        ### j,j,j,...(前面有n-1个j),j+k
        # 步长j,次数n-1
        ls_return = []
        for i in range(0, (n - 1) * j, j):
            ls_return.append(list2split[i:i + j])
        # 算上末尾的j+k
        ls_return.append(list2split[(n - 1) * j:])
        return ls_return


def permutation(lst, len):
    """
    对给定的列表进行排列组合
    Args:
        lst: list[str] e.g.:["A", "B", "C"]
        len: 长度 int e.g.:4

    Returns:
        list: 排列组合
    """
    result = []
    for x in itertools.product(*[lst] * len):
        result.append("".join(str(x)))
    return result


def sortListBy(list, byIndex = 0, reverse = False):
    """
    列表排序
    Args:
        list:
        byIndex: 0为默认排序，指明则按索引，如：
        [[1,2,3,4], [1,2,5,4]] 索引2
        则按第三位来排序 3<5
        reverse: 从小-大排序

    Returns:

    """
    return sorted(list, key=lambda x:x[byIndex], reverse=reverse)


def sortByNatsorted(list):
    """
    自然排序功能
    Args:
        list:

    Returns:

    """
    return natsorted(list)


def sortDictByValue(dict, reverse = False):
    """
    按值排序字典
    Args:
        dict:
        reverse: 是否反向 从大-小

    Returns:

    """
    # 按Value排序  {0: 65, 2: 5} -> [(2, 5), (0, 65)] 这里是元组
    temp_sorted_dict_list = sorted(dict.items(), key=lambda kv: (kv[1], kv[0]))
    # 元组转列表 ii:(2, 5) iii:2 5
    tempsortedlist = []
    result_dict = {}
    for i in temp_sorted_dict_list:
        temp_lst = []
        for j in i:
            temp_lst.append(j)
        tempsortedlist.append(temp_lst)
    if reverse:
        tempsortedlist.reverse()
    for i in tempsortedlist:
        result_dict[i[0]] = i[1]
    return result_dict


def sortDictByKey(dict, reverse = False):
    """
    按key排序字典
    Args:
        dict:
        reverse: 是否反向 从大-小

    Returns:

    """
    # 按Value排序  {0: 65, 2: 5} -> [(2, 5), (0, 65)] 这里是元组
    temp_sorted_dict_list = sorted(dict.items(), key=lambda kv: (kv[0], kv[1]))
    # 元组转列表 ii:(2, 5) iii:2 5
    tempsortedlist = []
    result_dict = {}
    for i in temp_sorted_dict_list:
        temp_lst = []
        for j in i:
            temp_lst.append(j)
        tempsortedlist.append(temp_lst)
    if reverse:
        tempsortedlist.reverse()
    for i in tempsortedlist:
        result_dict[i[0]] = i[1]
    return result_dict


def hasDuplicates(lst):
    """
    判断给定列表中是否有重复元素
    Args:
        lst:

    Returns:

    """
    return len(lst) != len(set(lst))


def find_duplicate_indexes(lst, verbose=False):
    """
    返回重复元素+索引
    {5: [4, 5], 6: [6, 7], 8: [9, 10]}
    Args:
        lst:

    Returns:

    """
    duplicates = {}
    for i, item in enumerate(lst):
        if item in duplicates:
            duplicates[item].append(i)
        else:
            duplicates[item] = [i]
    duplicate_indexes = {item: indexes for item, indexes in duplicates.items() if len(indexes) > 1}
    if verbose:
        if duplicate_indexes:
            print("列表中的重复元素及其索引:")
            for item, indexes in duplicate_indexes.items():
                print(f"元素 {item} 在索引 {indexes} 重复")
        else:
            print("列表中没有重复元素")
    return duplicate_indexes


def modify_string_if_duplicate(string, lst):
    """
    检查是否在给定列表中，并返回字符串
    python判断给定新字符串是否包含在原列表中，如果有就加上后缀(1)，比如给定x，原来列表中有x，就返回x(1)，如果原列表中有x(1)，就返回x(2)
    不变返回None
    Args:
        string:
        lst:

    Returns:

    """
    count = 1
    modified_string = string
    while modified_string in lst:
        modified_string = f"{string}({count})"
        count += 1
    if modified_string == string:
        return None
    else:
        return modified_string


def remove_duplicates(input_list, preserve_order=True):
    """
    去除重复元素
    Remove duplicate elements from a list and return a new list.

    Parameters:
    input_list (list): The list from which duplicates need to be removed.
    preserve_order (bool): Whether to preserve the original order of elements. Default is True.

    Returns:
    list: A new list with duplicates removed.
    """
    if preserve_order:
        seen = set()
        new_list = []
        for item in input_list:
            if item not in seen:
                new_list.append(item)
                seen.add(item)
        return new_list
    else:
        return list(set(input_list))


if __name__ == '__main__':
    l1 = [1,4,2,3,5,9,1]
    l2 = [3,3,2,4,5,5,2]
    l3 = [2,2,2,4,5,5,3]
    l = [l1,l2,l3]
    d1 = {1:3, 4:2, 3:5}

