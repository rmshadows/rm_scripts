# Title

## 默认配置

```
├── build
│   ├── bopomofo.prism.bin
│   ├── bopomofo.schema.yaml
│   ├── bopomofo_tw.prism.bin
│   ├── bopomofo_tw.schema.yaml
│   ├── cangjie5.prism.bin
│   ├── cangjie5.schema.yaml
│   ├── default.yaml
│   ├── luna_pinyin_fluency.prism.bin
│   ├── luna_pinyin_fluency.schema.yaml
│   ├── luna_pinyin.prism.bin
│   ├── luna_pinyin.schema.yaml
│   ├── luna_pinyin_simp.prism.bin
│   ├── luna_pinyin_simp.schema.yaml
│   ├── luna_quanpin.prism.bin
│   ├── luna_quanpin.schema.yaml
│   ├── stroke.prism.bin
│   ├── stroke.schema.yaml
│   ├── terra_pinyin.prism.bin
│   └── terra_pinyin.schema.yaml
├── installation.yaml
├── luna_pinyin.userdb
│   ├── 000003.log
│   ├── CURRENT
│   ├── LOCK
│   ├── LOG
│   └── MANIFEST-000002
├── sync
│   └── f4675913-3394-4bf5-b627-a6fcdf67f69e
│       └── installation.yaml
└── user.yaml
```

## 自定义配置

```
```

## 参考

```
用戶資料夾 則包含爲用戶準備的內容，如：
    〔全局設定〕 default.yaml
    〔發行版設定〕 weasel.yaml
    〔預設輸入方案副本〕 <方案標識>.schema.yaml
    ※〔安裝信息〕 installation.yaml
    ※〔用戶狀態信息〕 user.yaml
編譯輸入方案所產出的二進制文件：
    〔Rime 棱鏡〕 <方案標識>.prism.bin
    〔Rime 固態詞典〕 <詞典名>.table.bin
    〔Rime 反查詞典〕 <詞典名>.reverse.bin
記錄用戶寫作習慣的文件：
    ※〔用戶詞典〕 <詞典名>.userdb/ 或 <詞典名>.userdb.kct
    ※〔用戶詞典快照〕 <詞典名>.userdb.txt、<詞典名>.userdb.kct.snapshot 見於同步文件夾
以及用戶自己設定的：
    ※〔用戶對全局設定的定製信息〕 default.custom.yaml
    ※〔用戶對預設輸入方案的定製信息〕 <方案標識>.custom.yaml
    ※〔用戶自製輸入方案〕及配套的詞典源文件
註：以上標有 ※ 號的文件，包含用戶資料，您在清理文件時要注意備份！
```

## 码表

```
# 單字
你	ni
我	wo
的	de	99%
的	di	1%
地	de	10%
地	di	90%
目	mu
好	hao

# 詞組
你我
你的
我的
我的天
天地	tian di
好天
好好地
目的	mu di
目的地	mu di di

※注意： 不要 從網頁複製以上代碼到實作的詞典文件！因爲網頁裏製表符被轉換成空格從而不符合 Rime 詞典要求的格式。一些文本編輯器也會將使用者輸入的製表符自動轉換爲空格，請注意檢查和設置。

碼表部份，除了以上格式的編碼行，還可以包含空行（不含任何字符）及註釋行（行首爲 # 符號）。

以製表符（Tab）分隔的第一個字段是所定義的文字，可以是單字或詞組；

第二個字段是與文字對應的編碼；若該編碼由多個「音節」組成，音節之間以空格分開；

可選地、第三個字段是設定該字詞權重的頻度值（非負整數），或相對於預設權值的百分比（浮點數%）。 在拼音輸入法中，往往多音字的若干種讀音使用的場合不同，於是指定不同百分比來修正每個讀音的使用頻度。
```

## 其他词库

- 白霜拼音 - https://github.com/gaboolic/rime-frost
- 雾凇拼音 - https://github.com/iDvel/rime-ice
- RIME 词库增强 - https://github.com/Iorest/rime-dict
