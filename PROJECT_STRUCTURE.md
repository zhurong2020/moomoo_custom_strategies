# Moomoo Custom Strategies - Project Structure

## 📁 Project Organization

### `/strategies/` - Core Strategy Files (阶段性演进架构)
```
strategies/
├── dca_free_stable.quant          # 🆓 免费稳定版 - 公开分发
├── dca_premium_stable.quant       # 💎 付费稳定版 - 私有分发 (.gitignore保护)
├── dca_free_v2.quant              # 🔧 混合开发版 - 开发调试用
├── dca_advanced_v2.quant          # 👑 VIP原型版 - 未来APP参考
├── README.md                      # 📖 策略架构和维护说明
├── orders_his.csv                 # 📊 历史订单数据 (251天)
├── dca-free_20250828121355.csv    # 📋 回测执行日志
├── strategy_v1/                   # 🗂️ 历史版本 V1
├── strategy_v2/                   # 🗂️ 历史版本 V2
├── strategy_v3/                   # 🗂️ 历史版本 V3
└── strategy_v3_1/                 # 🗂️ 历史版本 V3.1
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

## 🎯 Current Status (阶段性演进架构)

### ✅ 已完成功能
- **双版本稳定架构**: 免费版(每周) vs 付费版(每日+智能加仓)
- **商业模式保护**: .gitignore保护付费版，分发渠道分离
- **性能数据验证**: 251天真实市场数据验证+4.1%收益优势
- **用户体验优化**: 简化参数，专注稳定性和易用性
- **技术支持体系**: 免费版社区支持，付费版专属服务

### 📊 核心性能指标  
- **每日定投 vs 每周定投**: +4.1%收益优势 (18.2% vs 14.1%)
- **平均成本效率**: $529.60 vs $548.73 每股
- **商业投资回报**: 5800%+ (¥35/月费用 vs $2,050额外收益)
- **架构稳定性**: 双文件维护，bug同步机制

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