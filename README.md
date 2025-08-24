# moomoo_custom_strategies

本项目包含为 Moomoo 客户端量化功能开发的自定义交易策略。每个策略都旨在解决特定的交易需求，并具有不同的功能侧重和参数配置。

## ⚠️ 免责声明 | Disclaimer

### 中文声明

本项目仅供学习和研究使用，不构成任何投资建议或交易指导。请注意：

1.  作者不是专业的投资顾问或理财规划师，本项目中的所有策略均基于个人研究和实践经验。
2.  量化交易存在固有风险，包括但不限于市场风险、流动性风险、技术风险等。
3.  任何人使用本项目中的代码进行实盘交易需自行承担全部风险和后果。
4.  策略的历史表现不代表未来收益，任何基于本项目进行的交易决策需要使用者自行判断和负责。
5.  在使用本项目代码进行实盘交易前，强烈建议：
    - 充分了解量化交易的原理和风险
    - 仔细阅读并理解代码的具体实现
    - 使用模拟盘进行充分测试
    - 根据个人风险承受能力调整参数
    - 合理控制仓位和资金规模

### English Disclaimer

This project is for educational and research purposes only. Please be aware:

1.  The author is not a professional financial advisor, and all strategies are based on personal research and experience.
2.  Quantitative trading involves inherent risks, including but not limited to market risk, liquidity risk, and technical risk.
3.  Anyone who uses the code in this project for live trading does so at their own risk and is solely responsible for any consequences.
4.  Past performance does not guarantee future results. All trading decisions based on this project require users' own judgment and responsibility.
5.  Before using this code for live trading, it is strongly recommended to:
    - Fully understand the principles and risks of quantitative trading
    - Carefully read and understand the code implementation
    - Conduct thorough testing using paper trading
    - Adjust parameters according to personal risk tolerance
    - Maintain reasonable position and capital management

## 策略总览

本项目目前包含以下主要策略，每个策略都针对不同的交易场景和用户需求：

| 策略名称 | 最新版本 | 核心功能概述 | 适用场景 | 更多详情 |
|---|---|---|---|---|
| **策略 V1 (定投与回撤加仓)** | `v1.1.0` | 固定周期定投，结合市场回撤动态分层加仓，旨在长期摊低成本。支持多种模式（基础定投、回撤加仓、极端回撤风控）。回测模式下日志格式与实盘完全一致。 | 适合追求长期资产积累、希望在下跌时逐步建仓的用户。 | [查看详情](./strategies/strategy_v1/readme.md) |
| **策略 V2 (标准网格交易)** | `v6.1` | 经典网格交易策略，通过预设网格进行高抛低吸。侧重订单与持仓管理的健壮性，增强了 fallback 逻辑处理订单同步延迟问题。 | 适合需要经典网格交易、对订单执行稳定性有较高要求的用户。 | [查看详情](./strategies/strategy_v2/readme.md) |
| **策略 V3 (高级网格交易)** | `v5.3.13` | 功能最全面的网格交易策略。支持动态网格、金字塔加仓、隔离模式、价格区间限制、价格偏差容忍度等高级特性。代码经过全面优化。 | 适合对网格交易有精细化控制需求、希望策略具备高度灵活性和鲁棒性的用户。 | [查看详情](./strategies/strategy_v3/readme.md) |
| **策略 V3.1 (改进版网格交易)** | `v9` | 在 V3 基础上进行改进和优化，提供统一的网格生成逻辑、多层次持仓同步、批量止盈和回测优化功能。集中化参数管理。 | 适合寻求更高效、更灵活的网格交易执行，并对参数管理有集中化需求的用户。 | [查看详情](./strategies/strategy_v3_1/readme.md) |

## 工具集成

项目包含多个辅助开发和分析的工具，位于 `tools/` 目录：

-   `field_inspector.moo`: 字段检查和验证工具。
-   `order_analyzer.moo`: 订单分析和统计工具。
-   `pricedata_collector.moo`: 价格数据采集工具。

## 文档结构

-   `docs/`: 项目文档目录
    -   `overview.md`: 项目整体概述和设计理念。
    -   `changelog.md`: 项目及各策略的详细版本更新记录。
    -   `Moomoo量化功能中常用的API函数及其用法.txt`: Moomoo 量化 API 参考文档。
    -   `Moomoo量化策略框架具体说明.txt`: Moomoo 策略框架说明。
    -   `commit_convention.md`: Git 提交信息规范。
-   `strategies/`: 策略实现目录，每个子目录包含一个独立的策略及其 `readme.md` 文件。
-   `tools/`: 辅助工具集目录。
-   `historical_orders/`: 策略生成的历史订单记录（通常被 `.gitignore` 忽略）。

## 最新更新

本项目持续进行功能增强和优化。最近的重要更新包括：

-   **策略 V3 (v5.3.13):** 新增价格偏差容忍度参数，允许用户更精细地控制市价与网格价格的偏离。同时，对代码进行了全面清理，移除了冗余变量和废弃方法，提升了代码质量和可维护性。
-   **策略 V3.1 (v9):** 引入了更高效的持仓同步机制和批量止盈功能，支持回测模式优化，提升了策略的运行效率和灵活性。
-   **策略 V2 (v6.1):** 增强了订单同步机制的稳健性，添加了 fallback 逻辑以处理订单信息延迟问题。
-   **策略 V1 (v1.1.0):** 优化了回测模式下的订单与成交日志，确保与实盘日志格式一致，便于回测分析。

更多详细的更新记录，请查阅 [changelog](./docs/changelog.md)。

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for full details.

You are free to use, modify, and distribute this project under the terms of the Apache License 2.0.