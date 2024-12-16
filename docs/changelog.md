# Changelog

All notable changes to this project will be documented in this file.

## [strategy_v3_1] - 2024-11-25
### Added
- Introduced `enable_position_sync_in_backtest` parameter to allow skipping position synchronization during backtesting
- Improved backtest performance by reducing computational overhead, especially for long-duration and high-frequency (e.g., 5-minute) intervals
- Maintained full functionality in live trading mode while providing flexibility in backtest environments
- Enhanced position synchronization mechanism to support both live and backtest modes
- Updated README documentation with detailed parameter descriptions and usage instructions

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