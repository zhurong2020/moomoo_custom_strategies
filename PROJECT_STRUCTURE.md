# Moomoo Custom Strategies - Project Structure

## 📁 Project Organization

### `/strategies/` - Core Strategy Files
```
strategies/
├── dca_free_v2.quant              # 🎯 Main DCA strategy (v2.2.0-Enhanced)
├── dca_advanced_v2.quant          # 💎 Advanced DCA with 8-layer system  
├── orders_his.csv                 # 📊 Historical orders data (251 days)
├── dca-free_20250828121355.csv    # 📋 Backtest execution log
├── README_three_tiers.md          # 📖 Three-tier system documentation
├── strategy_v1/                   # 🗂️ Legacy V1 implementation
├── strategy_v2/                   # 🗂️ Legacy V2 implementation  
├── strategy_v3/                   # 🗂️ Legacy V3 implementation
└── strategy_v3_1/                 # 🗂️ Legacy V3.1 implementation
```

### `/tools/` - Development & Analysis Tools  
```
tools/
├── validate_dca_logic.py          # ✅ Complete strategy validation
├── compare_interval_performance.py # 📊 Daily vs weekly performance test
├── analyze_performance_gap.py     # 🔍 Performance gap analysis
├── extract_spy_prices.py          # 💹 Price data extraction utility
├── test_qty_logic.py              # 🧪 Quantity parameter testing
├── spy_data_fetcher.py            # 🌐 Yahoo Finance data fetcher
├── field_inspector.moo            # 🔧 Moomoo field inspection
├── order_analyzer.moo             # 📈 Order analysis utility
└── pricedata_collector.moo        # 💾 Price data collection
```

### `/data/` - Test Data & Analysis Results
```
data/
├── spy_price_history.json         # 📊 251 days SPY price data
├── spy_price_history.csv          # 📊 CSV format price data  
├── spy_statistics.json            # 📈 Market statistics
├── dca_validation_report.json     # ✅ Strategy validation results
└── interval_comparison_report.json # 📊 Daily vs weekly comparison
```

### `/docs/` - Documentation & Planning
```
docs/
├── enhanced_tiered_features.md    # 🎯 Enhanced tiered system design
├── next_phase_plan.md             # 🚀 Development roadmap
├── project_progress_log.md        # 📋 Development history
├── tiered_system_planning.md      # 💰 Business tier planning
├── revised_system_planning.md     # 🔄 Updated system plans
├── overview.md                    # 📖 Project overview
├── changelog.md                   # 📝 Version history
├── commit_convention.md           # 📏 Git commit standards
├── Moomoo量化策略框架具体说明.txt    # 📚 Moomoo framework docs
└── Moomoo量化功能中常用的API函数及其用法.txt # 🔧 API reference
```

## 🎯 Current Status (v2.2.0-Enhanced)

### ✅ Completed Features
- **Tiered Strategy System**: Free (weekly) vs Paid (daily) intervals
- **Custom Balance Control**: System default vs user-defined (10K-500K)
- **Smart Position Sizing**: 3-layer drawdown protection with multipliers
- **Performance Validation**: Data-driven commercial value proposition
- **Comprehensive Testing**: 251-day historical backtesting

### 📊 Key Performance Metrics  
- **Daily DCA vs Weekly DCA**: +4.1% return advantage (18.2% vs 14.1%)
- **Average Cost Efficiency**: $529.60 vs $548.73 per share
- **Commercial ROI**: 5800%+ (¥35/month fee vs $2,050 additional gains)

## 🔒 Security & Privacy

### Excluded from Git (`.gitignore`)
```
# Business-sensitive documents (PROTECTED)
docs/community_commercialization_plan.md  # 💼 Business model details
docs/vip_tier_specifications.md           # 👑 VIP tier specifications
docs/business_*.md                         # 💰 All business documents
**/revenue_*, **/monetization_*            # 💵 Financial projections
config/private_*, *.key, *.secret          # 🔐 Private configs & keys
```

### Public Documentation (Safe to share)
- Strategy code and logic
- Technical documentation  
- Performance analysis tools
- Market data and test results

## 🚀 Development Workflow

### Version Control Standards
- **Main Branch**: `main` (stable releases)  
- **Commit Convention**: `feat:`, `fix:`, `docs:`, `test:`
- **Version Format**: `vX.Y.Z-Tier` (e.g., v2.2.0-Enhanced)

### Testing Standards
- All strategy changes must pass validation tests
- Performance comparisons required for tier modifications  
- Backtest validation with real market data (251+ days)

### Release Process
1. Feature development & testing
2. Performance validation & comparison
3. Documentation updates
4. Version increment & commit
5. Business-sensitive data review

## 📈 Commercial Tiers

### 🆓 Free Tier
- Weekly DCA intervals
- System default balance
- Basic drawdown monitoring
- 3-layer risk alerts

### 💎 Paid Tier (¥35/month)
- Daily DCA intervals (+4.1% performance)
- Custom balance (10K-500K)
- Smart 3-layer position sizing
- Advanced parameter controls

### 👑 VIP Tier (¥500+/year)  
- 8-layer complete protection system
- Cost-based DCA algorithm
- Multi-asset portfolio management
- Professional reporting & analysis

## 🛠️ Development Environment

### Required Dependencies
- Python 3.8+ (for analysis tools)
- Moomoo Quantitative Trading Platform
- Git for version control

### Optional Tools
- JSON viewers for report analysis
- CSV processors for data manipulation
- Text editors with Python syntax highlighting

## 📞 Support & Maintenance

### Code Ownership
- **Core Strategy**: Maintained by lead developer
- **Analysis Tools**: Community contributions welcome
- **Documentation**: Regular updates with new features

### Issue Tracking
- Strategy bugs: High priority fixes
- Performance optimizations: Regular review cycle
- Feature requests: Tier-based prioritization