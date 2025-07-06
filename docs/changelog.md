# Changelog

All notable changes to this project will be documented in this file.

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
