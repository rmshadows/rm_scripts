#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
功能说明：
    读取 gps.tsv 文件中的 WGS-84 坐标（无人机/GPS 原始坐标），
    转换为高德地图使用的 GCJ-02 坐标，
    并生成可直接定位的高德地图 URL。

输入文件（TSV，制表符分隔）示例：
    file    lat     lon     status
    ./IMG_20251216_124330.jpg   24.434898   117.829561972222   OK

输出文件：
    gps_amap.tsv
    在原有字段基础上，新增：
        - gcj_lat   （高德纬度）
        - gcj_lon   （高德经度）
        - amap_url  （高德地图定位链接）
"""

import csv
import math
from pathlib import Path

# ---------------------------
# 坐标转换常量（国家测绘通用）
# ---------------------------
PI = math.pi
A = 6378245.0  # 地球长半轴
EE = 0.00669342162296594323  # 偏心率平方


def _out_of_china(lat: float, lon: float) -> bool:
    """
    判断坐标是否在中国境外
    - 中国境外不做 GCJ-02 偏移，直接返回原坐标
    """
    return lon < 72.004 or lon > 137.8347 or lat < 0.8293 or lat > 55.8271


def _transform_lat(x: float, y: float) -> float:
    """
    GCJ-02 纬度偏移算法
    """
    ret = -100.0 + 2.0*x + 3.0*y + 0.2*y*y + 0.1*x*y + 0.2*math.sqrt(abs(x))
    ret += (20.0*math.sin(6.0*x*PI) + 20.0*math.sin(2.0*x*PI)) * 2.0 / 3.0
    ret += (20.0*math.sin(y*PI) + 40.0*math.sin(y/3.0*PI)) * 2.0 / 3.0
    ret += (160.0*math.sin(y/12.0*PI) + 320*math.sin(y*PI/30.0)) * 2.0 / 3.0
    return ret


def _transform_lon(x: float, y: float) -> float:
    """
    GCJ-02 经度偏移算法
    """
    ret = 300.0 + x + 2.0*y + 0.1*x*x + 0.1*x*y + 0.1*math.sqrt(abs(x))
    ret += (20.0*math.sin(6.0*x*PI) + 20.0*math.sin(2.0*x*PI)) * 2.0 / 3.0
    ret += (20.0*math.sin(x*PI) + 40.0*math.sin(x/3.0*PI)) * 2.0 / 3.0
    ret += (150.0*math.sin(x/12.0*PI) + 300.0*math.sin(x/30.0*PI)) * 2.0 / 3.0
    return ret


def wgs84_to_gcj02(lat: float, lon: float) -> tuple[float, float]:
    """
    坐标转换主函数
    输入：
        lat, lon  - WGS-84 坐标（无人机/GPS 原始）
    输出：
        (gcj_lat, gcj_lon) - GCJ-02 坐标（高德/腾讯地图）
    """
    if _out_of_china(lat, lon):
        return lat, lon

    dlat = _transform_lat(lon - 105.0, lat - 35.0)
    dlon = _transform_lon(lon - 105.0, lat - 35.0)

    radlat = lat / 180.0 * PI
    magic = math.sin(radlat)
    magic = 1 - EE * magic * magic
    sqrtmagic = math.sqrt(magic)

    dlat = (dlat * 180.0) / ((A * (1 - EE)) / (magic * sqrtmagic) * PI)
    dlon = (dlon * 180.0) / (A / sqrtmagic * math.cos(radlat) * PI)

    return lat + dlat, lon + dlon


def amap_marker_url(gcj_lat: float, gcj_lon: float, name: str | None = None) -> str:
    """
    生成高德地图 marker 定位 URL
    注意：
        高德地图 URL 参数顺序是：经度,纬度
    """
    base = f"https://uri.amap.com/marker?position={gcj_lon:.6f},{gcj_lat:.6f}"
    if name:
        base += "&name=" + name.replace(" ", "%20")
    return base


def main():
    """
    主流程：
        1. 读取 gps.tsv
        2. 将 lat/lon 转为 GCJ-02
        3. 生成高德地图定位链接
        4. 输出 gps_amap.tsv
    """
    in_path = Path("gps.tsv")
    out_path = Path("gps_amap.tsv")

    if not in_path.exists():
        raise FileNotFoundError("未找到 gps.tsv，请确认文件路径。")

    with in_path.open("r", encoding="utf-8") as fin, \
         out_path.open("w", encoding="utf-8", newline="") as fout:

        reader = csv.DictReader(fin, delimiter="\t")

        # 在原字段基础上追加新列
        fieldnames = list(reader.fieldnames or [])
        for col in ["gcj_lat", "gcj_lon", "amap_url"]:
            if col not in fieldnames:
                fieldnames.append(col)

        writer = csv.DictWriter(fout, delimiter="\t", fieldnames=fieldnames)
        writer.writeheader()

        for row in reader:
            try:
                lat = float(row["lat"])
                lon = float(row["lon"])
            except Exception:
                # 坐标异常时，保留原行，新增列留空
                row["gcj_lat"] = ""
                row["gcj_lon"] = ""
                row["amap_url"] = ""
                writer.writerow(row)
                continue

            gcj_lat, gcj_lon = wgs84_to_gcj02(lat, lon)

            row["gcj_lat"] = f"{gcj_lat:.6f}"
            row["gcj_lon"] = f"{gcj_lon:.6f}"

            # 使用文件名作为点位名称（可按需修改）
            name = Path(row.get("file", "")).name if row.get("file") else None
            row["amap_url"] = amap_marker_url(gcj_lat, gcj_lon, name)

            writer.writerow(row)

    print(f"处理完成，输出文件：{out_path.resolve()}")


if __name__ == "__main__":
    main()

