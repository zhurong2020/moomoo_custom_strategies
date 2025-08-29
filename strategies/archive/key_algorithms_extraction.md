# 核心算法提取文档

## 文档目标
提取各策略中的核心算法实现，为独立Python应用迁移提供详细的代码参考。

## Strategy V1 - 核心算法提取

### 1. 分层加仓算法
```python
def calculate_investment_qty(self, base_qty, drawdown, volatility, latest_price, average_cost, return_max_layer=False):
    """
    分层加仓核心算法
    :param base_qty: 基础投资数量
    :param drawdown: 当前回撤百分比
    :param volatility: 市场波动率（暂未使用）
    :param latest_price: 最新价格
    :param average_cost: 平均成本
    :param return_max_layer: 是否返回最大层级信息
    """
    # 分层倍数表 - 每5%回撤对应一个倍数
    layers = [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5]
    
    # 计算当前回撤层级
    layer_index = int(drawdown // 5)  # 每5%一个层级
    
    # 防重复触发机制
    if layer_index <= self.current_drawdown_layer:
        if return_max_layer:
            return 0, layer_index
        return 0
    
    # 更新当前最高触发层级
    self.current_drawdown_layer = layer_index
    
    # 计算投资倍数
    if layer_index < len(layers):
        multiplier = layers[layer_index]
    else:
        multiplier = layers[-1]  # 超出范围使用最高倍数
    
    # 计算调整后的投资数量
    adjusted_qty = math.ceil(base_qty * multiplier)
    
    if return_max_layer:
        return adjusted_qty, layer_index
    return adjusted_qty
```

### 2. 历史高点追踪算法
```python
def update_high_tracking(self, current_price):
    """
    更新历史高点追踪
    使用滑动窗口优化性能
    """
    current_time = time.time()
    
    # 使用deque实现滑动窗口 (最多保留20个高点)
    if not hasattr(self, 'high_queue'):
        self.high_queue = collections.deque(maxlen=20)
    
    # 添加当前价格点
    self.high_queue.append({
        'price': current_price,
        'time': current_time
    })
    
    # 计算历史最高价
    self.historical_high = max([point['price'] for point in self.high_queue])
    
    return self.historical_high

def calculate_current_drawdown(self, current_price):
    """计算当前回撤百分比"""
    if not hasattr(self, 'historical_high') or self.historical_high == 0:
        return 0.0
    
    drawdown = (self.historical_high - current_price) / self.historical_high * 100
    return max(0, drawdown)  # 确保非负
```

### 3. 定投时间控制算法
```python
def should_execute_dca(self, current_time):
    """
    判断是否应执行定投
    :param current_time: 当前时间 (datetime对象)
    :return: bool
    """
    # 首次投资
    if self.last_investment_time is None:
        return True
    
    # 计算时间间隔
    elapsed_minutes = (current_time - self.last_investment_time).total_seconds() / 60
    
    # 检查是否到达投资间隔
    return elapsed_minutes >= self.interval_min

def execute_dca_investment(self, current_price):
    """
    执行定投操作
    :param current_price: 当前价格
    :return: 订单信息或None
    """
    # 计算投资数量
    if self.frac_shares:  # 支持碎股
        investment_qty = self.qty
    else:
        investment_qty = int(self.qty)
    
    # 资金检查（回测环境）
    if hasattr(self, 'virtual_balance') and self.virtual_balance:
        required_amount = investment_qty * current_price
        if required_amount > self.virtual_balance:
            print(f"[虚拟余额不足] 需要{required_amount}, 可用{self.virtual_balance}")
            return None
        
        # 扣减虚拟余额
        self.virtual_balance -= required_amount
    
    # 执行买单
    order_id = self.place_market_buy_order(investment_qty)
    
    # 更新投资时间
    self.last_investment_time = device_time(TimeZone.DEVICE_TIME_ZONE)
    
    return order_id
```

## Strategy V2 - 核心算法提取

