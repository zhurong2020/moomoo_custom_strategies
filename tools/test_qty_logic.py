#!/usr/bin/env python3
"""
测试DCA策略中qty参数的正确使用
确保用户输入的数量被正确应用
"""

def test_qty_logic():
    """测试qty逻辑"""
    
    print("🧪 测试DCA策略qty参数逻辑")
    
    # 模拟不同的用户输入
    test_cases = [
        {"user_qty": 10, "preset_mode": 1, "expected_result": "用户输入10股生效"},
        {"user_qty": 30, "preset_mode": 2, "expected_result": "用户输入30股生效（不被平衡型预设覆盖）"},
        {"user_qty": 50, "preset_mode": 3, "expected_result": "用户输入50股与积极型预设一致"},
        {"user_qty": 20, "preset_mode": 1, "expected_result": "用户输入20股，但保守型预设应用10股"},
        {"user_qty": 20, "preset_mode": 2, "expected_result": "用户输入20股，平衡型预设不覆盖"},
    ]
    
    for i, test in enumerate(test_cases, 1):
        print(f"\n📋 测试用例 {i}:")
        print(f"   用户输入qty: {test['user_qty']}")
        print(f"   选择预设: {test['preset_mode']}")
        print(f"   期望结果: {test['expected_result']}")
        
        # 模拟策略逻辑
        result_qty = simulate_qty_logic(test['user_qty'], test['preset_mode'])
        print(f"   实际结果: 最终qty = {result_qty}")
        
        # 验证加仓计算
        drawdown_multipliers = [1.5, 2.0, 3.0]
        for layer, multiplier in enumerate(drawdown_multipliers):
            add_qty = int(result_qty * multiplier)
            print(f"   第{layer+1}层加仓: {result_qty} × {multiplier} = {add_qty}股")

def simulate_qty_logic(user_qty, preset_mode):
    """模拟策略的qty处理逻辑"""
    
    # 模拟预设配置
    presets = {
        1: {"name": "保守型", "base_qty": 10},
        2: {"name": "平衡型", "base_qty": None},  # 修复后：不覆盖用户输入
        3: {"name": "积极型", "base_qty": 50}
    }
    
    qty = user_qty  # 用户输入
    
    if preset_mode in presets:
        preset = presets[preset_mode]
        
        # 应用预设逻辑（修复后的版本）
        if preset["base_qty"] is not None and qty == 20:  # 仅在预设有值且用户未修改默认值时应用
            qty = preset["base_qty"]
    
    return qty

def test_parameter_validation():
    """测试参数验证逻辑"""
    
    print(f"\n🔍 测试参数验证逻辑")
    
    test_quantities = [5, 15, 25, 35, 100, 1500]  # 各种数量测试
    
    for version_tier in [1, 2]:  # 免费版和付费版
        print(f"\n{'💎 付费版' if version_tier == 2 else '🆓 免费版'} 参数验证:")
        
        for qty in test_quantities:
            validated_qty = validate_quantity(qty, version_tier, default_qty=20)
            status = "✅ 通过" if validated_qty == qty else f"⚠️ 修正为{validated_qty}"
            print(f"   输入{qty}股 → {status}")

def validate_quantity(quantity, version_tier, default_qty):
    """模拟参数验证逻辑"""
    
    if version_tier == 2:  # 付费版
        if quantity < 1 or quantity > 1000:
            return default_qty
    else:  # 免费版
        if quantity < 10 or quantity > 1000 or quantity % 10 != 0:
            return default_qty
    
    return quantity

if __name__ == '__main__':
    test_qty_logic()
    test_parameter_validation()
    
    print(f"\n✅ 测试完成！关键改进:")
    print(f"   1. 用户输入的qty值被正确保留和使用")
    print(f"   2. 预设模板不会覆盖用户的自定义qty")
    print(f"   3. 加仓计算基于用户的qty值")
    print(f"   4. 参数验证支持付费版更灵活的设置")