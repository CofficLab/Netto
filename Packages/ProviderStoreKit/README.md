# ProviderStoreKit

Netto 特有的商店能力契约。

## 与共享层的分工

| 层 | 位置 | 职责 |
|---|---|---|
| 通用契约 | `ProviderStore`（[LumiProviders](https://github.com/CofficLab/LumiProviders)） | 订阅档位、权益快照、权益能力协议、购买呈现协议、商品表契约 |
| 通用机制 | `KitStoreKit`（[LumiStoreKit](https://github.com/CofficLab/LumiStoreKit)） | 交易监听、权益校准、商品拉取、购买、恢复、交易验证、订阅聚合 |
| 本包 | ProviderStoreKit | Netto 特有的应用内能力契约 |

Netto 原来的 `ProviderStore` 包同时承担了「通用契约」与「Netto 特有契约」两件事。接入共享层后，通用部分交给共享契约包，本包只保留 Netto 特有的部分：

- `StoreProviding`：Netto 商店窗口与其消费方（防火墙面板）之间的应用内契约——加载商品、发起购买、恢复购买、订阅权益变更流。

## 依赖约束

本包只依赖共享的 `ProviderStore` 契约，**不依赖 StoreKit**。对外只暴露中立 Snapshot 与商品 ID，保证 Kernel 与其它插件不需要引入 StoreKit 依赖。

## 测试

```bash
cd Packages/ProviderStoreKit
swift test
```