### 1. 增强订单状态检查算法
```python
def enhanced_check_order_status(self, order_id, max_retries=120, retry_interval=0.5):
    """
    三层订单状态检查机制
    :param order_id: 订单ID
    :param max_retries: 最大重试次数
    :param retry_interval: 重试间隔(秒)
    :return: 执行信息字典或None
    """
    # 第一层：标准API查询
    exec_info = self._get_execution_info(order_id, self.stock)
    if exec_info and exec_info.get('total_qty', 0) > 0:
        return exec_info
    
    # 第二层：基于时间的成交记录查询
    exec_info = self._get_recent_trades_by_time(order_id)
    if exec_info:
        return exec_info
    
    # 第三层：Fallback机制
    exec_info = self._fallback_exec_info(order_id)
    
    return exec_info

def _get_execution_info(self, order_id, symbol):
    """标准执行信息查询"""
    try:
        exec_ids = request_executionid(order_id=order_id)
        if not exec_ids:
            return None
        
        total_qty = 0
        total_amount = 0
        trades = []
        
        for exec_id in exec_ids:
            exec_detail = get_executions_detail([exec_id])
            if exec_detail:
                detail = exec_detail[0]
                qty = detail.get('quantity', 0)
                price = detail.get('price', 0)
                
                total_qty += qty
                total_amount += qty * price
                trades.append({
                    'price': price,
                    'quantity': qty,
                    'exec_id': exec_id
                })
        
        if total_qty > 0:
            avg_price = total_amount / total_qty
            return {
                'total_qty': total_qty,
                'avg_price': avg_price,
                'trades': trades
            }
    except Exception as e:
        print(f"[执行信息查询异常] {e}")
    
    return None
```

### 2. 成交记录解析算法
```python
def _get_recent_trades_by_time(self, target_order_id=None, lookback_minutes=30):
    """
    从近期成交记录中查找订单信息
    :param target_order_id: 目标订单ID (可选)
    :param lookback_minutes: 回溯时间窗口(分钟)
    :return: 执行信息或None
    """
    try:
        # 计算时间范围
        end_time = datetime.now()
        start_time = end_time - timedelta(minutes=lookback_minutes)
        
        # 获取指定时间范围内的成交记录
        execution_ids = request_executionid(
            symbol=self.stock,
            start=start_time,
            end=end_time
        )
        
        if not execution_ids:
            return None
        
        # 解析成交记录
        matched_trades = []
        for exec_id in execution_ids:
            exec_detail = get_executions_detail([exec_id])
            if not exec_detail:
                continue
                
            detail = exec_detail[0]
            order_id = detail.get('order_id')
            
            # 如果指定了目标订单ID，只匹配该订单
            if target_order_id and order_id != target_order_id:
                continue
            
            # 提取交易信息
            side = detail.get('side')
            price = detail.get('price', 0)
            qty = detail.get('quantity', 0)
            exec_time = detail.get('exec_time')
            
            matched_trades.append({
                'order_id': order_id,
                'side': side,
                'price': price,
                'quantity': qty,
                'exec_time': exec_time,
                'exec_id': exec_id
            })
        
        # 聚合同一订单的交易
        if matched_trades:
            return self._aggregate_trades(matched_trades)
            
    except Exception as e:
        print(f"[成交记录查询异常] {e}")
    
    return None

def _aggregate_trades(self, trades):
    """聚合同一订单的多笔成交"""
    if not trades:
        return None
    
    total_qty = sum([t['quantity'] for t in trades])
    total_amount = sum([t['price'] * t['quantity'] for t in trades])
    avg_price = total_amount / total_qty if total_qty > 0 else 0
    
    return {
        'total_qty': total_qty,
        'avg_price': avg_price,
        'trades': trades,
        'order_id': trades[0]['order_id'],
        'side': trades[0]['side']
    }
```

### 3. 周期交易控制算法
```python
def check_period_trade_limit(self, trade_type):
    """
    检查周期交易限制
    :param trade_type: 'buy' 或 'sell'
    :return: bool (是否可以交易)
    """
    current_time = time.time()
    current_period = int(current_time // 60)  # 每分钟一个周期
    
    # 初始化或周期更新
    if (self.current_period_trades['period'] != current_period):
        self.current_period_trades = {
            'period': current_period,
            'buy_count': 0,
            'sell_count': 0,
            'grids': set()
        }
    
    # 检查交易次数限制
    if trade_type == 'buy' and self.current_period_trades['buy_count'] >= 2:
        return False
    elif trade_type == 'sell' and self.current_period_trades['sell_count'] >= 2:
        return False
    
    return True

def record_period_trade(self, trade_type, grid_price=None):
    """记录周期交易"""
    if trade_type == 'buy':
        self.current_period_trades['buy_count'] += 1
    elif trade_type == 'sell':
        self.current_period_trades['sell_count'] += 1
    
    if grid_price:
        self.current_period_trades['grids'].add(grid_price)
```

