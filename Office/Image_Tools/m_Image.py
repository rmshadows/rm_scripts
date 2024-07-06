#!/usr/bin/python3
"""
图像处理
"""
from PIL import Image, ImageDraw, ImageFont

import m_System


def openImg(fp):
    """
    打开图像
    Args:
        fp:

    Returns:

    """
    return Image.open(fp)


def draw_English_text(image, x, y, string, font_size=20, color=(0, 0, 0), word_css="en.ttf", direction=None):
    """
    添加英文文字（字体限制英文, 可自行修改中文字体）
    Args:
        image: Image对象
        x: x坐标
        y: y坐标
        string: 字符串
        font_size: 字体大小
        color: 颜色
        word_css: 字体
        direction: 方向

    Returns:
        Image对象
    """
    image = image.convert("RGB")
    font = ImageFont.truetype(word_css, font_size)
    draw = ImageDraw.Draw(image)
    draw.text((x, y), string, font=font, fill=color, direction=None)
    del draw
    return image


def saveAsPrefixName(image, fp, prefixName, verbose=False):
    nfn = m_System.editFilename(fp, None, prefix=prefixName)
    if verbose:
        print("{} -> {}".format(fp, nfn))
    image.save(nfn)


def draw_text(image, x, y, string, font_size=20, color=(0, 0, 0), word_css="zh.ttf", direction=None):
    """
    添加文字
    Args:
        image: Image对象
        x: x坐标(负数则从反方向开始计算)
        y: y坐标(负数则从反方向开始计算)
        string: 字符串
        font_size: 字体大小
        color: 颜色
        word_css: 字体
        direction: 方向

    Returns:
        Image对象
    """
    image = image.convert("RGB")
    font = ImageFont.truetype(word_css, font_size)
    draw = ImageDraw.Draw(image)

    # 获取文字的边界框
    text_bbox = draw.textbbox((0, 0), string, font=font, direction=direction)
    text_width = text_bbox[2] - text_bbox[0]
    text_height = text_bbox[3] - text_bbox[1]

    # 如果x或y为负值，从右下角开始计算
    if x < 0:
        x = image.width + x - text_width
    if y < 0:
        y = image.height + y - text_height

    # 绘制文字
    draw.text((x, y), string, font=font, fill=color, direction=direction)
    del draw
    return image


if __name__ == '__main__':
    print("Hello World")










