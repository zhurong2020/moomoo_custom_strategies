# Strategies目录整理说明

## 📁 整理后的目录结构

```
strategies/
├── 📄 README.md                       # 策略架构和维护说明
├── 📄 STRATEGY_ORGANIZATION.md        # 目录整理说明 (本文档)
│
├── 🎯 当前生产策略
│   ├── dca_free_stable.quant          # 🆓 免费稳定版 - 公开分发
│   ├── dca_premium_stable.quant       # 💎 付费稳定版 - 私有分发
│   └── dca_free_v2.quant              # 🔧 混合开发版 - 开发调试用
│
├── 📊 data/                            # 数据文件
│   └── backtests/                      # 回测数据
│       ├── dca-free_20250828121355.csv # 免费版回测执行日志
│       └── orders_his.csv              # 251天历史订单数据
│
└── 📦 archive/                         # 存档文件
    ├── dca_vip_reference.quant         # 👑 VIP版参考 (未来APP功能参考)
    ├── README_three_tiers.md           # 历史三层架构文档
    ├── key_algorithms_extraction.md    # 算法提取文档
    ├── migration_analysis.md           # 迁移分析文档
    └── legacy_versions/                # 历史版本存档
        ├── strategy_v1/                # V1版本
        ├── strategy_v2/                # V2版本  
        ├── strategy_v3/                # V3版本
        └── strategy_v3_1/              # V3.1版本
```

## 🎯 当前生产策略说明

### 1. `dca_free_stable.quant` - 免费稳定版
- **版本**: v1.0-Free-Stable
- **状态**: ✅ 生产就绪，公开分发
- **功能**: 每周定投 + 基础风险提醒
- **目标用户**: 新手投资者，稳健用户
- **分发渠道**: GitHub公开，技术文章推广

### 2. `dca_premium_stable.quant` - 付费稳定版  
- **版本**: v1.0-Premium-Stable
- **状态**: ✅ 生产就绪，私有分发
- **功能**: 每日定投 + 3层智能加仓 (+4.1%收益)
- **目标用户**: 有经验投资者，付费用户(¥35/月)
- **分发渠道**: 邮件私有分发，专属客服群
- **保护**: .gitignore自动保护，不会提交到公开仓库

### 3. `dca_free_v2.quant` - 混合开发版
- **版本**: v2.2.0-Enhanced  
- **状态**: 🔧 开发用，非分发文件
- **功能**: 包含免费+付费功能，用于开发调试
- **用途**: 功能测试，bug修复，新功能验证
- **注意**: 仅内部使用，不对外分发

## 📊 数据文件说明

### `data/backtests/`
- **`orders_his.csv`**: 251天真实SPY交易历史数据
  - 时间范围: 2024-08-01 至 2025-08-01
  - 用途: 策略验证，性能分析
  
- **`dca-free_20250828121355.csv`**: 免费版回测执行日志
  - 详细交易记录和策略执行过程
  - 用于调试和性能优化

## 📦 存档文件说明

### `archive/dca_vip_reference.quant`
- 原`dca_advanced_v2.quant`，8层VIP版本
- 作为未来APP功能开发的参考
- 包含高级功能原型代码

### `archive/legacy_versions/`
- **strategy_v1/**: 最早的策略版本
- **strategy_v2/**: V2迭代版本
- **strategy_v3/**: V3迭代版本  
- **strategy_v3_1/**: V3.1优化版本
- 保留完整的开发历史和文档

## 🛠️ 维护工作流

### 日常开发流程
1. **Bug发现** → 在`dca_free_v2.quant`中修复测试
2. **验证稳定** → 手动同步到两个稳定版本
3. **测试验证** → 确保功能一致性
4. **用户通知** → 更新日志和升级提醒

### 版本发布流程
1. **功能开发** → `dca_free_v2.quant`开发版
2. **稳定测试** → 充分验证功能稳定性
3. **版本同步** → 同步到对应稳定版本
4. **分发更新** → 按渠道分发给用户

### 文件保护机制
```bash
# .gitignore已配置保护
strategies/dca_premium_stable.quant  # 付费版保护
strategies/*premium*.quant           # 所有付费版本
```

## 🎯 未来计划

### 短期 (当前-Q2 2025)
- 维护双文件稳定版本
- 收集用户反馈优化
- bug修复和小版本更新
- 用户基数增长

### 中期 (Q3-Q4 2025) 
- 用户达到1000+时考虑重构
- 多平台适配调研
- 独立APP原型开发
- 参考`archive/dca_vip_reference.quant`

### 长期 (2026年+)
- 发布独立APP
- AI智能分析功能
- 参考存档中的高级功能
- 用户社区和生态建设

## 🔍 文件状态总览

| 文件 | 状态 | 用途 | 分发 | Git保护 |
|------|------|------|------|---------|
| `dca_free_stable.quant` | ✅ 生产 | 免费版 | 公开 | ❌ |
| `dca_premium_stable.quant` | ✅ 生产 | 付费版 | 私有 | ✅ |
| `dca_free_v2.quant` | 🔧 开发 | 调试 | 不分发 | ❌ |
| `archive/dca_vip_reference.quant` | 📦 存档 | 参考 | 不分发 | ❌ |
| `archive/legacy_versions/*` | 📦 存档 | 历史 | 不分发 | ❌ |

---

**整理完成时间**: 2025-08-28  
**整理原则**: 简化结构，明确分工，保护商业资产，便于维护 🎯