## Strategy V3 - 核心算法提取

### 1. 动态网格生成算法
```python
def generate_dynamic_grids(self, base_price, grid_percentage, grid_count, 
                          use_price_range=False, min_price=0, max_price=float('inf')):
    """
    动态网格生成算法
    :param base_price: 基准价格
    :param grid_percentage: 网格间距百分比
    :param grid_count: 网格总数
    :param use_price_range: 是否使用价格区间限制
    :param min_price: 最低价格限制
    :param max_price: 最高价格限制
    :return: 网格价格列表
    """
    grid_spacing = base_price * grid_percentage
    half_grids = grid_count // 2
    
    grid_prices = []
    
    # 生成对称网格
    for i in range(-half_grids, half_grids + 1):
        grid_price = base_price + (i * grid_spacing)
        
        # 价格区间过滤
        if use_price_range:
            if min_price <= grid_price <= max_price:
                grid_prices.append(round(grid_price, 2))
        else:
            if grid_price > 0:  # 确保价格为正
                grid_prices.append(round(grid_price, 2))
    
    return sorted(grid_prices)

def reset_grids(self, current_price, reason="价格偏离"):
    """
    网格重置算法
    :param current_price: 当前价格
    :param reason: 重置原因
    """
    print(f"[网格重置] 原因: {reason}, 基准价格: {current_price}")
    
    # 保存当前持仓状态
    old_positions = self.positions.copy()
    
    # 重新生成网格
    new_grids = self.generate_dynamic_grids(
        base_price=current_price,
        grid_percentage=self.grid_percentage,
        grid_count=self.grid_count,
        use_price_range=self.use_price_range,
        min_price=self.min_price_range,
        max_price=self.max_price_range
    )
    
    # 更新网格价格
    self.grid_prices = new_grids
    
    # 重新分配持仓
    self._redistribute_positions(old_positions)
    
    # 记录重置时间
    self.last_reset_time = time.time()

def _redistribute_positions(self, old_positions):
    """
    持仓重新分配算法
    将旧网格的持仓分配到新网格中
    """
    # 重置新网格持仓
    self.positions = {price: 0 for price in self.grid_prices}
    self.position_records = {price: [] for price in self.grid_prices}
    
    # 计算需要重新分配的总持仓
    total_old_position = sum(old_positions.values())
    
    if total_old_position == 0:
        return
    
    print(f"[持仓重新分配] 总持仓: {total_old_position}")
    
    # 按价格从低到高分配持仓
    remaining_position = total_old_position
    for grid_price in sorted(self.grid_prices):
        if remaining_position <= 0:
            break
        
        # 分配数量 (可以是简单平均分配或根据策略调整)
        allocation = min(remaining_position, self.max_grid_position)
        
        if allocation > 0:
            self.positions[grid_price] = allocation
            self.position_records[grid_price].append({
                'quantity': allocation,
                'price': grid_price,
                'type': 'redistribution',
                'timestamp': time.time()
            })
            remaining_position -= allocation
    
    # 处理剩余持仓 (移入手动持仓)
    if remaining_position > 0:
        current_price = current_price(self.stock)
        if current_price not in self.manual_positions:
            self.manual_positions[current_price] = 0
        self.manual_positions[current_price] += remaining_position
        print(f"[剩余持仓] {remaining_position}股移入手动持仓，价格: {current_price}")
```

