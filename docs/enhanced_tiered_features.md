# DCA策略增强分层功能设计

## 🎯 设计理念
- **免费版**: 基础体验，核心功能演示，参数受限
- **付费版**: 完整功能，参数可调，策略增强
- **VIP版**: 专业级别，完全自定义，高级算法

## 📊 当前问题分析

### 回测参数问题
- ❌ 用户无法设置初始资金
- ❌ 依赖Moomoo系统默认设置
- ❌ 无法控制回测时间范围
- ❌ K线周期固定为日线
- ❌ 无法调整风险偏好

## 🚀 分层功能设计方案

### 第1层：免费基础版 (🆓 Free)
**目标**: 让用户体验核心价值，建立信任

#### 基础参数 (用户可见但受限)
```python
# 资金设置
self.initial_balance_mode = show_variable(1, GlobalType.INT)  # 1=系统默认 2=自定义(付费版)
self.custom_balance = 10000  # 显示但不可用

# 投资参数  
self.qty = show_variable(20, GlobalType.INT)  # 10-50股范围
self.interval_mode = show_variable(1, GlobalType.INT)  # 1=每日 2=每周(付费版)

# 风险设置
self.risk_level = show_variable(1, GlobalType.INT)  # 1=保守 2=平衡(付费版) 3=积极(VIP)
```

#### 固定功能特性
- ✅ 基础定投 (每日，固定数量)
- ✅ 3层回撤监控 (5%/10%/20%)
- ✅ 风险提醒系统
- ✅ 基础统计报告
- ❌ 智能加仓 (仅提醒，不执行)
- ❌ 参数优化
- ❌ 高级时间控制

#### 升级引导
```python
if drawdown >= 10.0:
    print("⚠️ 免费版风险提醒: 当前回撤10.1%")
    print("💡 付费版在此时会自动加仓2倍，降低平均成本")
    print("💰 预计可提升收益15-30%，联系作者升级(¥35/月)")
```

### 第2层：付费进阶版 (💎 Advanced ¥35/月)
**目标**: 提供完整的智能定投体验

#### 解锁参数控制
```python
# 资金管理
self.initial_balance_mode = show_variable(2, GlobalType.INT)  # 可选自定义
self.custom_balance = show_variable(50000, GlobalType.INT)  # 10K-500K范围
self.reserve_ratio = show_variable(30, GlobalType.INT)  # 预留资金比例0-50%

# 时间控制
self.interval_mode = show_variable(2, GlobalType.INT)  # 1=每日 2=每周 3=自定义
self.custom_interval_hours = show_variable(24, GlobalType.INT)  # 1-168小时
self.kline_period = show_variable(1, GlobalType.INT)  # 1=日线 2=小时线(VIP)

# 加仓策略
self.enable_smart_position = show_variable(True, GlobalType.BOOL)
self.drawdown_sensitivity = show_variable(2, GlobalType.INT)  # 1=保守 2=标准 3=激进(VIP)
```

#### 智能功能
- ✅ 3层智能加仓系统 (5%/10%/20% → 1.5x/2x/3x)
- ✅ 资金预留管理
- ✅ 自定义投资周期
- ✅ 动态仓位调整
- ✅ 回测报告导出
- ✅ 月度收益分析
- ❌ 成本定投算法 (VIP功能)
- ❌ 多标的投资 (VIP功能)

#### 参数预设模板
```python
sensitivity_templates = {
    1: {"layers": [8, 15, 25], "multipliers": [1.5, 2.0, 3.0]},  # 保守
    2: {"layers": [5, 10, 20], "multipliers": [1.5, 2.0, 3.0]},  # 标准  
    3: {"layers": [3, 8, 15], "multipliers": [2.0, 3.0, 5.0]}   # 激进(VIP)
}
```

### 第3层：VIP专业版 (👑 Professional ¥500+/年)
**目标**: 专业投资者的完整解决方案

