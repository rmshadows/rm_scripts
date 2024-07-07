#!/usr/bin/python3
import m_Image
import m_System

ext = ["jpg", "png", "jpeg"]
MarkText = ""
x = 0
y = 0
# 0:不显示路径 1:显示图片相对路径 2:仅显示到上级文件夹
RelPath = 2
FontSize = 40
Font = "zh.ttf"

if __name__ == '__main__':
    images = []
    for ex in ext:
        for f in m_System.getSuffixFile(ex, ".", False):
            images.append(f)

    for i in images:
        # 打开为Image对象
        image = m_Image.openImg(i)
        # 分离相对路径
        relp = m_System.get_relative_path(i, ".")
        # print(relp)
        if RelPath == 1:
            mark_text = relp
        elif RelPath == 2:
            mark_text = m_System.get_relative_path(m_System.splitFilePath(relp)[0])
        else:
            mark_text = ""
        if (MarkText is not None) and (MarkText != ""):
            mark_text = "{0}（{1}）".format(mark_text, MarkText)
        img = m_Image.draw_text(image, x, y, mark_text, FontSize, word_css=Font)
        m_Image.saveAsPrefixName(img,  i, "save-", True)