### 2. 多层持仓管理算法
```python
def sync_all_positions(self, force_sync=False):
    """
    多层持仓同步算法
    :param force_sync: 是否强制同步
    :return: 同步结果
    """
    try:
        # 获取API实际持仓
        actual_position = position_holding_qty(self.stock)
        
        # 计算策略记录的总持仓
        grid_position = sum(self.positions.values())
        high_position = sum(self.high_positions.values()) if hasattr(self, 'high_positions') else 0
        manual_position = sum(self.manual_positions.values()) if hasattr(self, 'manual_positions') else 0
        
        total_recorded = grid_position + high_position + manual_position
        
        # 计算差异
        position_diff = actual_position - total_recorded
        
        print(f"[持仓同步] API持仓: {actual_position}, 记录持仓: {total_recorded}, 差异: {position_diff}")
        
        # 如果差异较小且非强制同步，跳过
        if abs(position_diff) <= 1 and not force_sync:
            return {'status': 'no_sync_needed', 'diff': position_diff}
        
        # 执行同步
        if position_diff > 0:
            # 实际持仓大于记录，可能有未记录的买入
            self._handle_missing_positions(position_diff)
        elif position_diff < 0:
            # 实际持仓小于记录，可能有未记录的卖出
            self._handle_excess_positions(abs(position_diff))
        
        return {'status': 'synced', 'diff': position_diff}
        
    except Exception as e:
        print(f"[持仓同步异常] {e}")
        return {'status': 'error', 'error': str(e)}

def _handle_missing_positions(self, missing_qty):
    """
    处理缺失持仓 (实际>记录)
    通过成交记录恢复或隔离处理
    """
    print(f"[缺失持仓处理] 缺失数量: {missing_qty}")
    
    # 尝试从成交记录恢复
    recovered = self._recover_from_trade_records(missing_qty)
    
    if recovered < missing_qty:
        # 无法完全恢复，剩余部分移入隔离持仓
        remaining = missing_qty - recovered
        current_price = current_price(self.stock)
        
        if current_price not in self.manual_positions:
            self.manual_positions[current_price] = 0
        
        self.manual_positions[current_price] += remaining
        print(f"[隔离处理] {remaining}股移入隔离持仓，价格: {current_price}")

def _handle_excess_positions(self, excess_qty):
    """
    处理多余持仓 (记录>实际)
    按优先级清理持仓记录
    """
    print(f"[多余持仓处理] 多余数量: {excess_qty}")
    
    remaining = excess_qty
    
    # 优先级1: 清理高位持仓
    if hasattr(self, 'high_positions') and self.high_positions and remaining > 0:
        remaining = self._reduce_positions(self.high_positions, remaining, "高位持仓")
    
    # 优先级2: 清理网格持仓 (从高价开始)
    if remaining > 0:
        sorted_grids = sorted(self.positions.items(), key=lambda x: x[0], reverse=True)
        temp_positions = dict(sorted_grids)
        remaining = self._reduce_positions(temp_positions, remaining, "网格持仓")
        # 更新实际的网格持仓
        for price, qty in temp_positions.items():
            self.positions[price] = qty
    
    # 优先级3: 清理手动持仓
    if hasattr(self, 'manual_positions') and self.manual_positions and remaining > 0:
        remaining = self._reduce_positions(self.manual_positions, remaining, "手动持仓")
    
    if remaining > 0:
        print(f"[持仓同步警告] 仍有{remaining}股无法解释的持仓差异")

def _reduce_positions(self, position_dict, target_reduction, position_type):
    """
    按比例减少指定持仓字典中的持仓
    :param position_dict: 持仓字典 {价格: 数量}
    :param target_reduction: 目标减少数量
    :param position_type: 持仓类型 (用于日志)
    :return: 剩余未减少的数量
    """
    total_positions = sum(position_dict.values())
    if total_positions == 0:
        return target_reduction
    
    remaining_reduction = target_reduction
    
    # 按价格从高到低减少持仓
    for price in sorted(position_dict.keys(), reverse=True):
        if remaining_reduction <= 0:
            break
            
        current_qty = position_dict[price]
        if current_qty <= 0:
            continue
        
        # 计算该价格需要减少的数量
        reduction = min(current_qty, remaining_reduction)
        position_dict[price] = current_qty - reduction
        remaining_reduction -= reduction
        
        print(f"[{position_type}减持] 价格{price}: {current_qty} -> {position_dict[price]} (减少{reduction})")
    
    return remaining_reduction
```

## Strategy V3.1 - 核心算法提取

