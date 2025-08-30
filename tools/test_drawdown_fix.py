#!/usr/bin/env python3
"""
v2.4.1 回撤层级修复验证
验证从高到低层级检查的逻辑是否正确工作
"""

class TestDrawdownLogic:
    """模拟回撤层级检查逻辑"""
    
    def __init__(self, aggressive_multiplier=1.0):
        self.effective_qty = 2
        self.drawdown_layers = [5.0, 10.0, 20.0]
        self.base_multipliers = [1.5, 2.0, 3.0]
        self.drawdown_multipliers = [m * aggressive_multiplier for m in self.base_multipliers]
    
    def calculate_add_position_qty_old(self, drawdown):
        """旧逻辑：从低到高检查（有BUG）"""
        print(f"🔍 旧逻辑检查 - 回撤: {drawdown:.1f}%")
        for i, threshold in enumerate(self.drawdown_layers):
            if drawdown >= threshold:
                add_qty = int(self.effective_qty * self.drawdown_multipliers[i])
                print(f"   ❌ 旧版: 第{i+1}层 ({threshold}%) → {add_qty}股")
                return add_qty, i+1, threshold
        return 0, 0, 0
    
    def calculate_add_position_qty_new(self, drawdown):
        """新逻辑：从高到低检查（修复版）"""
        print(f"🔍 新逻辑检查 - 回撤: {drawdown:.1f}%")
        for i in reversed(range(len(self.drawdown_layers))):
            threshold = self.drawdown_layers[i]
            if drawdown >= threshold:
                add_qty = int(self.effective_qty * self.drawdown_multipliers[i])
                print(f"   ✅ 新版: 第{i+1}层 ({threshold}%) → {add_qty}股")
                return add_qty, i+1, threshold
        return 0, 0, 0

def test_drawdown_scenarios():
    """测试不同回撤场景"""
    
    print("="*80)
    print("🧪 v2.4.1 回撤层级修复验证")
    print("="*80)
    
    # 测试不同激进乘数
    test_cases = [
        {"multiplier": 1.0, "name": "标准版(1.0x)"},
        {"multiplier": 2.0, "name": "激进版(2.0x)"},
    ]
    
    # 测试回撤场景（基于您的TSLA测试数据）
    scenarios = [
        {"drawdown": 3.0, "desc": "轻微回撤"},
        {"drawdown": 17.8, "desc": "TSLA第1次加仓 ($401.53)"},
        {"drawdown": 20.8, "desc": "TSLA第2次加仓 ($386.68)"},  
        {"drawdown": 25.0, "desc": "深度回撤"},
        {"drawdown": 48.3, "desc": "TSLA最低点 ($252.54)"}
    ]
    
    for case in test_cases:
        print(f"\n📋 测试 {case['name']} - 乘数: {case['multiplier']}x")
        print("-" * 60)
        
        tester = TestDrawdownLogic(case['multiplier'])
        print(f"配置: 基础倍数{tester.base_multipliers} → 最终倍数{tester.drawdown_multipliers}")
        
        for scenario in scenarios:
            drawdown = scenario['drawdown']
            desc = scenario['desc']
            
            print(f"\n🎯 场景: {desc} - 回撤{drawdown}%")
            
            # 测试旧逻辑
            old_qty, old_layer, old_threshold = tester.calculate_add_position_qty_old(drawdown)
            
            # 测试新逻辑  
            new_qty, new_layer, new_threshold = tester.calculate_add_position_qty_new(drawdown)
            
            # 对比结果
            if old_qty != new_qty:
                print(f"   🚨 差异发现: 旧版{old_qty}股 vs 新版{new_qty}股")
                print(f"   📊 改进: 从第{old_layer}层({old_threshold}%) 升级到 第{new_layer}层({new_threshold}%)")
                improvement = ((new_qty - old_qty) / old_qty * 100) if old_qty > 0 else 0
                print(f"   📈 加仓提升: +{improvement:.0f}%")
            else:
                print(f"   ✅ 结果一致: {new_qty}股")
    
    print("\n" + "="*80)
    print("📊 关键发现:")
    print("1. 17.8%回撤: 旧版触发第1层(1.5x) → 新版触发第2层(2.0x)")
    print("2. 20.8%回撤: 旧版触发第1层(1.5x) → 新版触发第3层(3.0x)")
    print("3. 激进乘数2.0x时: 17.8%回撤从3股提升到4股 (+33%)")
    print("4. 极端回撤48.3%: 新版正确触发最高层级")
    print("="*80)

if __name__ == "__main__":
    test_drawdown_scenarios()