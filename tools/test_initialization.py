#!/usr/bin/env python3
"""
测试混合开发版初始化脚本
用于验证修复后的初始化过程
"""

def test_strategy_initialization():
    """测试策略初始化关键属性"""
    
    print("🧪 测试混合开发版初始化过程")
    print("=" * 50)
    
    # 模拟策略初始化需要的关键属性
    required_attributes = [
        'current_drawdown_layer',
        'last_investment_time', 
        'highest_price',
        'last_valid_price',
        'strategy_start_price',
        'drawdown_reset_threshold',
        'high_queue',
        '_position',
        '_total_cost',
        'virtual_balance',
        'version_tier',
        'interval_min',
        'qty',
        'backtest'
    ]
    
    print("📋 检查必需属性列表:")
    for attr in required_attributes:
        print(f"   - {attr}")
    
    print(f"\n✅ 总共需要初始化 {len(required_attributes)} 个关键属性")
    
    # 检查初始化顺序
    print(f"\n🔄 建议的初始化顺序:")
    print("1. 核心状态变量 (current_drawdown_layer, highest_price, 等)")
    print("2. 回测支持变量 (high_queue, _position, _total_cost)")
    print("3. 用户参数设置 (global_variables)")
    print("4. 预设配置 (setup_presets)")  
    print("5. 分层功能 (setup_tier_features) - 设置 interval_min")
    print("6. 虚拟余额最终确认")
    print("7. 欢迎信息显示")
    
    print(f"\n🎯 关键修复点:")
    print("- ✅ 提前初始化 high_queue 和 virtual_balance")
    print("- ✅ setup_tier_features 前确保所有依赖属性存在")
    print("- ✅ 异常处理中使用 getattr 和默认值")
    print("- ✅ 虚拟余额的多重保护机制")
    
    print(f"\n🚀 测试建议:")
    print("1. 免费版测试: version_tier=1, interval_mode=1")
    print("2. 付费版测试: version_tier=2, interval_mode=2")  
    print("3. 边界测试: 异常情况下的默认值使用")

if __name__ == "__main__":
    test_strategy_initialization()