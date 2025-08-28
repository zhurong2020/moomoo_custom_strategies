#!/usr/bin/env python3
"""
SPY价格数据获取工具
用于DCA策略回测的历史数据准备
"""

import json
import urllib.request
from datetime import datetime, timedelta
import csv

def get_spy_data(days=365):
    """获取SPY近一年价格数据"""
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days)
    
    print(f'📊 获取SPY价格数据: {start_date.strftime("%Y-%m-%d")} 到 {end_date.strftime("%Y-%m-%d")}')
    
    # 转换为时间戳
    start_ts = int(start_date.timestamp())
    end_ts = int(end_date.timestamp())
    
    url = f'https://query1.finance.yahoo.com/v8/finance/chart/SPY?period1={start_ts}&period2={end_ts}&interval=1d'
    
    try:
        with urllib.request.urlopen(url) as response:
            data = json.loads(response.read().decode())
        
        result = data['chart']['result'][0]
        timestamps = result['timestamp']
        quotes = result['indicators']['quote'][0]
        
        spy_data = []
        for i, ts in enumerate(timestamps):
            date_str = datetime.fromtimestamp(ts).strftime('%Y-%m-%d')
            close_price = quotes['close'][i]
            high_price = quotes['high'][i] 
            low_price = quotes['low'][i]
            open_price = quotes['open'][i]
            volume = quotes['volume'][i]
            
            if close_price is not None:  # 过滤无效数据
                spy_data.append({
                    'date': date_str,
                    'open': round(open_price, 2) if open_price else close_price,
                    'high': round(high_price, 2) if high_price else close_price, 
                    'low': round(low_price, 2) if low_price else close_price,
                    'close': round(close_price, 2),
                    'volume': volume if volume else 0
                })
        
        return spy_data
        
    except Exception as e:
        print(f'❌ 获取数据失败: {e}')
        return None

def save_to_csv(data, filename):
    """保存数据到CSV文件"""
    with open(filename, 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['date', 'open', 'high', 'low', 'close', 'volume']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for row in data:
            writer.writerow(row)

def save_to_json(data, filename):
    """保存数据到JSON文件"""
    with open(filename, 'w', encoding='utf-8') as jsonfile:
        json.dump(data, jsonfile, indent=2, ensure_ascii=False)

def main():
    # 获取数据
    spy_data = get_spy_data(365)
    
    if not spy_data:
        print('❌ 未能获取数据')
        return
    
    print(f'✅ 成功获取 {len(spy_data)} 天的SPY数据')
    print(f'📅 日期范围: {spy_data[0]["date"]} 到 {spy_data[-1]["date"]}')
    
    # 计算价格统计
    prices = [d["close"] for d in spy_data]
    min_price = min(prices)
    max_price = max(prices)
    avg_price = sum(prices) / len(prices)
    
    print(f'💰 价格统计:')
    print(f'   最低: ${min_price:.2f}')
    print(f'   最高: ${max_price:.2f}')
    print(f'   平均: ${avg_price:.2f}')
    print(f'   波动: {(max_price - min_price) / min_price * 100:.1f}%')
    
    # 保存文件
    base_path = '/home/wuxia/projects/moomoo_custom_strategies/data/'
    
    # 确保目录存在
    import os
    os.makedirs(base_path, exist_ok=True)
    
    csv_file = f'{base_path}spy_historical_data.csv'
    json_file = f'{base_path}spy_historical_data.json'
    
    save_to_csv(spy_data, csv_file)
    save_to_json(spy_data, json_file)
    
    print(f'💾 数据已保存:')
    print(f'   CSV: {csv_file}')
    print(f'   JSON: {json_file}')
    
    # 显示最近几天的数据示例
    print(f'\n📈 最近5天数据示例:')
    for i in range(-5, 0):
        d = spy_data[i]
        print(f'   {d["date"]}: ${d["close"]:.2f} (H:${d["high"]:.2f} L:${d["low"]:.2f})')

if __name__ == '__main__':
    main()