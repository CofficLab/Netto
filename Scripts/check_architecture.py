#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Netto 架构依赖扫描脚本（阶段 8）。

用途：阻止回归，维护迁移后架构边界。可独立运行：
    python3 Scripts/check_architecture.py

检查项（任一命中即失败，exit 1）：
  R1  KernelCore 包禁止 import UI/业务 SDK：
      SwiftUI / AppKit / NetworkExtension / SwiftData / StoreKit /
      MagicKit / MagicCore / MagicUI / OSLog / Combine / Observation
      （允许 Foundation / Synchronization 及标准库）。
  R2  所有本地包禁止 `static let shared` / `static var shared` 单例。
  R3  Plugin 实现包（Packages/Plugin*）禁止 import 同级其他 Plugin 包
      （跨插件只能走 Provider 契约）。
  R4  App 目标（Core/Plugins/AppStore）禁止直连 Repo/Service：
      旧 singleton 访问、旧构造器、旧注册机制符号。
  R5  全仓库禁止 `@unchecked Sendable`（不得掩盖并发边界）。
  R6  全仓库禁止 Objective-C 运行时自动注册（objc_copyClassList、
      autoRegisterPlugins、@objc(...Registrant)）。

已知豁免（刻意保留，请勿误报）：
  - App 目标 import ProviderShell / Provider 契约 / FactoryNetto / KernelCore：
    App 组合根负责启动 Factory 创建的唯一 Kernel 并缓存视图所需契约。
  - ProviderShell 暴露 `AnyView` 的 UI 贡献契约（阶段 6 既定设计）。
  - Core/Config/AppNotifications.swift 的 App 内通知名（无负载壳内信号）。
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

KERNEL_BANNED_IMPORTS = {
    "SwiftUI", "AppKit", "NetworkExtension", "SwiftData", "StoreKit",
    "MagicKit", "MagicCore", "MagicUI", "OSLog", "Combine", "Observation",
}

# App 目标内禁用的旧服务符号（R4）
BANNED_SYMBOLS = [
    "EventRepo.shared", "AppSettingRepo.shared", "FirewallService.shared",
    "PluginRegistry.shared", "PluginWindowManager.shared",
    "MagicMessageProvider.shared", "StoreService.bootstrap",
    "autoRegisterPlugins", "PluginRegistrant", "PluginWindowContent",
    "EventRepo(", "AppSettingRepo(", "FirewallService(",
    "OSSystemExtensionManager.shared", "IPCConnection.shared",
]

R2_PATTERN = re.compile(r"static\s+(?:let|var)\s+shared\b")
R5_PATTERN = re.compile(r"@unchecked\s+Sendable")
R6_PATTERNS = [
    re.compile(r"objc_copyClassList"),
    re.compile(r"autoRegisterPlugins"),
    re.compile(r"@objc\(\w*Registrant"),
]

import_re = re.compile(r"^\s*import\s+(\S+)", re.MULTILINE)

violations = []


def scan_files(roots, exclude_dirs=(".build",), include_ext=(".swift",)):
    for root in roots:
        r = pathlib.Path(root)
        if not r.exists():
            continue
        for p in r.rglob("*"):
            if any(part in exclude_dirs for part in p.parts):
                continue
            if p.suffix in include_ext and p.is_file():
                yield p


def report(path, rule, detail):
    violations.append(f"[{rule}] {path}: {detail}")


# R1 / R2 / R5：KernelCore 与全部本地包
for p in scan_files([ROOT / "Packages"]):
    text = p.read_text(encoding="utf-8", errors="replace")
    rel = p.relative_to(ROOT)
    if "KernelCore" in p.parts:
        for m in import_re.finditer(text):
            mod = m.group(1)
            if mod in KERNEL_BANNED_IMPORTS:
                report(rel, "R1", f"KernelCore 非法 import {mod}")
    if R2_PATTERN.search(text):
        report(rel, "R2", "包内存在 shared 单例")
    # R5：忽略注释行（"不使用 @unchecked Sendable" 等说明性注释不算违规）
    for i, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        if stripped.startswith("//") or stripped.startswith("///") or stripped.startswith("*"):
            continue
        if R5_PATTERN.search(line):
            report(rel, "R5", f"@unchecked Sendable 不允许 (行 {i})")

# R3：Plugin 实现包不 import 同级 Plugin 包
plugin_pkgs = {
    p.name for p in (ROOT / "Packages").glob("Plugin*")
    if p.is_dir() and (p / "Package.swift").is_file()
}
for p in scan_files([ROOT / "Packages"]):
    if not any(part.startswith("Plugin") for part in p.parts):
        continue
    # Test targets may compose plugins for integration coverage; R3 governs shipped code.
    if "Tests" in p.parts:
        continue
    # 定位该源文件所属包名
    pkg_name = None
    for part in p.parts:
        if part in plugin_pkgs:
            pkg_name = part
            break
    if pkg_name is None:
        continue
    text = p.read_text(encoding="utf-8", errors="replace")
    for m in import_re.finditer(text):
        mod = m.group(1)
        if mod in plugin_pkgs and mod != pkg_name:
            report(p.relative_to(ROOT), "R3", f"import 同级插件包 {mod}")

# R4：App 目标禁用的旧服务符号
for p in scan_files([ROOT / "Core", ROOT / "Plugins", ROOT / "AppStore"]):
    text = p.read_text(encoding="utf-8", errors="replace")
    rel = p.relative_to(ROOT)
    for sym in BANNED_SYMBOLS:
        for i, line in enumerate(text.splitlines(), 1):
            if sym in line and "//" not in line.split(sym)[0]:
                report(rel, "R4", f"命中 {sym} (行 {i})")

# R6：全仓库 ObjC 自动注册
for p in scan_files([ROOT / "Core", ROOT / "Plugins", ROOT / "AppStore", ROOT / "Packages", ROOT / "Bridge", ROOT / "Extension"]):
    text = p.read_text(encoding="utf-8", errors="replace")
    rel = p.relative_to(ROOT)
    for pat in R6_PATTERNS:
        if pat.search(text):
            report(rel, "R6", f"命中 {pat.pattern}")

if violations:
    print("架构扫描失败：发现 %d 处违规" % len(violations))
    for v in violations:
        print("  " + v)
    sys.exit(1)
print("架构扫描通过：R1–R6 全部干净")
