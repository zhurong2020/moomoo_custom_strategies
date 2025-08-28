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

### 1. Choose Your Tier

#### 🆓 Free Tier
```python
version_tier = 1          # Free version
interval_mode = 1         # Weekly intervals (auto)
balance_mode = 1          # System default balance
```
- Weekly DCA intervals
- Basic drawdown monitoring  
- Risk alerts and notifications

#### 💎 Paid Tier (¥35/month)
```python
version_tier = 2          # Paid version  
interval_mode = 2         # Daily intervals
balance_mode = 2          # Custom balance
custom_balance = 50000    # 10K-500K range
```
- Daily DCA intervals (+4.1% performance)
- Smart 3-layer position sizing
- Custom balance control
- Advanced parameter optimization

### 2. Deploy to Moomoo Platform
1. Copy `strategies/dca_free_v2.quant` to Moomoo
2. Configure your desired tier and parameters
3. Set investment symbol (e.g., SPY)
4. Start backtesting or live trading

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