# Scoop CN Mirror Bucket

国内镜像加速的 Scoop Bucket，将软件下载地址替换为 NJU、TUNA 等国内镜像站。

## 添加此 Bucket

```powershell
scoop bucket add cn-mirror https://gitee.com/axinger-scoop/cn-mirror.git
```

## 安装软件

```powershell
scoop install cn-mirror/temurin21-jdk
```

## 已收录软件

| 软件名 | 版本 | 镜像源 |
|--------|------|--------|
| python | 3.14.6 | TUNA |
| git | 2.54.0 | TUNA |
| nodejs-lts | 24.16.0 | 阿里云 |
| maven | 3.9.16 | TUNA |
| gradle | 9.5.1 | 腾讯云 |
| temurin8-jdk | 8u492-b09 | NJU |
| temurin11-jdk | 11.0.31-11 | NJU |
| temurin17-jdk | 17.0.19-10 | NJU |
| temurin21-jdk | 21.0.11-10.0 | NJU |

## 镜像源

- NJU: https://mirrors.nju.edu.cn/
- TUNA: https://mirrors.tuna.tsinghua.edu.cn/
- 阿里云: https://mirrors.aliyun.com/
- 腾讯云: https://mirrors.cloud.tencent.com/
