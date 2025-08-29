# Changelog

All notable changes to this project will be documented in this file.

## [Current Release - v2.2.5-Stable] - 2025-08-29

### Enhanced (参数优化版本)
- **参数类型修复：** 修复basic_invest_only布尔值类型处理，添加int→bool自动转换
- **GUI兼容性增强：** 完善参数验证显示，增加类型检查和调试信息
- **功能验证完成：** 通过SPY回测全面验证核心商业功能

### Validated Features (已验证功能)
**版本功能验证 ✅**
- 免费版每周定投：version_tier=1, 每周20股定投正常
- 付费版每日定投：version_tier=2, 1440分钟周期每日执行

**预设模板验证 ✅** 
- 保守型预设：preset_mode=1, qty自动调整20→10股
- 平衡型预设：preset_mode=2, qty保持默认20股  
- 积极型预设：preset_mode=3, qty自动调整20→50股

**资金管理验证 ✅**
- 系统默认资金：balance_mode=1, 使用系统账户余额
- 自定义资金：balance_mode=2, 使用custom_balance设定值($50,000验证)

**回测验证数据 ✅**
- 测试标的：SPY (标普500 ETF)
- 测试时间：2025年7月1-31日
- 投资执行：100%成功率，订单全部正常成交
- 计算准确性：虚拟余额、持仓统计、成本计算全部正确

### Technical Validation Summary
- 核心功能完成度：95% (商业分层逻辑完整)
- 初始化稳定性：100% (5阶段流程稳定)
- GUI参数兼容性：优秀 (支持各种参数组合)
- 异常处理能力：完善 (qty=1修正、类型转换等)

*注：剩余5%功能(纯定投模式、回撤加仓场景)待后续版本完善*

## [混合开发版 v2.2.4-FixedInit] - 2025-08-29
### Fixed (Major Release)
- **初始化顺序重构：** 修复5阶段初始化流程，解决setup_presets在interval_min未定义前调用的AttributeError
- **参数验证增强：** 新增print_global_variables()调试功能，识别和修正qty=1等show_variable异常返回值
- **异常处理完善：** 添加完整的fallback机制和详细错误日志，确保初始化稳定性
- **虚拟余额保护：** 增强None值检查和自动默认值设置，防止余额计算错误

### Added
- **调试工具：** 新增详细的初始化状态打印和参数验证功能
- **混合开发版工作流：** 添加MIXED_DEVELOPMENT_WORKFLOW.md文档和测试工具
- **参数修正机制：** 运行时自动修正异常参数值（如qty=1→20）

### Technical Notes
- 策略测试验证：SPY回测5周，所有功能正常运行
- 免费版每周定投：正确执行20股×5次=100股定投
- 商业功能分层：version_tier参数控制免费版/付费版功能正常

*注：当前架构为三文件分离：dca_free_public.quant（开源）、dca_premium_moomoo.quant（授权）、dca_dev_mixed.quant（开发）*

## [Documentation Update] - 2025-08-24
### Updated
- **主README文件：** 更新策略总览表格，补充各策略最新特性和版本信息
- **项目概述文档：** 增强主要功能特性描述，添加订单稳定性和价格偏差容忍度等新特性
- **策略V3.1文档：** 补充回测优化参数说明和版本更新记录
- **最新更新记录：** 重新整理各策略版本更新要点，突出关键改进

## [strategy_v3 v5.3.13] - 2025-07-06
### Added
- **价格偏差容忍度：** 新增 `price_deviation_tolerance_multiplier` 全局变量，允许用户调整市价与网格价格的最大偏离容忍度，以更精细地控制成交价格。

## [strategy_v3 v5.3.12] - 2024-11-21
### Refactor
- **代码清理：** 移除了未使用的 `max_capital_usage` 变量，以及 `_check_profit_before_reset`、`_execute_batch_sell`、`_clean_empty_high_grids` 等冗余方法，并修正了 `handle_data` 中重复的 `_check_high_grid_profit` 调用，使代码更加精简高效。

## [strategy_v3_1 v9] - 2024-11-25
### Added
- Introduced `enable_position_sync_in_backtest` parameter to allow skipping position synchronization during backtesting
- Improved backtest performance by reducing computational overhead, especially for long-duration and high-frequency (e.g., 5-minute) intervals
- Maintained full functionality in live trading mode while providing flexibility in backtest environments
- Enhanced position synchronization mechanism to support both live and backtest modes
- Updated README documentation with detailed parameter descriptions and usage instructions

## [strategy_v1 v1.1.0] - 2025-06-12
### Fixed
- 【修复】回测模式下，加仓（回撤分层加仓）和定投的模拟下单与成交日志完全一致，均输出完整的“订单状态/成交状态/全部成交”流程，便于回测与实盘对齐分析。
### Optimized
- 【优化】加仓和定投均调用 place_market 进行模拟下单，日志格式与实盘完全一致。
### Note
- 【说明】本版本为长期维护主线，建议所有用户升级。

## [strategy_v3 v5.3.10] - 2024-11-21
### Added
- Enhanced grid trading strategy with improved position management
- Added price range validation for trading operations
- Enabled isolation mode by default for better position handling
- Updated documentation with new features and parameters
### Fixed
- Position synchronization issues in isolation mode
- Price range and position statistics calculation errors

## [strategy_v3] - 2024-11-21
### Added
- Created strategy_v3 with improved grid trading implementation
- Added comprehensive README documentation with detailed technical specifications
- Enhanced position management with thread-safe mechanisms
- Implemented batch order execution system
- Added automated position verification and correction

## [strategy_v2] - 2024-11-19
### Added
- Created strategy_v2 with unified grid spacing logic
- Simplified grid reset mechanism
- Added position tracking and order management
- Created dedicated README for strategy documentation

## [strategy_v1] - 2024-11-04
### Added
- Initial implementation of grid trading strategy
- Basic grid price calculation and management
- Simple position tracking system
- Configuration file support
- Basic logging functionality

## [Initial Commit] - 2024-11-04
### Added
- Project structure setup
- Basic documentation files
- License file
- Tool utilities for strategy development:
  - field_inspector.moo
  - order_analyzer.moo
  - pricedata_collector.moo