### 1. 资金感知型下单算法
```python
def place_intelligent_buy_order(self, target_quantity, current_price, order_type='market'):
    """
    资金感知型智能下单算法
    :param target_quantity: 目标下单数量
    :param current_price: 当前市价
    :param order_type: 订单类型
    :return: 订单结果
    """
    try:
        # 获取实际可用资金
        available_cash = total_cash(currency=Currency.USD)
        
        # 获取最大可购买数量 (基于现金和保证金)
        max_buyable_qty = max_qty_to_buy_on_cash(
            symbol=self.stock,
            order_type=OrdType.MKT if order_type == 'market' else OrdType.LMT,
            price=current_price
        )
        
        # 获取当前持仓和持仓限制
        current_position = position_holding_qty(self.stock)
        remaining_position_limit = self.position_limit - current_position
        
        # 综合约束计算最终下单数量
        final_quantity = min(
            target_quantity,           # 策略目标数量
            max_buyable_qty,          # 资金约束数量
            remaining_position_limit,  # 持仓限制约束
            self.max_single_order_qty if hasattr(self, 'max_single_order_qty') else float('inf')
        )
        
        # 数量有效性检查
        if final_quantity <= 0:
            reason = self._get_constraint_reason(
                target_quantity, max_buyable_qty, 
                remaining_position_limit, available_cash
            )
            print(f"[智能下单] 跳过买单: {reason}")
            return None
        
        # 执行下单
        if order_type == 'market':
            order_id = place_market_order(self.stock, OrderSide.BUY, final_quantity)
        else:
            order_id = place_limit_order(self.stock, OrderSide.BUY, final_quantity, current_price)
        
        print(f"[智能下单] 目标数量: {target_quantity}, 实际下单: {final_quantity}, 订单ID: {order_id}")
        
        return {
            'order_id': order_id,
            'target_qty': target_quantity,
            'actual_qty': final_quantity,
            'price': current_price,
            'available_cash': available_cash,
            'max_buyable_qty': max_buyable_qty
        }
        
    except Exception as e:
        print(f"[智能下单异常] {e}")
        return None

def _get_constraint_reason(self, target_qty, max_buyable_qty, remaining_limit, available_cash):
    """
    分析约束原因
    :return: 约束原因字符串
    """
    if max_buyable_qty <= 0:
        return f"资金不足(可用: ${available_cash:.2f})"
    elif remaining_limit <= 0:
        return f"持仓已满(限制: {self.position_limit})"
    elif target_qty <= 0:
        return f"目标数量无效({target_qty})"
    else:
        return "未知约束"
```

