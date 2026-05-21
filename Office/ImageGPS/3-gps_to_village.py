#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
直接运行：
    python3 3-gps_to_village.py

输入：
- gps.tsv（tab 分隔）：file, lat, lon, status   （WGS-84，经度lon，纬度lat）
- 龙海区村界.shp（村界面，字段含：XZQDM, XZQMC ...）

输出：
- gps_with_village.tsv（tab 分隔）：原列 + XZQDM + XZQMC + hit
"""

# =======================
# 默认配置区（只改这里）
# =======================
GPS_TSV = "gps.tsv"
VILLAGE_SHP = "龙海区村界.shp"
OUT_TSV = "gps_with_village.tsv"

ONLY_STATUS_OK = True

# shp 缺 CRS 时的兜底（你这个最可能是 4490=CGCS2000 或 4326=WGS84）
ASSUME_SHP_EPSG = 4490   # 不对就改成 4326 再跑一次

# 空间关系：点在面内
PREDICATE = "within"     # 推荐 within

# 边界补救：点落在边界线上时，within 可能返回空；用小缓冲+intersects兜底
EDGE_BUFFER_METERS = 2   # 0=关闭
# =======================

import os
os.environ["SHAPE_RESTORE_SHX"] = "YES"  # 自动重建缺失的 .shx

import pandas as pd
import geopandas as gpd
from shapely.geometry import Point


def load_villages(path: str) -> gpd.GeoDataFrame:
    gdf = gpd.read_file(path)

    # shp 没 CRS：用兜底 EPSG
    if gdf.crs is None:
        if ASSUME_SHP_EPSG is None:
            raise RuntimeError("村界 shp 没有 CRS，且 ASSUME_SHP_EPSG=None，无法继续。")
        gdf = gdf.set_crs(epsg=ASSUME_SHP_EPSG)

    # 统一转 WGS84（经纬度）
    gdf = gdf.to_crs(epsg=4326)

    # 必须字段检查
    need = ["XZQDM", "XZQMC"]
    missing = [c for c in need if c not in gdf.columns]
    if missing:
        raise RuntimeError(f"村界属性表缺少字段：{missing}（请确认 shp 字段名是否一致）")

    # 只保留需要的字段 + geometry，避免 join 出来一堆列
    gdf = gdf[["XZQDM", "XZQMC", "geometry"]].copy()
    return gdf


def main():
    # 1) 读 gps.tsv
    df = pd.read_csv(GPS_TSV, sep="\t", dtype={"file": str, "status": str})
    df["lat"] = pd.to_numeric(df["lat"], errors="coerce")
    df["lon"] = pd.to_numeric(df["lon"], errors="coerce")

    if ONLY_STATUS_OK and "status" in df.columns:
        df_work = df[df["status"] == "OK"].copy()
    else:
        df_work = df.copy()

    df_work = df_work.dropna(subset=["lon", "lat"])

    # 2) 点表 -> GeoDataFrame（WGS84）
    pts = gpd.GeoDataFrame(
        df_work,
        geometry=[Point(xy) for xy in zip(df_work["lon"], df_work["lat"])],
        crs="EPSG:4326",
    )

    # 3) 读村界并统一到 WGS84
    villages = load_villages(VILLAGE_SHP)

    # 4) 空间连接：within
    joined = gpd.sjoin(
        pts,
        villages,
        how="left",
        predicate=PREDICATE,
    )

    # 5) 边界补救：未命中 -> 点缓冲(米) + intersects
    if EDGE_BUFFER_METERS and EDGE_BUFFER_METERS > 0:
        miss = joined[joined["index_right"].isna()].copy()
        if not miss.empty:
            pts_3857 = pts.to_crs(epsg=3857)
            villages_3857 = villages.to_crs(epsg=3857)

            fix_geom = pts_3857.loc[miss.index, "geometry"].buffer(EDGE_BUFFER_METERS)
            fix = gpd.GeoDataFrame(miss.drop(columns=["geometry"]), geometry=fix_geom, crs="EPSG:3857")

            fix_join = gpd.sjoin(
                fix,
                villages_3857,
                how="left",
                predicate="intersects",
            )

            # 写回 XZQDM/XZQMC
            for idx in fix_join.index:
                if pd.isna(joined.loc[idx, "index_right"]) and not pd.isna(fix_join.loc[idx, "index_right"]):
                    joined.loc[idx, "XZQDM"] = fix_join.loc[idx, "XZQDM"]
                    joined.loc[idx, "XZQMC"] = fix_join.loc[idx, "XZQMC"]
                    joined.loc[idx, "index_right"] = fix_join.loc[idx, "index_right"]

    # 6) 输出
    out = joined[["file", "lat", "lon", "status", "XZQDM", "XZQMC"]].copy()
    out["hit"] = ~joined["index_right"].isna()

    # 合并回原 df（保留全部行）
    merge_keys = [c for c in ["file", "lat", "lon", "status"] if c in df.columns]
    df_out = df.merge(out, on=merge_keys, how="left")

    df_out.to_csv(OUT_TSV, sep="\t", index=False, encoding="utf-8")
    print(f"完成：输出 {OUT_TSV}")
    print(f"命中：{int(df_out['hit'].fillna(False).sum())}/{len(df_out)}")
    print("提示：如果全部未命中或命中明显不对，把 ASSUME_SHP_EPSG 在 4490/4326 间切换再试。")


if __name__ == "__main__":
    main()

