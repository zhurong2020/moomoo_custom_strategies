#!/usr/bin/env python3
"""
DCA策略逻辑完整验证工具
使用真实SPY数据验证免费版和付费版的定投逻辑
"""

import json
import csv
from datetime import datetime, timedelta
from collections import deque

class DCAStrategyValidator:
    """DCA策略验证器"""
    
    def __init__(self, spy_data_file, initial_balance=10000):
        self.spy_data = self.load_spy_data(spy_data_file)
        self.initial_balance = initial_balance
        
        # 策略参数
        self.drawdown_layers = [5.0, 10.0, 20.0]
        self.drawdown_multipliers = [1.5, 2.0, 3.0]
        self.extreme_drawdown_pct = 50.0
        
    def load_spy_data(self, file_path):
        """加载SPY价格数据"""
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        print(f"📊 加载了 {len(data)} 天的SPY数据")
        return data
    
    def reset_strategy_state(self, version_tier, qty, interval_days=1):
        """重置策略状态"""
        self.version_tier = version_tier
        self.qty = qty
        self.interval_days = interval_days
        
        # 策略状态
        self.current_drawdown_layer = -1
        self.highest_price = None
        self.strategy_start_price = None
        self.virtual_balance = self.initial_balance
        self.position = 0
        self.total_cost = 0.0
        self.last_investment_date = None
        
        # 交易记录
        self.trade_history = []
        self.daily_stats = []
    
    def calculate_drawdown(self, latest_price):
        """计算回撤幅度"""
        if self.strategy_start_price is None:
            self.strategy_start_price = latest_price
            self.highest_price = latest_price
            return 0.0
            
        # 更新最高价
        if latest_price > self.highest_price:
            old_highest = self.highest_price
            self.highest_price = latest_price
            # 价格创新高时，重置回撤层级
            if (latest_price - old_highest) / old_highest > 0.05:  # 上涨5%
                self.current_drawdown_layer = -1
        
        # 计算当前回撤
        if self.highest_price > 0:
            drawdown = (self.highest_price - latest_price) / self.highest_price * 100
        else:
            drawdown = 0.0
            
        return drawdown
    
    def calculate_add_position_qty(self, drawdown):
        """计算加仓数量"""
        for i, threshold in enumerate(self.drawdown_layers):
            if drawdown >= threshold:
                # 检查是否已经在这个层级或更高层级加过仓
                if i <= self.current_drawdown_layer:
                    continue
                    
                # 触发新的加仓层级
                self.current_drawdown_layer = i
                add_qty = int(self.qty * self.drawdown_multipliers[i])
                return add_qty, i + 1  # 返回数量和层级
        
        return 0, 0
    
    def should_invest(self, current_date):
        """判断是否应该定投"""
        if self.last_investment_date is None:
            return True
        
        current_dt = datetime.strptime(current_date, '%Y-%m-%d')
        last_dt = datetime.strptime(self.last_investment_date, '%Y-%m-%d')
        
        return (current_dt - last_dt).days >= self.interval_days
    
    def execute_investment(self, date, price, quantity, trade_type):
        """执行投资"""
        required_cash = quantity * price
        
        # 资金不足检查
        if required_cash > self.virtual_balance:
            max_qty = int(self.virtual_balance // price)
            if max_qty < 1:
                return None  # 无法投资
            
            original_qty = quantity
            quantity = max_qty
            required_cash = quantity * price
            trade_type += f" (资金调整: {original_qty}→{quantity}股)"
        
        # 执行交易
        self.virtual_balance -= required_cash
        self.total_cost += required_cash
        self.position += quantity
        self.last_investment_date = date
        
        # 记录交易
        trade_record = {
            'date': date,
            'price': price,
            'quantity': quantity,
            'amount': required_cash,
            'type': trade_type,
            'balance': self.virtual_balance,
            'position': self.position,
            'total_cost': self.total_cost
        }
        
        self.trade_history.append(trade_record)
        return trade_record
    
    def free_version_logic(self, date, price, drawdown):
        """免费版策略逻辑"""
        result = {
            'action': 'none',
            'reason': '',
            'risk_alert': ''
        }
        
        # 风险提醒
        if drawdown >= 20.0:
            result['risk_alert'] = f"免费版风险提醒: 回撤{drawdown:.1f}%，建议关注市场变化"
        elif drawdown >= 10.0:
            result['risk_alert'] = f"回撤监控: 当前回撤{drawdown:.1f}%"
        
        # 仅定期定投
        if self.should_invest(date):
            trade = self.execute_investment(date, price, self.qty, "免费版定投")
            if trade:
                result['action'] = 'invest'
                result['reason'] = f"定期定投 {self.qty}股"
                return result, trade
        
        result['reason'] = "等待下次定投时机"
        return result, None
    
    def advanced_version_logic(self, date, price, drawdown):
        """付费版策略逻辑"""
        result = {
            'action': 'none',
            'reason': '',
            'risk_alert': ''
        }
        
        # 极端回撤保护
        if drawdown >= self.extreme_drawdown_pct:
            result['risk_alert'] = f"极端回撤保护: {drawdown:.1f}%，仅定投模式"
            if self.should_invest(date):
                trade = self.execute_investment(date, price, self.qty, "极端回撤保护")
                if trade:
                    result['action'] = 'invest'
                    result['reason'] = f"极端回撤保护定投 {self.qty}股"
                    return result, trade
        
        # 智能加仓系统
        add_qty, layer = self.calculate_add_position_qty(drawdown)
        if add_qty > 0:
            trade = self.execute_investment(date, price, add_qty, f"付费版第{layer}层加仓")
            if trade:
                result['action'] = 'add_position'
                result['reason'] = f"第{layer}层加仓 {add_qty}股 (回撤{drawdown:.1f}%)"
                result['risk_alert'] = f"触发第{layer}层加仓保护"
                return result, trade
        
        # 常规定投
        if self.should_invest(date):
            trade = self.execute_investment(date, price, self.qty, "付费版定投")
            if trade:
                result['action'] = 'invest'
                result['reason'] = f"定期定投 {self.qty}股"
                return result, trade
        
        result['reason'] = "等待下次投资时机"
        return result, None
    
    def run_backtest(self, version_tier, qty, show_details=False):
        """运行回测"""
        self.reset_strategy_state(version_tier, qty)
        
        version_name = "免费版" if version_tier == 1 else "付费版"
        print(f"\n🚀 开始{version_name}回测 (qty={qty}股)")
        print("="*60)
        
        significant_events = []  # 记录重要事件
        
        for i, day_data in enumerate(self.spy_data):
            date = day_data['date']
            price = day_data['price']
            
            # 计算回撤
            drawdown = self.calculate_drawdown(price)
            
            # 执行策略逻辑
            if version_tier == 1:
                logic_result, trade = self.free_version_logic(date, price, drawdown)
            else:
                logic_result, trade = self.advanced_version_logic(date, price, drawdown)
            
            # 记录每日统计
            market_value = self.position * price
            total_value = self.virtual_balance + market_value
            profit = market_value - self.total_cost
            profit_pct = (profit / self.total_cost * 100) if self.total_cost > 0 else 0
            
            daily_stat = {
                'date': date,
                'price': price,
                'drawdown': drawdown,
                'position': self.position,
                'balance': self.virtual_balance,
                'market_value': market_value,
                'total_value': total_value,
                'profit': profit,
                'profit_pct': profit_pct,
                'highest_price': self.highest_price,
                'action': logic_result['action'],
                'reason': logic_result['reason']
            }
            
            self.daily_stats.append(daily_stat)
            
            # 记录重要事件
            if trade or logic_result['risk_alert'] or drawdown >= 5:
                event = {
                    'date': date,
                    'price': price,
                    'drawdown': drawdown,
                    'action': logic_result['action'],
                    'reason': logic_result['reason'],
                    'alert': logic_result['risk_alert'],
                    'trade': trade
                }
                significant_events.append(event)
            
            # 显示重要事件
            if show_details and (trade or drawdown >= 10):
                print(f"{date}: ${price:.2f} | 回撤{drawdown:.1f}% | {logic_result['reason']}")
                if logic_result['risk_alert']:
                    print(f"         ⚠️ {logic_result['risk_alert']}")
                if trade:
                    print(f"         💰 余额${self.virtual_balance:.0f} | 持仓{self.position}股")
        
        return self.generate_backtest_report(version_name, significant_events)
    
    def generate_backtest_report(self, version_name, significant_events):
        """生成回测报告"""
        final_stats = self.daily_stats[-1]
        
        # 计算关键指标
        total_trades = len(self.trade_history)
        total_invested = self.total_cost
        final_value = final_stats['total_value']
        total_return = ((final_value - self.initial_balance) / self.initial_balance) * 100
        
        # 统计不同交易类型
        trade_types = {}
        for trade in self.trade_history:
            trade_type = trade['type'].split('(')[0].strip()  # 去除调整说明
            trade_types[trade_type] = trade_types.get(trade_type, 0) + 1
        
        # 最大回撤统计
        max_drawdown_day = max(self.daily_stats, key=lambda x: x['drawdown'])
        
        report = {
            'version': version_name,
            'qty': self.qty,
            'summary': {
                'total_days': len(self.daily_stats),
                'total_trades': total_trades,
                'total_invested': total_invested,
                'final_balance': final_stats['balance'],
                'final_position': final_stats['position'],
                'final_market_value': final_stats['market_value'],
                'final_total_value': final_value,
                'total_return': total_return,
                'max_drawdown': max_drawdown_day['drawdown'],
                'max_drawdown_date': max_drawdown_day['date']
            },
            'trade_breakdown': trade_types,
            'significant_events': significant_events,
            'daily_stats': self.daily_stats,
            'trade_history': self.trade_history
        }
        
        return report

def compare_versions():
    """对比不同版本的表现"""
    spy_file = '/home/wuxia/projects/moomoo_custom_strategies/data/spy_price_history.json'
    validator = DCAStrategyValidator(spy_file, initial_balance=50000)  # 使用5万本金测试
    
    # 测试配置
    test_configs = [
        {'version_tier': 1, 'qty': 20, 'name': '免费版-20股'},
        {'version_tier': 2, 'qty': 20, 'name': '付费版-20股'},
        {'version_tier': 1, 'qty': 30, 'name': '免费版-30股'},
        {'version_tier': 2, 'qty': 30, 'name': '付费版-30股'}
    ]
    
    reports = []
    
    for config in test_configs:
        print(f"\n{'='*20} {config['name']} {'='*20}")
        report = validator.run_backtest(
            config['version_tier'], 
            config['qty'], 
            show_details=True
        )
        reports.append(report)
        
        # 显示摘要
        s = report['summary']
        print(f"\n📊 {config['name']} 回测结果:")
        print(f"   总交易次数: {s['total_trades']}")
        print(f"   总投资金额: ${s['total_invested']:.0f}")
        print(f"   最终总价值: ${s['final_total_value']:.0f}")
        print(f"   总收益率: {s['total_return']:.1f}%")
        print(f"   最大回撤: {s['max_drawdown']:.1f}% ({s['max_drawdown_date']})")
        print(f"   交易类型分布: {report['trade_breakdown']}")
    
    # 生成对比报告
    generate_comparison_report(reports)
    
    return reports

def generate_comparison_report(reports):
    """生成版本对比报告"""
    print(f"\n🏆 版本对比总结")
    print("="*80)
    
    # 对比表格
    print(f"{'版本':<15} {'总收益率':<10} {'交易次数':<8} {'最大回撤':<10} {'加仓次数':<8}")
    print("-"*60)
    
    for report in reports:
        s = report['summary']
        add_position_count = report['trade_breakdown'].get('付费版第1层加仓', 0) + \
                           report['trade_breakdown'].get('付费版第2层加仓', 0) + \
                           report['trade_breakdown'].get('付费版第3层加仓', 0)
        
        print(f"{report['version']:<15} {s['total_return']:<9.1f}% {s['total_trades']:<8} "
              f"{s['max_drawdown']:<9.1f}% {add_position_count:<8}")
    
    # 关键发现
    paid_20 = next(r for r in reports if r['version'] == '付费版' and r['qty'] == 20)
    free_20 = next(r for r in reports if r['version'] == '免费版' and r['qty'] == 20)
    
    performance_diff = paid_20['summary']['total_return'] - free_20['summary']['total_return']
    
    print(f"\n🎯 关键发现:")
    print(f"   付费版相比免费版额外收益: {performance_diff:.1f}%")
    print(f"   付费版智能加仓触发次数: {sum(paid_20['trade_breakdown'].get(k, 0) for k in paid_20['trade_breakdown'] if '加仓' in k)}")
    print(f"   免费版仅风险提醒，无智能加仓")

def main():
    """主函数"""
    print("🧪 DCA策略完整逻辑验证")
    print("使用真实SPY数据验证免费版和付费版差异")
    print("="*60)
    
    reports = compare_versions()
    
    # 保存详细报告
    output_file = '/home/wuxia/projects/moomoo_custom_strategies/data/dca_validation_report.json'
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(reports, f, indent=2, ensure_ascii=False)
    
    print(f"\n💾 详细报告已保存: {output_file}")
    print("✅ DCA策略逻辑验证完成！")

if __name__ == '__main__':
    main()