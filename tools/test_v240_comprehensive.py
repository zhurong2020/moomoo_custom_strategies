#!/usr/bin/env python3
"""
v2.4.0 综合测试脚本
测试重点：
1. bar_custom API历史最高价初始化功能
2. 激进乘数系统 (1.0x vs 2.0x vs 2.5x对比)
3. 修复后的回撤计算准确性
4. 长期回撤场景下的激进抄底效果

Created: 2025-08-29
Version: 1.0
"""

import os
import sys
import csv
import json
from datetime import datetime, timedelta
from collections import defaultdict
import math

# 添加策略目录到Python路径
sys.path.append('/home/wuxia/projects/moomoo_custom_strategies/strategies')

class MockMoomooAPI:
    """模拟Moomoo API for v2.4.0测试"""
    
    def __init__(self, spy_data_file):
        self.spy_data = []
        self.current_index = 0
        self.load_spy_data(spy_data_file)
        
    def load_spy_data(self, file_path):
        """加载SPY历史数据"""
        with open(file_path, 'r') as f:
            reader = csv.DictReader(f)
            for row in reader:
                self.spy_data.append({
                    'date': row['date'], 
                    'price': float(row['price'])
                })
        print(f"📊 加载SPY数据: {len(self.spy_data)}天")
    
    def bar_custom(self, symbol, data_type, custom_num, custom_type, select):
        """模拟bar_custom API - 关键测试函数"""
        print(f"🔍 bar_custom调用: {symbol}, 数据类型: {data_type}, 周期: {custom_num}")
        
        if self.current_index < custom_num:
            # 数据不够200天，使用现有数据的最大值
            available_data = self.spy_data[:self.current_index + 1]
            max_price = max(item['price'] for item in available_data)
            print(f"   📈 数据不足{custom_num}天，使用{len(available_data)}天最高价: ${max_price:.2f}")
            return max_price
        else:
            # 获取过去custom_num天的最高价
            start_idx = max(0, self.current_index - custom_num + 1)
            end_idx = self.current_index + 1
            period_data = self.spy_data[start_idx:end_idx]
            max_price = max(item['price'] for item in period_data)
            print(f"   📈 获取{custom_num}天历史最高价: ${max_price:.2f} (索引{start_idx}-{end_idx})")
            return max_price
    
    def bar_close(self, symbol, bar_type, select):
        """模拟获取收盘价"""
        if self.current_index < len(self.spy_data):
            price = self.spy_data[self.current_index]['price']
            return price
        return None
    
    def current_price(self, symbol, price_type):
        """模拟获取当前价格"""
        return self.bar_close(symbol, None, 1)
    
    def total_cash(self, currency):
        """模拟获取账户余额"""
        return 100000.0  # 10万美元
    
    def device_time(self, timezone):
        """模拟获取当前时间"""
        if self.current_index < len(self.spy_data):
            date_str = self.spy_data[self.current_index]['date']
            return datetime.strptime(date_str, '%Y-%m-%d')
        return datetime.now()
    
    def advance_day(self):
        """前进一天"""
        self.current_index += 1
        return self.current_index < len(self.spy_data)

