#!/usr/bin/env python3
"""
v2.5.0 五层回撤系统验证
验证免费版3层 vs 付费版5层的差异
测试极端回撤警告功能

Created: 2025-08-29
Version: 1.0
"""

class TestV250DrawdownSystem:
    """模拟v2.5.0的5层回撤系统"""
    
    def __init__(self, version_tier=1, aggressive_multiplier=1.0):
        self.version_tier = version_tier
        self.aggressive_multiplier = aggressive_multiplier
        self.effective_qty = 20
        
        # v2.5.0分层配置
        if version_tier == 1:  # 免费版
            self.drawdown_layers = [5.0, 10.0, 20.0]
            self.base_multipliers = [1.5, 2.0, 3.0]
        else:  # version_tier == 2 (付费版)
            self.drawdown_layers = [5.0, 10.0, 20.0, 35.0, 50.0] 
            self.base_multipliers = [1.5, 2.0, 3.0, 4.0, 5.0]
        
        self.drawdown_multipliers = [m * aggressive_multiplier for m in self.base_multipliers]
        self.extreme_drawdown_pct = 60.0
        self._extreme_drawdown_warned = False
    
    def calculate_add_position_qty(self, drawdown):
        """计算加仓数量 - v2.5.0版本"""
        # 检查极端回撤警告
        max_layer_threshold = self.drawdown_layers[-1]
        if drawdown > max_layer_threshold and drawdown >= self.extreme_drawdown_pct:
            if not self._extreme_drawdown_warned:
                print(f"   🚨 极端回撤警告: 当前回撤{drawdown:.1f}%超过第{len(self.drawdown_layers)}层({max_layer_threshold}%)")
                print("   📱 建议考虑VIP App的高级回撤管理功能")
                self._extreme_drawdown_warned = True
        
        # 从高层级开始检查
        for i in reversed(range(len(self.drawdown_layers))):
            threshold = self.drawdown_layers[i]
            if drawdown >= threshold:
                add_qty = int(self.effective_qty * self.drawdown_multipliers[i])
                return add_qty, i+1, threshold
        
        return 0, 0, 0

def test_5tier_comparison():
    """测试5层系统与3层系统对比"""
    
    print("="*80)
    print("🧪 v2.5.0 五层回撤系统对比测试")
    print("="*80)
    
    # 测试场景 (基于实际TSLA数据)
    test_scenarios = [
        {"drawdown": 17.8, "desc": "TSLA 17.8%回撤", "price": 401.53},
        {"drawdown": 20.8, "desc": "TSLA 20.8%回撤", "price": 386.68}, 
        {"drawdown": 37.8, "desc": "TSLA 37.8%回撤", "price": 303.72},
        {"drawdown": 44.5, "desc": "TSLA 44.5%回撤", "price": 270.93},
        {"drawdown": 48.3, "desc": "TSLA 48.3%最低点", "price": 252.54},
        {"drawdown": 65.0, "desc": "极端回撤场景", "price": 200.00}
    ]
    
    # 测试配置
    test_configs = [
        {"tier": 1, "multiplier": 1.0, "name": "免费版(3层)"},
        {"tier": 2, "multiplier": 1.0, "name": "付费版(5层)-标准"},
        {"tier": 2, "multiplier": 2.0, "name": "付费版(5层)-激进2.0x"},
        {"tier": 2, "multiplier": 2.5, "name": "付费版(5层)-激进2.5x"}
    ]
    
    results = {}
    
    for config in test_configs:
        print(f"\n📋 测试 {config['name']}")
        print("-" * 60)
        
        tester = TestV250DrawdownSystem(config['tier'], config['multiplier'])
        config_results = []
        
        print(f"配置: {len(tester.drawdown_layers)}层系统 {tester.drawdown_layers}")
        print(f"倍数: {tester.drawdown_multipliers}")
        
        for scenario in test_scenarios:
            drawdown = scenario['drawdown']
            desc = scenario['desc']
            
            print(f"\n🎯 {desc}:")
            
            qty, layer, threshold = tester.calculate_add_position_qty(drawdown)
            
            if qty > 0:
                print(f"   ✅ 触发第{layer}层 ({threshold}%) → {qty}股")
                investment = qty * scenario['price']
                print(f"   💰 投资金额: ${investment:,.2f}")
            else:
                print("   ⭕ 未触发加仓")
                investment = 0
            
            config_results.append({
                'scenario': desc,
                'drawdown': drawdown,
                'qty': qty,
                'layer': layer,
                'investment': investment
            })
        
        results[config['name']] = config_results
    
    # 生成对比分析
    print("\n" + "="*80)
    print("📊 五层系统优势分析")
    print("="*80)
    
    # 计算总投资对比
    for scenario_idx, scenario in enumerate(test_scenarios):
        print(f"\n📈 {scenario['desc']} - 投资对比:")
        
        free_investment = results["免费版(3层)"][scenario_idx]['investment']
        paid_std_investment = results["付费版(5层)-标准"][scenario_idx]['investment']
        paid_aggressive_investment = results["付费版(5层)-激进2.5x"][scenario_idx]['investment']
        
        if free_investment > 0:
            improvement_std = ((paid_std_investment - free_investment) / free_investment * 100) if free_investment > 0 else 0
            improvement_aggressive = ((paid_aggressive_investment - free_investment) / free_investment * 100) if free_investment > 0 else 0
            
            print(f"   免费版: ${free_investment:,.0f}")
            print(f"   付费版: ${paid_std_investment:,.0f} (+{improvement_std:.0f}%)")  
            print(f"   激进版: ${paid_aggressive_investment:,.0f} (+{improvement_aggressive:.0f}%)")
        else:
            print(f"   免费版: $0")
            print(f"   付费版: ${paid_std_investment:,.0f}")
            print(f"   激进版: ${paid_aggressive_investment:,.0f}")
    
    # 关键发现
    print(f"\n🔍 关键发现:")
    print(f"1. 37.8%回撤: 5层系统触发第4层，3层系统只能触发第3层")
    print(f"2. 48.3%极端回撤: 5层系统可达第4层最大加仓")
    print(f"3. 激进乘数2.5x在5层系统中效果显著，适合长期投资")
    print(f"4. 极端回撤警告系统有效引导用户升级VIP功能")

def test_extreme_drawdown_warning():
    """专门测试极端回撤警告功能"""
    
    print("\n" + "="*60)
    print("⚠️ 极端回撤警告系统测试")
    print("="*60)
    
    tester = TestV250DrawdownSystem(version_tier=2, aggressive_multiplier=2.0)
    
    extreme_scenarios = [55.0, 65.0, 75.0]
    
    for drawdown in extreme_scenarios:
        print(f"\n🔥 测试 {drawdown}% 极端回撤:")
        qty, layer, threshold = tester.calculate_add_position_qty(drawdown)
        print(f"   结果: 第{layer}层，{qty}股")

if __name__ == "__main__":
    try:
        test_5tier_comparison()
        test_extreme_drawdown_warning()
        print("\n✅ v2.5.0五层系统测试完成！")
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()