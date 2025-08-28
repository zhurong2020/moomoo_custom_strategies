#!/usr/bin/env python3
"""
从订单历史CSV提取SPY价格数据
用于DCA策略本地测试
"""

import csv
import json
from datetime import datetime

def extract_spy_prices(csv_file):
    """从订单历史CSV提取SPY价格数据"""
    spy_data = []
    
    with open(csv_file, 'r', encoding='utf-8-sig') as file:
        # 跳过BOM标记
        content = file.read()
        if content.startswith('\ufeff'):
            content = content[1:]
        
        # 重新分析CSV
        lines = content.strip().split('\n')
        reader = csv.DictReader(lines)
        
        for row in reader:
            # 提取关键信息
            trade_date = row['成交时间'].split(' ')[0]  # 提取日期部分
            price = float(row['成交价格'])
            
            # 转换日期格式
            date_obj = datetime.strptime(trade_date, '%Y/%m/%d')
            formatted_date = date_obj.strftime('%Y-%m-%d')
            
            spy_data.append({
                'date': formatted_date,
                'price': price,
                'trade_time': row['成交时间'],
                'quantity': int(row['成交数量']),
                'amount': float(row['成交金额'])
            })
    
    return spy_data

def calculate_statistics(data):
    """计算价格统计信息"""
    prices = [d['price'] for d in data]
    
    return {
        'count': len(prices),
        'min_price': min(prices),
        'max_price': max(prices),
        'avg_price': sum(prices) / len(prices),
        'first_price': prices[0],
        'last_price': prices[-1],
        'total_return': (prices[-1] - prices[0]) / prices[0] * 100,
        'volatility': (max(prices) - min(prices)) / min(prices) * 100
    }

def save_test_data(data, stats):
    """保存测试数据文件"""
    import os
    
    # 创建data目录
    data_dir = '/home/wuxia/projects/moomoo_custom_strategies/data'
    os.makedirs(data_dir, exist_ok=True)
    
    # 保存详细价格数据 (JSON)
    with open(f'{data_dir}/spy_price_history.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    
    # 保存简化价格数据 (CSV)
    with open(f'{data_dir}/spy_price_history.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=['date', 'price'])
        writer.writeheader()
        for item in data:
            writer.writerow({'date': item['date'], 'price': item['price']})
    
    # 保存统计信息
    with open(f'{data_dir}/spy_statistics.json', 'w', encoding='utf-8') as f:
        json.dump(stats, f, indent=2, ensure_ascii=False)
    
    return data_dir

def main():
    csv_file = '/home/wuxia/projects/moomoo_custom_strategies/strategies/orders_his.csv'
    
    print("📊 提取SPY价格数据...")
    
    # 提取数据
    spy_data = extract_spy_prices(csv_file)
    
    if not spy_data:
        print("❌ 未能提取到数据")
        return
    
    # 计算统计
    stats = calculate_statistics(spy_data)
    
    # 输出统计信息
    print(f"✅ 成功提取 {stats['count']} 天的SPY价格数据")
    print(f"📅 时间跨度: {spy_data[0]['date']} 至 {spy_data[-1]['date']}")
    print(f"💰 价格区间: ${stats['min_price']:.2f} - ${stats['max_price']:.2f}")
    print(f"📈 平均价格: ${stats['avg_price']:.2f}")
    print(f"📊 总收益率: {stats['total_return']:.1f}%")
    print(f"📉 价格波动: {stats['volatility']:.1f}%")
    
    # 保存数据
    data_dir = save_test_data(spy_data, stats)
    print(f"\n💾 数据已保存至: {data_dir}/")
    print(f"   - spy_price_history.json (详细数据)")
    print(f"   - spy_price_history.csv (价格数据)")
    print(f"   - spy_statistics.json (统计信息)")
    
    # 显示关键价格点
    print(f"\n🎯 关键价格点:")
    print(f"   起始价格: ${spy_data[0]['price']:.2f} ({spy_data[0]['date']})")
    print(f"   最高价格: ${stats['max_price']:.2f}")
    print(f"   最低价格: ${stats['min_price']:.2f}")
    print(f"   最终价格: ${spy_data[-1]['price']:.2f} ({spy_data[-1]['date']})")
    
    # 计算回撤点位
    print(f"\n📉 重要回撤点位计算:")
    max_price = stats['max_price']
    for threshold in [5, 10, 15, 20]:
        target_price = max_price * (1 - threshold/100)
        print(f"   {threshold}%回撤点位: ${target_price:.2f}")

if __name__ == '__main__':
    main()