class V240TestStrategy:
    """v2.4.0策略测试类"""
    
    def __init__(self, api, aggressive_multiplier=1.0):
        self.api = api
        self.aggressive_multiplier = aggressive_multiplier
        self.version_tier = 2 if aggressive_multiplier > 1.0 else 1
        self.reset()
    
    def reset(self):
        """重置策略状态"""
        self.run_highest_price = None
        self.current_drawdown_layer = -1
        self.position = 0
        self.total_cost = 0.0
        self.virtual_balance = 100000.0
        self.qty = 20
        self.effective_qty = 20
        
        # v2.4.0关键参数
        self.drawdown_layers = [5.0, 10.0, 20.0]
        self.base_multipliers = [1.5, 2.0, 3.0]
        self.drawdown_multipliers = [m * self.aggressive_multiplier for m in self.base_multipliers]
        
        # 统计数据
        self.trades = []
        self.investment_count = 0
        self.add_position_count = 0
        self.max_drawdown_experienced = 0.0
        
        print(f"🎯 策略配置: 激进乘数={self.aggressive_multiplier}x, 最终倍数={self.drawdown_multipliers}")
    
    def initialize_highest_price_baseline(self):
        """测试历史最高价初始化"""
        try:
            print("📈 测试bar_custom历史最高价初始化...")
            historical_high = self.api.bar_custom(
                symbol='SPY',
                data_type='HIGH', 
                custom_num=200,
                custom_type='D1',
                select=1
            )
            
            if historical_high and historical_high > 0:
                self.run_highest_price = historical_high
                print(f"✅ 历史最高价基准: ${historical_high:.2f}")
                return True
            else:
                # 回退机制测试
                current_val = self.api.current_price('SPY', 'FTH')
                self.run_highest_price = current_val or 500.0
                print(f"⚠️ 回退到当前价格: ${self.run_highest_price:.2f}")
                return False
        except Exception as e:
            print(f"❌ 历史最高价初始化失败: {e}")
            self.run_highest_price = 500.0
            return False
    
    def calculate_drawdown(self, latest_price):
        """测试修复后的回撤计算"""
        if self.run_highest_price is None:
            self.run_highest_price = latest_price
            print(f"⚠️ 运行时初始化最高价: ${latest_price:.2f}")
            
        # 实时更新运行时最高价
        if latest_price > self.run_highest_price:
            old_high = self.run_highest_price
            self.run_highest_price = latest_price
            print(f"📈 创新高: ${old_high:.2f} → ${latest_price:.2f}")
            self.current_drawdown_layer = -1  # 重置回撤层级
        
        # 计算准确回撤
        if self.run_highest_price > 0:
            drawdown = (self.run_highest_price - latest_price) / self.run_highest_price * 100
            self.max_drawdown_experienced = max(self.max_drawdown_experienced, drawdown)
            return drawdown
        return 0.0
    
    def calculate_add_position_qty(self, drawdown):
        """测试激进乘数系统"""
        for i, threshold in enumerate(self.drawdown_layers):
            if drawdown >= threshold:
                # v2.4.0激进抄底：每次达到阈值都加仓
                if i > self.current_drawdown_layer:  # 新层级
                    self.current_drawdown_layer = i
                    add_qty = int(self.effective_qty * self.drawdown_multipliers[i])
                    print(f"🎯 激进加仓触发: 第{i+1}层 ({threshold}%), {self.drawdown_multipliers[i]:.1f}x倍数, {add_qty}股")
                    return add_qty
        return 0
    
    def execute_trade(self, qty, price, trade_type):
        """执行交易"""
        cost = qty * price
        if cost <= self.virtual_balance:
            self.position += qty
            self.total_cost += cost
            self.virtual_balance -= cost
            
            self.trades.append({
                'date': self.api.spy_data[self.api.current_index]['date'],
                'price': price,
                'qty': qty,
                'type': trade_type,
                'total_position': self.position,
                'avg_cost': self.total_cost / self.position if self.position > 0 else 0
            })
            
            if trade_type == 'regular':
                self.investment_count += 1
            else:
                self.add_position_count += 1
                
            return True
        else:
            print(f"⚠️ 资金不足: 需要${cost:.2f}, 可用${self.virtual_balance:.2f}")
            return False
    
    def run_backtest(self, days_to_test=None):
        """运行回测"""
        print(f"\n🚀 开始v2.4.0回测 - 激进乘数: {self.aggressive_multiplier}x")
        
        # 初始化历史最高价基准
        baseline_success = self.initialize_highest_price_baseline()
        
        days_tested = 0
        max_days = days_to_test or len(self.api.spy_data)
        
        # 模拟每7天定投一次
        investment_interval = 7
        days_since_last_investment = 0
        
        while self.api.advance_day() and days_tested < max_days:
            days_tested += 1
            current_price = self.api.bar_close('SPY', None, 1)
            
            if current_price is None:
                continue
                
            # 计算回撤
            drawdown = self.calculate_drawdown(current_price)
            
            # 定期定投
            days_since_last_investment += 1
            if days_since_last_investment >= investment_interval:
                self.execute_trade(self.qty, current_price, 'regular')
                days_since_last_investment = 0
            
            # 回撤加仓
            add_qty = self.calculate_add_position_qty(drawdown)
            if add_qty > 0:
                self.execute_trade(add_qty, current_price, 'add_position')
            
            # 每30天打印一次状态
            if days_tested % 30 == 0:
                avg_cost = self.total_cost / self.position if self.position > 0 else 0
                profit_pct = (current_price - avg_cost) / avg_cost * 100 if avg_cost > 0 else 0
                print(f"📊 第{days_tested}天: 价格=${current_price:.2f}, 回撤={drawdown:.1f}%, "
                      f"持仓={self.position}股, 成本=${avg_cost:.2f}, 盈亏={profit_pct:.1f}%")
        
        return self.generate_report(current_price)
    
    def generate_report(self, final_price):
        """生成测试报告"""
        if self.position == 0:
            return None
            
        avg_cost = self.total_cost / self.position
        total_value = self.position * final_price
        profit_loss = total_value - self.total_cost
        profit_pct = profit_loss / self.total_cost * 100
        
        report = {
            'aggressive_multiplier': self.aggressive_multiplier,
            'version_tier': self.version_tier,
            'final_stats': {
                'total_investment': round(self.total_cost, 2),
                'total_position': self.position,
                'average_cost': round(avg_cost, 2),
                'final_price': round(final_price, 2),
                'total_value': round(total_value, 2),
                'profit_loss': round(profit_loss, 2),
                'profit_percentage': round(profit_pct, 2),
                'max_drawdown': round(self.max_drawdown_experienced, 2)
            },
            'trading_stats': {
                'regular_investments': self.investment_count,
                'add_position_trades': self.add_position_count,
                'total_trades': len(self.trades),
                'avg_trade_size': round(sum(t['qty'] for t in self.trades) / len(self.trades), 1) if self.trades else 0
            },
            'system_performance': {
                'baseline_initialization_success': hasattr(self, 'run_highest_price') and self.run_highest_price is not None,
                'historical_high_price': round(self.run_highest_price, 2) if self.run_highest_price else 0,
                'drawdown_layers': self.drawdown_layers,
                'final_multipliers': [round(m, 1) for m in self.drawdown_multipliers]
            }
        }
        
        return report

