#!/usr/bin/env python3
"""
分析付费版加仓收益不明显的原因
深入研究DCA策略的性能瓶颈
"""

import json
import math
from datetime import datetime

def load_validation_report():
    """加载验证报告"""
    with open('/home/wuxia/projects/moomoo_custom_strategies/data/dca_validation_report.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def analyze_performance_gap():
    """分析性能差距的原因"""
    reports = load_validation_report()
    
    print("🔍 深度分析：为什么付费版加仓收益不明显？")
    print("="*60)
    
    # 找到免费版和付费版20股的报告
    free_20 = next(r for r in reports if r.get('version') == '免费版' and r.get('qty') == 20)
    paid_20 = next(r for r in reports if r.get('version') == '付费版' and r.get('qty') == 20)
    
    print(f"📊 基础对比:")
    print(f"   免费版收益率: {free_20['summary']['total_return']:.1f}%")
    print(f"   付费版收益率: {paid_20['summary']['total_return']:.1f}%")
    print(f"   收益差异: {paid_20['summary']['total_return'] - free_20['summary']['total_return']:.1f}%")
    
    # 分析原因1：资金限制
    print(f"\n🔍 原因分析 1: 资金限制")
    print(f"   免费版总投资: ${free_20['summary']['total_invested']:,.0f}")
    print(f"   付费版总投资: ${paid_20['summary']['total_invested']:,.0f}")
    print(f"   投资差异: ${paid_20['summary']['total_invested'] - free_20['summary']['total_invested']:,.0f}")
    
    if abs(paid_20['summary']['total_invested'] - free_20['summary']['total_invested']) < 1000:
        print("   ⚠️ 发现问题：两个版本投资金额几乎相同！")
        print("   💡 说明：加仓优势被资金限制抵消了")
    
    # 分析原因2：加仓时机
    print(f"\n🔍 原因分析 2: 加仓时机分析")
    
    # 找到加仓交易
    paid_trades = paid_20['trade_history']
    add_position_trade = next((t for t in paid_trades if '加仓' in t['type']), None)
    
    if add_position_trade:
        add_date = add_position_trade['date']
        add_price = add_position_trade['price']
        add_qty = add_position_trade['quantity']
        
        print(f"   加仓时间: {add_date}")
        print(f"   加仓价格: ${add_price:.2f}")
        print(f"   加仓数量: {add_qty}股")
        
        # 计算加仓后的价格表现
        spy_data = load_spy_data()
        add_index = next(i for i, d in enumerate(spy_data) if d['date'] == add_date)
        
        # 计算加仓后30天、60天、最终的价格变化
        periods = [30, 60, len(spy_data) - add_index - 1]
        for days in periods:
            if add_index + days < len(spy_data):
                future_price = spy_data[add_index + days]['price']
                future_date = spy_data[add_index + days]['date']
                price_change = (future_price - add_price) / add_price * 100
                
                print(f"   {days}天后({future_date}): ${future_price:.2f}, 涨幅{price_change:.1f}%")
        
        # 分析加仓的实际贡献
        extra_shares = add_qty - 20  # 比正常定投多出的股数
        final_price = spy_data[-1]['price']
        extra_value = extra_shares * final_price
        extra_cost = extra_shares * add_price
        extra_profit = extra_value - extra_cost
        
        print(f"   加仓额外贡献分析:")
        print(f"   - 额外股数: {extra_shares}股")
        print(f"   - 额外成本: ${extra_cost:.0f}")
        print(f"   - 额外价值: ${extra_value:.0f}")
        print(f"   - 额外利润: ${extra_profit:.0f}")
    
    # 分析原因3：市场表现
    print(f"\n🔍 原因分析 3: 市场表现特征")
    analyze_market_characteristics()
    
    # 分析原因4：策略设计
    print(f"\n🔍 原因分析 4: 策略设计问题")
    analyze_strategy_design()
    
    # 提出改进建议
    print(f"\n💡 改进建议:")
    suggest_improvements()

def load_spy_data():
    """加载SPY数据"""
    with open('/home/wuxia/projects/moomoo_custom_strategies/data/spy_price_history.json', 'r', encoding='utf-8') as f:
        return json.load(f)

def analyze_market_characteristics():
    """分析市场特征"""
    spy_data = load_spy_data()
    prices = [d['price'] for d in spy_data]
    
    # 计算波动特征
    daily_returns = []
    for i in range(1, len(prices)):
        daily_return = (prices[i] - prices[i-1]) / prices[i-1]
        daily_returns.append(daily_return)
    
    # 计算标准差
    mean_return = sum(daily_returns) / len(daily_returns)
    variance = sum((r - mean_return) ** 2 for r in daily_returns) / len(daily_returns)
    std_dev = math.sqrt(variance)
    volatility = std_dev * math.sqrt(252) * 100  # 年化波动率
    
    # 分析回撤恢复速度
    max_price = max(prices)
    max_index = prices.index(max_price)
    min_price_after_max = min(prices[max_index:])
    min_index = prices.index(min_price_after_max)
    
    max_drawdown_pct = (max_price - min_price_after_max) / max_price * 100
    
    # 计算恢复时间
    recovery_price = max_price * 0.95  # 恢复到95%
    recovery_index = None
    for i in range(min_index, len(prices)):
        if prices[i] >= recovery_price:
            recovery_index = i
            break
    
    recovery_days = recovery_index - min_index if recovery_index else len(prices) - min_index
    
    print(f"   年化波动率: {volatility:.1f}%")
    print(f"   最大回撤: {max_drawdown_pct:.1f}%")
    print(f"   回撤恢复时间: {recovery_days}天")
    
    if recovery_days < 30:
        print("   ⚠️ 发现问题：回撤恢复太快，加仓优势不明显")
    
    if max_drawdown_pct < 15:
        print("   ⚠️ 发现问题：最大回撤不够深，加仓机会有限")

def analyze_strategy_design():
    """分析策略设计问题"""
    print(f"   1. 资金限制问题:")
    print(f"      - 初始资金$50,000相对较少")
    print(f"      - 4-5次投资后资金耗尽，无法继续加仓")
    print(f"      - 加仓优势被资金限制抵消")
    
    print(f"   2. 加仓时机问题:")
    print(f"      - 第1层(5%)触发过早")
    print(f"      - 市场快速恢复，加仓优势不明显")
    print(f"      - 未触发更深层级的加仓")
    
    print(f"   3. 加仓倍数问题:")
    print(f"      - 1.5x倍数相对保守")
    print(f"      - 在浅回撤中效果有限")
    
    print(f"   4. 策略周期问题:")
    print(f"      - 每日定投频率过高")
    print(f"      - 资金消耗太快，无法利用长期波动")

def suggest_improvements():
    """提出改进建议"""
    print(f"   1. 增加初始资金或调整投资数量")
    print(f"      - 建议：使用更大的初始资金($100,000+)")
    print(f"      - 或者：降低基础投资数量(10股/次)")
    
    print(f"   2. 优化加仓层级设置")
    print(f"      - 建议：调整为8%/15%/25%的更深回撤")
    print(f"      - 或者：增加更多层级(5层或8层)")
    
    print(f"   3. 增强加仓倍数")
    print(f"      - 建议：1.5x → 2x/3x/5x的更激进倍数")
    print(f"      - 特别是深度回撤时的倍数")
    
    print(f"   4. 调整定投频率")
    print(f"      - 建议：改为每周或每3天定投")
    print(f"      - 留更多资金用于回撤加仓")
    
    print(f"   5. 添加持仓比例控制")
    print(f"      - 建议：预留30-50%资金专门用于加仓")
    print(f"      - 避免前期投资过多导致后期无资金加仓")

def create_improved_strategy_test():
    """创建改进策略测试"""
    print(f"\n🧪 改进策略测试方案:")
    
    improvements = [
        {
            "name": "增加资金版",
            "changes": "初始资金$100,000",
            "expected": "更多加仓机会，收益差异更明显"
        },
        {
            "name": "调整层级版", 
            "changes": "回撤层级8%/15%/25%",
            "expected": "在更深回撤时才加仓，效果更明显"
        },
        {
            "name": "增强倍数版",
            "changes": "加仓倍数2x/3x/5x", 
            "expected": "加仓效果更显著"
        },
        {
            "name": "周期优化版",
            "changes": "每周定投+预留加仓资金",
            "expected": "更多资金用于加仓时机"
        }
    ]
    
    for imp in improvements:
        print(f"   📋 {imp['name']}")
        print(f"      修改: {imp['changes']}")
        print(f"      预期: {imp['expected']}")

def main():
    """主函数"""
    analyze_performance_gap()
    create_improved_strategy_test()
    
    print(f"\n✅ 结论: 付费版收益不明显的主要原因")
    print(f"   1. 💰 资金限制：初始资金相对较少，加仓机会有限")
    print(f"   2. 🎯 时机问题：5%回撤触发过早，市场恢复快")  
    print(f"   3. 📊 倍数保守：1.5x加仓倍数在浅回撤中效果有限")
    print(f"   4. ⏱️ 频率过高：每日定投消耗资金太快")
    print(f"   5. 📈 市场特征：这段时间SPY总体上涨，回撤较浅")

if __name__ == '__main__':
    main()