# Scoop CN Mirror Bucket

国内镜像加速的 Scoop Bucket，将常用开发工具的下载地址替换为 **NJU、TUNA、阿里云、腾讯云** 等国内镜像站，解决 GitHub / 境外源下载慢或失败的问题。

---

## 快速开始

### 1. 添加 Bucket

```powershell
scoop bucket add cn-mirror https://gitee.com/axinger-scoop/cn-mirror.git
```

### 2. 安装软件

```powershell
# 安装 JDK 21（南大镜像）
scoop install cn-mirror/temurin21-jdk

# 安装 Maven（清华镜像）
scoop install cn-mirror/maven

# 安装 Node.js LTS（阿里云镜像）
scoop install cn-mirror/nodejs-lts
```

> **提示**：`cn-mirror` 中的软件与官方 bucket 同名，只是下载地址不同。安装前可用 `scoop search <软件名>` 查看可用来源。

---

## 已收录软件

| 软件名 | 版本 | 镜像源 | 说明 |
|--------|------|--------|------|
| python | 3.14.6 | TUNA | Python 解释器 |
| git | 2.54.0 | TUNA | Git for Windows |
| nodejs-lts | 24.16.0 | 阿里云 | Node.js 长期支持版 |
| maven | 3.9.16 | TUNA | Java 项目构建工具 |
| gradle | 9.5.1 | 腾讯云 | Gradle 构建工具 |
| temurin8-jdk | 8u492-b09 | NJU | Eclipse Temurin JDK 8 |
| temurin11-jdk | 11.0.31-11 | NJU | Eclipse Temurin JDK 11 |
| temurin17-jdk | 17.0.19-10 | NJU | Eclipse Temurin JDK 17 |
| temurin21-jdk | 21.0.11-10.0 | NJU | Eclipse Temurin JDK 21 |

---

## 为什么使用这个 Bucket？

Scoop 官方 bucket 中的软件下载地址通常指向 **GitHub Releases**、**nodejs.org**、**python.org** 等境外服务器。在国内网络环境下：

- 下载速度极慢（几 KB/s）
- 频繁超时、断连
- 某些地区完全无法访问

本仓库将这些下载地址替换为国内高校/云厂商的镜像源，**软件本体与官方完全一致**，仅加速下载过程。

---

## 镜像源

| 镜像站 | 地址 | 覆盖软件 |
|--------|------|----------|
| NJU（南京大学） | https://mirrors.nju.edu.cn/ | JDK（Adoptium） |
| TUNA（清华大学） | https://mirrors.tuna.tsinghua.edu.cn/ | Python、Git、Maven |
| 阿里云 | https://mirrors.aliyun.com/ | Node.js |
| 腾讯云 | https://mirrors.cloud.tencent.com/ | Gradle |

---

## 如何添加新软件

如果你想为本仓库贡献新的国内镜像软件，步骤如下：

1. **找到原始清单**：从 `main` / `java` 等官方 bucket 复制 JSON 清单
2. **找到国内镜像地址**：在 NJU / TUNA / 阿里云 / 腾讯云等镜像站搜索对应文件
3. **获取哈希值**：下载镜像文件，计算 SHA256（或从镜像站的 `.sha256.txt` 获取）
4. **修改清单**：替换 `url` 和 `hash` 字段
5. **测试安装**：`scoop install cn-mirror/<软件名>`
6. **提交 PR**：推送到本仓库

详细步骤参考：`cn-mirror-guide.md`（位于 [ax-note/scoop/cn-mirror-guide.md](https://gitee.com/axinger/ax-note/blob/main/scoop/cn-mirror-guide.md)）

---

## 仓库关系

本仓库（`cn-mirror`）是 [ax-note](https://gitee.com/axinger/ax-note) 项目的 **Git Submodule**，用于集中管理国内镜像加速的 Scoop 软件清单。

```
ax-note/
└── scoop/
    └── cn-mirror/   ← 本仓库（独立推送）
```

---

## 常见问题

**Q: 安装后软件和官方版本有区别吗？**

A: 没有区别。镜像站定期同步官方源，文件哈希值经过校验，确保与官方一致。

**Q: 某些软件版本较新，镜像站没有怎么办？**

A: 可以先用官方 bucket 安装，或在本仓库提交 Issue 请求添加。镜像站通常会在 1~3 天内同步新版本。

**Q: 可以同时安装官方 bucket 和 cn-mirror 的同名软件吗？**

A: 不可以。Scoop 同一时刻只能安装一个来源的软件。如需切换来源：`scoop uninstall <软件名>` 后再从另一来源安装。

---

## License

各软件遵循其原始许可证。本仓库仅提供镜像地址替换，不修改软件本体。