def run_comprehensive_test():
    """运行综合对比测试"""
    
    print("="*80)
    print("🧪 v2.4.0 综合测试开始")
    print("="*80)
    
    spy_data_file = '/home/wuxia/projects/moomoo_custom_strategies/data/spy_price_history.csv'
    
    # 测试不同激进乘数的效果
    test_cases = [
        {'multiplier': 1.0, 'name': '标准版 (免费版)'},
        {'multiplier': 1.5, 'name': '适度激进'},  
        {'multiplier': 2.0, 'name': '激进版'},
        {'multiplier': 2.5, 'name': '超激进版 (付费版上限)'}
    ]
    
    results = []
    
    for case in test_cases:
        print(f"\n📋 测试 {case['name']} - 乘数: {case['multiplier']}x")
        print("-" * 60)
        
        # 创建新的API实例和策略
        api = MockMoomooAPI(spy_data_file)
        strategy = V240TestStrategy(api, case['multiplier'])
        
        # 运行回测
        result = strategy.run_backtest(days_to_test=200)  # 测试200天
        
        if result:
            result['test_name'] = case['name']
            results.append(result)
            
            # 打印关键指标
            stats = result['final_stats']
            print(f"\n📊 {case['name']} 测试结果:")
            print(f"   总投资: ${stats['total_investment']:,.2f}")
            print(f"   持仓数量: {stats['total_position']}股")
            print(f"   平均成本: ${stats['average_cost']:.2f}")
            print(f"   最终价格: ${stats['final_price']:.2f}") 
            print(f"   盈亏金额: ${stats['profit_loss']:,.2f}")
            print(f"   盈亏比例: {stats['profit_percentage']:.2f}%")
            print(f"   最大回撤: {stats['max_drawdown']:.2f}%")
            print(f"   加仓次数: {result['trading_stats']['add_position_trades']}次")
    
    # 生成对比报告
    generate_comparison_report(results)
    
    return results

def generate_comparison_report(results):
    """生成对比分析报告"""
    if not results:
        return
        
    print("\n" + "="*80)
    print("📊 v2.4.0 激进乘数系统对比分析")
    print("="*80)
    
    # 按盈亏排序
    sorted_results = sorted(results, key=lambda x: x['final_stats']['profit_percentage'], reverse=True)
    
    print(f"{'排名':<4} {'策略':<15} {'乘数':<6} {'盈亏%':<8} {'加仓次数':<8} {'最大回撤%':<10}")
    print("-" * 60)
    
    for i, result in enumerate(sorted_results):
        print(f"{i+1:<4} {result['test_name']:<15} {result['aggressive_multiplier']}x{'':<3} "
              f"{result['final_stats']['profit_percentage']:.2f}%{'':<3} "
              f"{result['trading_stats']['add_position_trades']:<8} "
              f"{result['final_stats']['max_drawdown']:.2f}%")
    
    # 分析结论
    best_result = sorted_results[0]
    print(f"\n🏆 最佳表现: {best_result['test_name']}")
    print(f"   激进乘数: {best_result['aggressive_multiplier']}x")
    print(f"   收益优势: {best_result['final_stats']['profit_percentage']:.2f}%")
    
    # 保存结果到文件
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = f"/home/wuxia/projects/moomoo_custom_strategies/data/v240_test_report_{timestamp}.json"
    
    with open(report_file, 'w', encoding='utf-8') as f:
        json.dump({
            'test_timestamp': timestamp,
            'test_version': 'v2.4.0',
            'test_description': '激进乘数系统综合测试',
            'results': results
        }, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 详细报告已保存: {report_file}")

if __name__ == "__main__":
    try:
        results = run_comprehensive_test()
        print("\n✅ v2.4.0测试完成！")
    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback
        traceback.print_exc()