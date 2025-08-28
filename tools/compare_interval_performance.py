#!/usr/bin/env python3
"""
对比每日定投 vs 每周定投的性能差异
验证付费版周期优势的商业价值
"""

import json
import math
from datetime import datetime, timedelta

class IntervalComparisonTest:
    """投资周期对比测试"""
    
    def __init__(self, spy_data_file, initial_balance=50000):
        self.spy_data = self.load_spy_data(spy_data_file)
        self.initial_balance = initial_balance
        
    def load_spy_data(self, file_path):
        """加载SPY数据"""
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    
    def reset_state(self, interval_days, qty):
        """重置测试状态"""
        self.interval_days = interval_days
        self.qty = qty
        self.virtual_balance = self.initial_balance
        self.position = 0
        self.total_cost = 0.0
        self.last_investment_date = None
        self.trade_history = []
        
    def should_invest(self, current_date):
        """判断是否应该定投"""
        if self.last_investment_date is None:
            return True
        
        current_dt = datetime.strptime(current_date, '%Y-%m-%d')
        last_dt = datetime.strptime(self.last_investment_date, '%Y-%m-%d')
        
        return (current_dt - last_dt).days >= self.interval_days
    
    def execute_investment(self, date, price):
        """执行投资"""
        required_cash = self.qty * price
        
        # 资金不足检查
        if required_cash > self.virtual_balance:
            max_qty = int(self.virtual_balance // price)
            if max_qty < 1:
                return None
            
            actual_qty = max_qty
            required_cash = actual_qty * price
        else:
            actual_qty = self.qty
        
        # 执行交易
        self.virtual_balance -= required_cash
        self.total_cost += required_cash
        self.position += actual_qty
        self.last_investment_date = date
        
        trade_record = {
            'date': date,
            'price': price,
            'quantity': actual_qty,
            'amount': required_cash,
            'balance': self.virtual_balance,
            'position': self.position,
            'total_cost': self.total_cost
        }
        
        self.trade_history.append(trade_record)
        return trade_record
    
    def run_test(self, interval_days, qty):
        """运行单个测试"""
        self.reset_state(interval_days, qty)
        
        interval_name = f"每{interval_days}日" if interval_days > 1 else "每日"
        print(f"\n🧪 测试: {interval_name}定投 (每次{qty}股)")
        print("-" * 50)
        
        trade_count = 0
        for day_data in self.spy_data:
            date = day_data['date']
            price = day_data['price']
            
            if self.should_invest(date):
                trade = self.execute_investment(date, price)
                if trade:
                    trade_count += 1
                    if trade_count <= 5:  # 显示前5笔交易
                        print(f"   {date}: {trade['quantity']}股 @ ${price:.2f} = ${trade['amount']:.0f}")
        
        # 计算最终结果
        final_price = self.spy_data[-1]['price']
        market_value = self.position * final_price
        total_value = self.virtual_balance + market_value
        total_return = ((total_value - self.initial_balance) / self.initial_balance) * 100
        
        # 计算平均成本
        avg_cost = self.total_cost / self.position if self.position > 0 else 0
        cost_efficiency = ((final_price - avg_cost) / avg_cost * 100) if avg_cost > 0 else 0
        
        result = {
            'interval_days': interval_days,
            'interval_name': interval_name,
            'qty': qty,
            'trade_count': len(self.trade_history),
            'total_invested': self.total_cost,
            'final_position': self.position,
            'avg_cost': avg_cost,
            'final_price': final_price,
            'market_value': market_value,
            'total_value': total_value,
            'total_return': total_return,
            'cost_efficiency': cost_efficiency,
            'trade_history': self.trade_history
        }
        
        print(f"📊 结果:")
        print(f"   交易次数: {result['trade_count']}")
        print(f"   总投资: ${result['total_invested']:.0f}")
        print(f"   持仓数量: {result['final_position']}股")
        print(f"   平均成本: ${result['avg_cost']:.2f}")
        print(f"   最终价格: ${result['final_price']:.2f}")
        print(f"   总收益率: {result['total_return']:.1f}%")
        print(f"   成本效率: {result['cost_efficiency']:.1f}%")
        
        return result
    
    def compare_intervals(self):
        """对比不同投资周期"""
        print("🎯 每日定投 vs 每周定投性能对比测试")
        print("=" * 60)
        
        # 测试配置
        test_configs = [
            {'interval_days': 7, 'qty': 20, 'name': '免费版 (每周20股)'},
            {'interval_days': 1, 'qty': 20, 'name': '付费版 (每日20股)'},
            {'interval_days': 7, 'qty': 30, 'name': '免费版 (每周30股)'},
            {'interval_days': 1, 'qty': 30, 'name': '付费版 (每日30股)'},
        ]
        
        results = []
        for config in test_configs:
            print(f"\n{'='*20} {config['name']} {'='*20}")
            result = self.run_test(config['interval_days'], config['qty'])
            result['config_name'] = config['name']
            results.append(result)
        
        # 生成对比报告
        self.generate_comparison_report(results)
        return results
    
    def generate_comparison_report(self, results):
        """生成对比报告"""
        print(f"\n🏆 性能对比总结")
        print("=" * 80)
        
        # 对比表格
        print(f"{'策略配置':<20} {'收益率':<8} {'交易次数':<8} {'平均成本':<10} {'成本效率':<8}")
        print("-" * 70)
        
        for result in results:
            print(f"{result['config_name']:<20} {result['total_return']:<7.1f}% {result['trade_count']:<8} "
                  f"${result['avg_cost']:<9.2f} {result['cost_efficiency']:<7.1f}%")
        
        # 计算关键差异
        weekly_20 = next(r for r in results if r['interval_days'] == 7 and r['qty'] == 20)
        daily_20 = next(r for r in results if r['interval_days'] == 1 and r['qty'] == 20)
        
        return_diff = daily_20['total_return'] - weekly_20['total_return']
        cost_diff = weekly_20['avg_cost'] - daily_20['avg_cost']
        trade_diff = daily_20['trade_count'] - weekly_20['trade_count']
        
        print(f"\n🎯 关键发现:")
        print(f"   每日定投 vs 每周定投 (20股对比):")
        print(f"   - 收益率差异: {return_diff:+.1f}% (每日定投{'优势' if return_diff > 0 else '劣势'})")
        print(f"   - 平均成本差异: ${cost_diff:+.2f} (每日定投成本{'更低' if cost_diff > 0 else '更高'})")
        print(f"   - 交易次数差异: {trade_diff:+d}次 (每日定投交易更{'频繁' if trade_diff > 0 else '少'})")
        
        # 商业化价值评估
        self.evaluate_commercial_value(return_diff, cost_diff, results)
    
    def evaluate_commercial_value(self, return_diff, cost_diff, results):
        """评估商业化价值"""
        print(f"\n💰 商业化价值评估:")
        
        if return_diff > 2:
            print(f"   ✅ 每日定投优势明显 (+{return_diff:.1f}%)，付费价值突出")
            print(f"   💡 建议营销话术: '每日定投比每周定投收益高{return_diff:.1f}%'")
        elif return_diff > 0:
            print(f"   ⚠️  每日定投小幅优势 (+{return_diff:.1f}%)，价值一般")
            print(f"   💡 建议结合其他功能强化付费价值")
        else:
            print(f"   ❌ 每日定投无明显优势 ({return_diff:.1f}%)，需要重新设计")
            print(f"   💡 建议调整策略或寻找其他差异化点")
        
        # 分析原因
        print(f"\n🔍 差异原因分析:")
        weekly_result = next(r for r in results if r['interval_days'] == 7)
        daily_result = next(r for r in results if r['interval_days'] == 1)
        
        print(f"   每周定投: {weekly_result['trade_count']}次交易，平均成本${weekly_result['avg_cost']:.2f}")
        print(f"   每日定投: {daily_result['trade_count']}次交易，平均成本${daily_result['avg_cost']:.2f}")
        
        if daily_result['trade_count'] > weekly_result['trade_count'] * 5:
            print(f"   💡 每日定投交易频率高，在波动市场中平滑成本效果更好")
        
        if abs(cost_diff) < 5:
            print(f"   ⚠️  平均成本差异不大，说明这段时间市场相对稳定")
    
    def analyze_market_conditions(self):
        """分析市场条件对结果的影响"""
        prices = [d['price'] for d in self.spy_data]
        
        # 计算市场统计
        start_price = prices[0]
        end_price = prices[-1]
        min_price = min(prices)
        max_price = max(prices)
        
        total_return = (end_price - start_price) / start_price * 100
        volatility_range = (max_price - min_price) / min_price * 100
        
        print(f"\n📈 市场条件分析:")
        print(f"   期间收益: {total_return:.1f}% (${start_price:.2f} → ${end_price:.2f})")
        print(f"   价格波动: {volatility_range:.1f}% (${min_price:.2f} - ${max_price:.2f})")
        
        if total_return > 10:
            print(f"   📊 上涨市场: 定投频率对收益影响相对较小")
        elif total_return < -10:
            print(f"   📊 下跌市场: 高频定投摊低成本优势明显")
        else:
            print(f"   📊 震荡市场: 定投策略差异主要体现在成本控制")

def main():
    """主函数"""
    spy_file = '/home/wuxia/projects/moomoo_custom_strategies/data/spy_price_history.json'
    tester = IntervalComparisonTest(spy_file, initial_balance=50000)
    
    # 分析市场条件
    tester.analyze_market_conditions()
    
    # 运行对比测试
    results = tester.compare_intervals()
    
    # 保存结果
    output_file = '/home/wuxia/projects/moomoo_custom_strategies/data/interval_comparison_report.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 详细报告已保存: {output_file}")
    print("✅ 投资周期对比测试完成！")

if __name__ == '__main__':
    main()