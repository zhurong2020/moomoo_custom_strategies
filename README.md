# moomoo_custom_strategies
This repository contains version-controlled custom quantitative strategies for the moomoo client

本项目包含基于网格交易原则实现的多个量化策略。每个策略具有不同的参数和应用场景。

## ⚠️ 免责声明 | Disclaimer

### 中文声明
本项目仅供学习和研究使用，不构成任何投资建议或交易指导。请注意：

1. 作者不是专业的投资顾问或理财规划师，本项目中的所有策略均基于个人研究和实践经验。
2. 量化交易存在固有风险，包括但不限于市场风险、流动性风险、技术风险等。
3. 任何人使用本项目中的代码进行实盘交易需自行承担全部风险和后果。
4. 策略的历史表现不代表未来收益，任何基于本项目进行的交易决策需要使用者自行判断和负责。
5. 在使用本项目代码进行实盘交易前，强烈建议：
   - 充分了解量化交易的原理和风险
   - 仔细阅读并理解代码的具体实现
   - 使用模拟盘进行充分测试
   - 根据个人风险承受能力调整参数
   - 合理控制仓位和资金规模

### English Disclaimer
This project is for educational and research purposes only. Please be aware:

1. The author is not a professional financial advisor, and all strategies are based on personal research and experience.
2. Quantitative trading involves inherent risks, including but not limited to market risk, liquidity risk, and technical risk.
3. Anyone who uses the code in this project for live trading does so at their own risk and is solely responsible for any consequences.
4. Past performance does not guarantee future results. All trading decisions based on this project require users' own judgment and responsibility.
5. Before using this code for live trading, it is strongly recommended to:
   - Fully understand the principles and risks of quantitative trading
   - Carefully read and understand the code implementation
   - Conduct thorough testing using paper trading
   - Adjust parameters according to personal risk tolerance
   - Maintain reasonable position and capital management

## 策略总览

### [Strategy V3](./strategies/strategy_v3/readme.md)
- 统一网格间距和盈利标准的改进版本
- 引入线程安全的持仓管理机制
- 支持批量订单执行
- 完善的持仓验证和自动修正系统
- 详细的运行日志和错误处理
- 支持隔离模式（默认开启）实现策略与实际持仓分离
- 价格区间限制功能，增强风险控制
- 金字塔加仓策略支持
- 最新版本：v5.3.8

### [Strategy V2](./strategies/strategy_v2/readme.md)
- 简化的网格重置逻辑
- 改进的持仓跟踪系统
- 基础的风险控制机制
- 订单管理优化

### [Strategy V1](./strategies/strategy_v1/readme.md)
- 基础网格交易功能实现
- 简单的网格价格计算
- 基本持仓跟踪系统
- 配置文件支持

## 工具集成

项目包含多个辅助工具，位于 `tools/` 目录：

- `field_inspector.moo`: 字段检查和验证工具
- `order_analyzer.moo`: 订单分析和统计工具
- `pricedata_collector.moo`: 价格数据采集工具

## 文档结构

- `docs/`: 项目文档目录
  - `overview.md`: 项目概述和设计理念
  - `changelog.md`: 版本更新记录
- `historical_orders/`: 历史订单记录
- `strategies/`: 策略实现目录
  - `strategy_v3/`: 最新的网格交易策略（v5.3.8），支持隔离模式和价格区间限制
  - `strategy_v2/`: 简化版网格交易策略
  - `strategy_v1/`: 基础网格交易策略
- `tools/`: 工具集目录

## 版本控制

每个策略版本都有独立的目录和配置文件，便于进行版本管理和策略回溯。详细的更新记录请参考 [changelog](./docs/changelog.md)。

## 最新更新（v5.3.8）

- 默认启用隔离模式，更好地处理持仓同步问题
- 增加价格区间限制功能，增强风险控制
- 改进持仓统计和验证机制
- 优化策略文档和使用说明

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.