### 2. 参数自动校验算法
```python
def validate_and_adjust_parameters(self):
    """
    参数自动校验和调整算法
    确保参数配置的合理性和一致性
    :return: 调整结果报告
    """
    adjustments = []
    warnings = []
    
    try:
        # 1. 数量整除关系检查
        if hasattr(self, 'position_limit') and hasattr(self, 'min_order_quantity'):
            if self.position_limit % self.min_order_quantity != 0:
                adjusted_limit = (self.position_limit // self.min_order_quantity) * self.min_order_quantity
                adjustments.append({
                    'parameter': 'position_limit',
                    'old_value': self.position_limit,
                    'new_value': adjusted_limit,
                    'reason': '调整为最小下单数量的整倍数'
                })
                self.position_limit = adjusted_limit
        
        # 2. 网格数量合理性检查
        if hasattr(self, 'grid_count'):
            if self.grid_count > 30:
                adjustments.append({
                    'parameter': 'grid_count',
                    'old_value': self.grid_count,
                    'new_value': 30,
                    'reason': '限制最大网格数量以提升性能'
                })
                self.grid_count = 30
            elif self.grid_count < 3:
                adjustments.append({
                    'parameter': 'grid_count',
                    'old_value': self.grid_count,
                    'new_value': 5,
                    'reason': '确保最小有效网格数量'
                })
                self.grid_count = 5
        
        # 3. 价格区间检查
        if hasattr(self, 'min_price_range') and hasattr(self, 'max_price_range'):
            if self.min_price_range >= self.max_price_range:
                adjustments.append({
                    'parameter': 'price_range',
                    'old_value': f'[{self.min_price_range}, {self.max_price_range}]',
                    'new_value': '[0.0, 999999.0]',
                    'reason': '价格区间设置错误，已重置'
                })
                self.min_price_range = 0.0
                self.max_price_range = 999999.0
        
        # 4. 网格间距合理性检查
        if hasattr(self, 'grid_spacing_pct'):
            if self.grid_spacing_pct > 0.20:  # 20%
                warnings.append({
                    'parameter': 'grid_spacing_pct',
                    'value': self.grid_spacing_pct,
                    'warning': '网格间距过大，可能导致交易机会减少'
                })
            elif self.grid_spacing_pct < 0.005:  # 0.5%
                warnings.append({
                    'parameter': 'grid_spacing_pct',
                    'value': self.grid_spacing_pct,
                    'warning': '网格间距过小，可能导致频繁交易'
                })
        
        # 5. 资金使用率检查
        if hasattr(self, 'max_capital_usage'):
            if self.max_capital_usage > 1.0:
                adjustments.append({
                    'parameter': 'max_capital_usage',
                    'old_value': self.max_capital_usage,
                    'new_value': 1.0,
                    'reason': '资金使用率不能超过100%'
                })
                self.max_capital_usage = 1.0
        
        # 6. 超时参数检查
        if hasattr(self, 'order_timeout'):
            if self.order_timeout < 30:
                adjustments.append({
                    'parameter': 'order_timeout',
                    'old_value': self.order_timeout,
                    'new_value': 30,
                    'reason': '订单超时时间过短，调整为30秒'
                })
                self.order_timeout = 30
            elif self.order_timeout > 600:
                adjustments.append({
                    'parameter': 'order_timeout',
                    'old_value': self.order_timeout,
                    'new_value': 600,
                    'reason': '订单超时时间过长，调整为10分钟'
                })
                self.order_timeout = 600
        
        # 输出调整结果
        if adjustments:
            print("[参数自动调整]:")
            for adj in adjustments:
                print(f"  • {adj['parameter']}: {adj['old_value']} → {adj['new_value']} ({adj['reason']})")
        
        if warnings:
            print("[参数配置警告]:")
            for warn in warnings:
                print(f"  ⚠ {warn['parameter']}: {warn['warning']}")
        
        if not adjustments and not warnings:
            print("[参数校验] 所有参数配置正常")
        
        return {
            'adjustments_count': len(adjustments),
            'warnings_count': len(warnings),
            'adjustments': adjustments,
            'warnings': warnings,
            'status': 'completed'
        }
        
    except Exception as e:
        print(f"[参数校验异常] {e}")
        return {
            'adjustments_count': 0,
            'warnings_count': 0,
            'status': 'error',
            'error': str(e)
        }
```