#### 完全解锁参数
```python
# 高级资金管理
self.portfolio_mode = show_variable(True, GlobalType.BOOL)  # 多标的组合
self.rebalance_enabled = show_variable(True, GlobalType.BOOL)  # 自动再平衡
self.max_position_pct = show_variable(80, GlobalType.INT)  # 最大仓位比例

# 高级时间控制
self.kline_period = show_variable(2, GlobalType.INT)  # 1=日线 2=小时线 3=分钟线
self.market_timing = show_variable(True, GlobalType.BOOL)  # 择时功能
self.volatility_filter = show_variable(True, GlobalType.BOOL)  # 波动率过滤

# 专业加仓系统
self.use_cost_dca = show_variable(True, GlobalType.BOOL)  # 成本定投算法
self.max_layers = show_variable(8, GlobalType.INT)  # 最多8层保护
self.custom_multipliers = "2,3,4,5,6,8,10,15"  # 自定义倍数
```

#### 专业功能
- ✅ 8层完整回撤保护系统
- ✅ 成本定投算法 (基于持仓成本动态调整)
- ✅ 波动率自适应调整
- ✅ 多标的组合投资
- ✅ 小时线/分钟线支持
- ✅ 高级择时功能
- ✅ 完整风险管理
- ✅ 专业报告和分析
- ✅ API接口和自动化

## 🔧 技术实现建议

### 1. 资金管理增强
```python
def initialize_balance(self):
    """初始化资金管理"""
    if self.version_tier >= 2 and self.initial_balance_mode == 2:
        # 付费版：使用自定义资金
        self.virtual_balance = self.custom_balance
        self.reserved_balance = self.custom_balance * (self.reserve_ratio / 100)
        self.available_balance = self.virtual_balance - self.reserved_balance
    else:
        # 免费版：使用系统默认
        self.virtual_balance = total_cash(currency=Currency.USD)
        self.reserved_balance = 0
        self.available_balance = self.virtual_balance
```

### 2. 参数验证和引导
```python
def validate_tier_features(self):
    """验证版本功能权限"""
    if self.version_tier == 1:  # 免费版限制
        if self.qty > 50:
            print("💡 免费版投资数量限制50股，付费版可达1000股")
            self.qty = 50
        
        if self.interval_mode > 1:
            print("💡 免费版仅支持每日定投，付费版支持自定义周期")
            self.interval_mode = 1
            
    elif self.version_tier == 2:  # 付费版限制
        if self.risk_level == 3:
            print("💡 激进模式为VIP专享，当前使用标准模式")
            self.risk_level = 2
```

### 3. 功能分层展示
```python
def print_feature_comparison(self):
    """显示功能对比，引导升级"""
    features = {
        "基础定投": ["✅", "✅", "✅"],
        "智能加仓": ["❌", "✅", "✅"], 
        "自定义资金": ["❌", "✅", "✅"],
        "高级参数": ["❌", "✅", "✅"],
        "成本算法": ["❌", "❌", "✅"],
        "多标的投资": ["❌", "❌", "✅"],
        "专业报告": ["❌", "✅", "✅"]
    }
    
    print("📊 功能对比:")
    print("功能\t\t免费版\t付费版\tVIP版")
    for feature, support in features.items():
        print(f"{feature}\t{support[0]}\t{support[1]}\t{support[2]}")
```

## 🎯 用户体验设计

### 渐进式解锁体验
1. **免费版**: 体验核心价值 → 看到加仓机会 → 产生升级欲望
2. **付费版**: 完整功能 → 看到专业功能 → 考虑VIP升级
3. **VIP版**: 专业工具 → 持续价值 → 长期订阅

### 实时引导提示
- 回撤时提示付费版加仓效果
- 参数受限时提示解锁方案
- 成功案例分享和收益对比

## 📈 商业化优势
1. **差异化明显**: 每个层级都有独特价值
2. **升级路径清晰**: 功能限制驱动付费意愿
3. **长期粘性**: 专业功能形成依赖
4. **口碑传播**: 免费版质量保证推广效果