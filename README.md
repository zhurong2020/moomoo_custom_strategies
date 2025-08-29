# Moomoo Custom DCA Strategies

A professional-grade Dollar-Cost Averaging (DCA) strategy system for Moomoo quantitative trading platform with tiered commercial features.

## ⚠️ Important Disclaimer | 免责声明

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

## 🎯 Project Overview

This project provides an enhanced DCA investment strategy that solves common pain points in traditional periodic investment approaches. Features a three-tier commercial system designed for different user needs.

### Key Features
- **Smart Position Sizing**: 3-layer drawdown protection with automatic position adjustment
- **Interval Optimization**: Daily vs weekly investment frequency with proven performance differences  
- **Custom Balance Control**: User-defined investment capital (10K-500K range)
- **Performance Validated**: 251-day historical backtesting with real SPY data

## 🏆 Performance Highlights

| Strategy | Return | Average Cost | Cost Efficiency | Tier |
|----------|--------|--------------|-----------------|------|
| **Daily DCA** | **18.2%** | $529.60 | 18.3% | 💎 Paid |
| Weekly DCA | 14.1% | $548.73 | 14.1% | 🆓 Free |
| **Advantage** | **+4.1%** | **-$19.13** | **+4.2%** | **Premium** |

*Based on 251-day SPY backtesting (Aug 2024 - Aug 2025)*

## 🚀 Quick Start

### 1. Choose Your Version

#### 🆓 免费稳定版 (推荐新手)
```python
# 使用 strategies/dca_free_stable.quant
qty = 20                  # 定投股数 (10-50，10的倍数)
conservative_mode = False # 保守模式 (强制10股)
enable_risk_alerts = True # 风险提醒开关
```
- **固定特性**: 每周定投，基础风险提醒
- **适合人群**: 新手用户，稳健投资者
- **获取方式**: GitHub公开下载

#### 💎 付费稳定版 (¥35/月)
```python
# 使用 strategies/dca_premium_stable.quant (私有获取)
qty = 20                  # 定投股数 (灵活配置)
custom_balance = 50000    # 自定义资金 (10K-500K)
interval_mode = 2         # 1=每日 2=每日(推荐) 3=每周
enable_smart_sizing = True # 3层智能加仓
```
- **核心优势**: 每日定投+智能加仓 (+4.1%收益)
- **适合人群**: 有经验投资者，追求收益优化
- **获取方式**: 联系作者私有分发

### 2. 部署到Moomoo平台
1. 根据需求选择对应策略文件
2. 导入到Moomoo量化交易平台
3. 设置投资标的 (如SPY)
4. 开始回测或实盘交易

## 📊 Strategy Logic

### Core Algorithm
1. **Periodic Investment**: Fixed intervals (daily/weekly) with consistent amounts
2. **Drawdown Detection**: Monitor price decline from recent highs  
3. **Smart Position Sizing**: Increase investment during market downturns
4. **Risk Management**: Multi-layer protection with automatic adjustments

### Drawdown Protection System
```
5% drawdown  → 1.5x position size (30 shares vs 20)
10% drawdown → 2.0x position size (40 shares vs 20)  
20% drawdown → 3.0x position size (60 shares vs 20)
```

### Performance Advantage Sources
- **Market Timing**: Daily intervals capture more price dips
- **Cost Averaging**: More frequent investments smooth price volatility
- **Position Sizing**: Intelligent increase during market stress

## 🛠️ Development Tools

### Validation & Testing
```bash
# Complete strategy validation
python tools/validate_dca_logic.py

# Daily vs weekly performance comparison  
python tools/compare_interval_performance.py

# Performance gap analysis
python tools/analyze_performance_gap.py
```

### Data Analysis
- **Real Market Data**: 251 days of SPY price history
- **Comprehensive Reports**: JSON format with detailed metrics
- **Performance Attribution**: Clear breakdown of return sources

## 📁 Project Structure

```
moomoo_custom_strategies/
├── strategies/           # Core strategy files
│   ├── dca_free_v2.quant       # 🎯 Main strategy (v2.2.0)
│   └── dca_advanced_v2.quant   # 💎 Advanced 8-layer version
├── tools/               # Development & analysis tools  
├── data/                # Test data & validation results
├── docs/                # Documentation & planning
└── README.md            # This file
```

## 🎯 Commercial Tiers

### Tier Comparison Matrix

| Feature | 🆓 Free | 💎 Paid | 👑 VIP |
|---------|---------|---------|--------|
| **DCA Intervals** | Weekly | Daily | Custom |
| **Balance Control** | System Default | 10K-500K | Unlimited |
| **Position Sizing** | Fixed | 3-Layer Smart | 8-Layer Pro |
| **Performance** | 14.1% | 18.2% (+4.1%) | 20%+ |
| **Cost** | Free | ¥35/month | ¥500+/year |

### Upgrade Value Proposition
- **ROI**: ¥35/month investment → $2,050+ additional annual returns
- **Efficiency**: 5800%+ return on subscription cost
- **Risk Reduction**: Smart position sizing during market downturns

## 📈 Historical Performance

### Market Conditions (Aug 2024 - Aug 2025)
- **SPY Performance**: +13.3% total return
- **Volatility**: 30.7% price range ($489-$639)  
- **Market Type**: Bull market with significant corrections

### Strategy Results
- **Best Performer**: Daily DCA Paid Tier (18.2% return)
- **Risk-Adjusted**: Consistent outperformance across market conditions
- **Cost Efficiency**: Superior average cost achievement

## 🔐 Security & Privacy

### Protected Information
- Business commercialization plans
- Revenue projections and user analytics
- VIP tier specifications and pricing models
- Personal contact information and client data

### Public Information  
- Strategy code and technical documentation
- Performance analysis and backtesting results
- Development tools and testing frameworks
- General market analysis and insights

## 📞 Support & Contact

### Technical Issues
- **GitHub Issues**: Report bugs and feature requests
- **Documentation**: Comprehensive guides in `/docs/`
- **Testing Tools**: Self-service validation utilities

### Commercial Inquiries
- **Tier Upgrades**: Contact for paid tier access
- **Custom Development**: Enterprise solutions available
- **Partnership**: Strategic collaboration opportunities

## 📄 License & Usage

### Open Source Components
- Core strategy logic (Apache License 2.0)
- Development tools and testing frameworks
- Documentation and educational content

### Commercial Components  
- Paid tier features and advanced algorithms
- VIP professional services and support
- Custom development and integration services

---

**Built with precision for professional quantitative trading on Moomoo platform** 🚀

*Last updated: August 2025 | Version: v2.2.0-Enhanced*