### 3. 性能优化算法
```python
class BacktestOptimizer:
    """回测性能优化器"""
    
    def __init__(self, strategy):
        self.strategy = strategy
        self.optimization_enabled = getattr(strategy, 'enable_backtest_optimization', False)
        self.minimal_logging = getattr(strategy, 'minimal_logging', False)
        
        # 缓存机制
        self.position_cache = {}
        self.price_cache = {}
        self.cache_expiry = 60  # 缓存60秒
        
    def optimized_position_sync(self):
        """
        优化的持仓同步 - 回测模式下可选择跳过
        """
        if not self.optimization_enabled:
            return self.strategy.sync_positions()  # 标准同步
        
        # 回测优化模式
        if getattr(self.strategy, 'is_backtest', False):
            # 使用缓存的持仓数据，避免频繁API调用
            cache_key = f"position_{self.strategy.stock}"
            current_time = time.time()
            
            if (cache_key in self.position_cache and 
                current_time - self.position_cache[cache_key]['timestamp'] < self.cache_expiry):
                return self.position_cache[cache_key]['data']
            
            # 执行同步并缓存结果
            sync_result = self.strategy.sync_positions()
            self.position_cache[cache_key] = {
                'data': sync_result,
                'timestamp': current_time
            }
            
            return sync_result
        
        # 实盘模式正常同步
        return self.strategy.sync_positions()
    
    def optimized_logging(self, level, message, force_output=False):
        """
        优化的日志输出
        :param level: 日志级别 (DEBUG, INFO, WARNING, ERROR)
        :param message: 日志消息
        :param force_output: 强制输出
        """
        if force_output:
            print(f"[{level}] {message}")
            return
            
        # 非优化模式 - 正常输出
        if not self.optimization_enabled:
            print(f"[{level}] {message}")
            return
        
        # 优化模式 - 选择性输出
        if self.minimal_logging:
            # 仅输出重要信息
            if level in ['WARNING', 'ERROR'] or '买入' in message or '卖出' in message:
                print(f"[{level}] {message}")
        else:
            # 过滤调试信息
            if level != 'DEBUG':
                print(f"[{level}] {message}")
    
    def batch_operations(self, operations):
        """
        批量操作优化
        :param operations: 操作列表 [{'type': 'buy', 'grid_price': 100, 'quantity': 10}, ...]
        :return: 批量执行结果
        """
        if not self.optimization_enabled or len(operations) <= 1:
            # 非优化模式或单个操作，逐个执行
            results = []
            for op in operations:
                result = self._execute_single_operation(op)
                results.append(result)
            return results
        
        # 批量优化执行
        return self._execute_batch_operations(operations)
    
    def _execute_batch_operations(self, operations):
        """批量执行操作"""
        results = []
        
        # 按类型分组
        buy_ops = [op for op in operations if op['type'] == 'buy']
        sell_ops = [op for op in operations if op['type'] == 'sell']
        
        # 批量执行买入操作
        if buy_ops:
            buy_results = self._batch_buy_orders(buy_ops)
            results.extend(buy_results)
        
        # 批量执行卖出操作
        if sell_ops:
            sell_results = self._batch_sell_orders(sell_ops)
            results.extend(sell_results)
        
        return results
    
    def _batch_buy_orders(self, buy_operations):
        """批量买入订单"""
        total_quantity = sum([op['quantity'] for op in buy_operations])
        
        # 检查资金约束
        available_cash = total_cash(currency=Currency.USD)
        current_price = current_price(self.strategy.stock)
        required_cash = total_quantity * current_price
        
        if required_cash > available_cash:
            # 资金不足，按比例缩减
            ratio = available_cash / required_cash
            for op in buy_operations:
                op['quantity'] = int(op['quantity'] * ratio)
        
        # 执行批量买入
        results = []
        for op in buy_operations:
            if op['quantity'] > 0:
                order_id = place_market_order(
                    self.strategy.stock, 
                    OrderSide.BUY, 
                    op['quantity']
                )
                results.append({
                    'operation': op,
                    'order_id': order_id,
                    'status': 'success'
                })
            else:
                results.append({
                    'operation': op,
                    'order_id': None,
                    'status': 'skipped_insufficient_funds'
                })
        
        return results
    
    def _batch_sell_orders(self, sell_operations):
        """批量卖出订单"""
        results = []
        
        # 按盈利从高到低排序，优先卖出高盈利网格
        sorted_ops = sorted(sell_operations, 
                          key=lambda x: x.get('profit_pct', 0), 
                          reverse=True)
        
        for op in sorted_ops:
            order_id = place_market_order(
                self.strategy.stock,
                OrderSide.SELL,
                op['quantity']
            )
            results.append({
                'operation': op,
                'order_id': order_id,
                'status': 'success'
            })
        
        return results
```

## 算法迁移建议总结

### 优先迁移算法 (核心价值高)
1. **Strategy V1 分层加仓算法** - 独特的智能加仓机制
2. **Strategy V2 增强订单同步** - 解决订单延迟的完整方案  
3. **Strategy V3_1 资金感知下单** - 智能资金管理
4. **Strategy V3 动态网格生成** - 灵活的网格交易基础

### 架构改进建议
1. **数据持久化** - 使用数据库存储所有历史状态
2. **异步处理** - 使用asyncio提升并发性能
3. **模块化设计** - 每个算法封装为独立模块
4. **配置管理** - 使用配置文件统一参数管理
5. **监控告警** - 集成完善的监控和通知系统

### 性能优化重点
1. **缓存机制** - 减少重复计算和API调用
2. **批量处理** - 优化订单执行效率
3. **智能日志** - 可配置的日志输出级别
4. **内存管理** - 优化大量历史数据的存储

这些核心算法和优化策略将为独立Python应用奠定坚实的技术基础。