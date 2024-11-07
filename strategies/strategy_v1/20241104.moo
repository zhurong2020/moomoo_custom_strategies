class Strategy(StrategyBase):
    def initialize(self):
        """初始化策略"""
        self.trigger_symbols()
        self.custom_indicator()
        self.global_variables()

    def trigger_symbols(self):
        """定义运行标的"""
        self.trading_symbol = declare_trig_symbol()

    def custom_indicator(self):
        """设置技术指标"""
        self.register_indicator(
            indicator_name='MA', 
            script='''MA1:MA(CLOSE,20),COLORFF8D1E;''', 
            param_list=['20']
        )

    def global_variables(self):
        """定义全局变量"""
        # 策略参数
        self.grid_percentage = show_variable(2.0, GlobalType.FLOAT)  # 网格间距(%)
        self.initial_capital = show_variable(90000.0, GlobalType.FLOAT)  # 初始资金
        self.position_limit = show_variable(0.05, GlobalType.FLOAT)  # 单次建仓比例
        self.max_positions_per_grid = show_variable(3, GlobalType.INT)  # 单网格最大持仓
        self.capital_reserve = show_variable(0.1, GlobalType.FLOAT)  # 资金保留比例
        self.min_quantity = show_variable(200, GlobalType.INT)  # 最小交易数量
        self.max_quantity = show_variable(200, GlobalType.INT)  # 最大交易数量
        self.price_adjust = show_variable(0.001, GlobalType.FLOAT)  # 委托价格调整比例
        self.profit_percentage = show_variable(1.5, GlobalType.FLOAT)  # 获利目标(%)
        self.order_timeout = 5  # 订单超时时间(秒)
        self.max_retries = 2  # 最大重试次数
        
        # 资金管理
        self.available_capital = self.initial_capital * (1 - self.capital_reserve)
        
        # 内部状态变量
        self.grids = {}  # 网格信息
        self.base_price = None  # 基准价格
        self.total_position = 0  # 总持仓
        self.last_trade_time = None  # 最后交易时间
        self.base_quantity = None  # 基础交易量
        self.last_quantity_update = None  # 上次更新数量时间

    def get_current_time(self):
        """统一的时间获取函数"""
        try:
            current_time = device_time(TimeZone.ET)
            # 检查无效时间
            if current_time.year < 2000:
                print(f"警告：检测到无效时间戳: {current_time}")
                return None
            return current_time
        except Exception as e:
            print(f"获取时间出错: {str(e)}")
            return None
    
    def round_price(self, price):
        """统一的价格取整方法"""
        return round(price * 10) / 10

    def round_quantity(self, qty):
        """统一的数量取整方法"""
        return max(self.min_quantity, int(qty / 10) * 10)

    def is_trading_time(self):
        """检查是否在交易时间"""
        current_time = self.get_current_time()
        if not current_time:
            return False
        # 严格限制在9:30执行
        return current_time.hour == 9 and current_time.minute == 30
        
    def can_trade_today(self):
        """检查是否可以在当天交易"""
        current_time = self.get_current_time()
        if not current_time:
            return False
        if self.last_trade_time is None:
            return True
        return current_time.date() != self.last_trade_time.date()

    def find_closest_grid(self, price, grid_prices):
        """找到最接近的网格价格"""
        if not grid_prices:
            return None
            
        closest_grid = None
        min_diff = float('inf')
        
        for grid_price in grid_prices:
            diff = abs(int(grid_price * 10) - int(price * 10))
            if diff < min_diff:
                min_diff = diff
                closest_grid = grid_price
                
        return closest_grid
        
    def calculate_base_quantity(self, current_price):
        """计算基础交易量"""
        try:
            print(f"\n计算基础交易量:")
            print(f"当前价格: {current_price:.2f}")
            
            # 计算每网格资金量
            grid_capital = self.available_capital * self.position_limit
            print(f"单网格资金: {grid_capital:.2f}")
            
            # 计算基础交易量
            theoretical_qty = int(grid_capital / current_price)
            base_quantity = self.round_quantity(theoretical_qty)
            print(f"计算得到基础交易量: {base_quantity}")
            
            return base_quantity
            
        except Exception as e:
            print(f"计算基础交易量出错: {str(e)}")
            return self.min_quantity

    def update_base_quantity(self, current_price):
        """更新基础交易量"""
        try:
            current_time = device_time(TimeZone.ET)
            
            # 检查是否需要更新
            if (self.base_quantity is None or 
                self.last_quantity_update is None or
                (current_time - self.last_quantity_update).days >= 7):
                
                new_quantity = self.calculate_base_quantity(current_price)
                
                # 限制变化幅度
                if self.base_quantity is not None:
                    max_change = 0.3
                    min_qty = self.round_quantity(self.base_quantity * (1 - max_change))
                    max_qty = self.round_quantity(self.base_quantity * (1 + max_change))
                    new_quantity = max(min_qty, min(new_quantity, max_qty))
                
                self.base_quantity = new_quantity
                self.last_quantity_update = current_time
                print(f"更新基础交易量: {self.base_quantity} 股")
                
            return self.base_quantity
            
        except Exception as e:
            print(f"更新基础交易量出错: {str(e)}")
            return self.min_quantity

    def initialize_grids(self, price):
        """初始化/重置网格"""
        try:
            # 保存原有持仓
            old_positions = {}
            if self.grids:
                for grid_price, grid in self.grids.items():
                    if grid['positions']:
                        old_positions[grid_price] = grid['positions'].copy()
            
            # 计算新网格价格
            self.base_price = self.round_price(price)
            percentage_interval = self.grid_percentage / 100
            grid_prices = []
            
            # 创建对称网格
            for i in range(-5, 6):
                grid_price = self.round_price(price * (1 + i * percentage_interval))
                grid_prices.append(grid_price)
            
            # 初始化新网格
            self.grids = {
                price: {
                    'positions': [],
                    'total_quantity': 0,
                    'last_trade_time': None
                }
                for price in grid_prices
            }
            
            # 迁移原有持仓到新网格
            total_quantity = 0
            if old_positions:
                for old_price, positions in old_positions.items():
                    closest_grid = self.find_closest_grid(old_price, grid_prices)
                    if closest_grid:
                        self.grids[closest_grid]['positions'].extend(positions)
                        position_quantity = sum(p['quantity'] for p in positions)
                        self.grids[closest_grid]['total_quantity'] += position_quantity
                        total_quantity += position_quantity
            
            # 更新总持仓
            self.total_position = total_quantity
            
            grid_prices_str = ', '.join([f"{p:.1f}" for p in sorted(grid_prices)])
            print(f"网格初始化完成，基准价格: {self.base_price:.1f}，网格价格: [{grid_prices_str}]")
            
        except Exception as e:
            print(f"初始化网格出错: {str(e)}")

    def need_reset_grids(self, price):
        """检查是否需要重置网格"""
        try:
            if not self.grids:
                return True
                
            grid_prices = sorted(self.grids.keys())
            lowest_grid = grid_prices[0]
            highest_grid = grid_prices[-1]
            
            # 添加缓冲区避免频繁重置
            buffer_percentage = self.grid_percentage * 0.5 / 100
            lower_bound = self.round_price(lowest_grid * (1 - buffer_percentage))
            upper_bound = self.round_price(highest_grid * (1 + buffer_percentage))
            
            print(f"\n检查网格重置:")
            print(f"当前价格: {price:.1f}")
            print(f"网格范围: [{lower_bound:.1f}, {upper_bound:.1f}]")
            print(f"当前总持仓: {self.total_position}")
            
            return price < lower_bound or price > upper_bound
            
        except Exception as e:
            print(f"检查网格重置出错: {str(e)}")
            return False

    def place_order_with_check(self, symbol, price, qty, side, time_in_force):
        """优化的订单处理逻辑"""
        try:
            # 限制总执行时间
            max_total_time = 30  # 最大总执行时间（秒）
            start_time = time.time()
            
            for attempt in range(self.max_retries):
                # 检查总执行时间
                if time.time() - start_time > max_total_time:
                    print("订单执行总时间超过限制")
                    return False, 0, None, 0.0
                
                # 调整委托价格
                if side == OrderSide.BUY:
                    adjusted_price = self.round_price(price * (1 + self.price_adjust * (attempt + 1)))
                else:
                    adjusted_price = self.round_price(price * (1 - self.price_adjust * (attempt + 1)))
                    
                order_id = place_limit(
                    symbol=symbol,
                    price=adjusted_price,
                    qty=qty,
                    side=side,
                    time_in_force=time_in_force
                )
                
                if not order_id:
                    if attempt < self.max_retries - 1:
                        continue
                    return False, 0, None, 0.0
                
                # 立即检查订单状态
                try:
                    status = order_status(order_id)
                    if status == "FILLED_ALL":
                        try:
                            filled_qty = order_filled_qty(order_id)
                            return True, filled_qty, order_id, adjusted_price
                        except:
                            return True, qty, order_id, adjusted_price
                            
                    # 等待很短时间后再次检查
                    time.sleep(0.5)
                    status = order_status(order_id)
                    if status == "FILLED_ALL":
                        try:
                            filled_qty = order_filled_qty(order_id)
                            return True, filled_qty, order_id, adjusted_price
                        except:
                            return True, qty, order_id, adjusted_price
                except:
                    pass
                
                # 如果未成交，撤单并继续
                try:
                    cancel_order_by_orderid(order_id)
                except:
                    pass
                    
            return False, 0, None, 0.0
            
        except Exception as e:
            print(f"下单异常: {str(e)}")
            return False, 0, None, 0.0
            
    def execute_first_position(self, price):
        """执行首次建仓"""
        try:
            print(f"尝试执行首次建仓，价格: {price}")
            qty = self.calculate_position_size(price)
            if qty <= 0:
                print("建仓数量为0，不执行建仓")
                return
                
            success, filled_qty, order_id, filled_price = self.place_order_with_check(
                symbol=self.trading_symbol,
                price=price,
                qty=qty,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if success and filled_qty > 0:
                current_time = device_time(TimeZone.ET)
                closest_grid = self.find_closest_grid(filled_price, self.grids.keys())
                
                if closest_grid:
                    grid = self.grids[closest_grid]
                    grid['positions'].append({
                        'price': filled_price,
                        'quantity': filled_qty,
                        'time': current_time,
                        'order_id': order_id
                    })
                    grid['total_quantity'] += filled_qty
                    grid['last_trade_time'] = current_time
                    self.total_position += filled_qty
                    self.last_trade_time = current_time
                    print(f"持仓更新到网格 {closest_grid}, 成交价格: {filled_price}")
                    self.print_position_summary()
                
        except Exception as e:
            print(f"执行首次建仓出错: {str(e)}")

    def calculate_position_size(self, price):
        """计算交易数量"""
        try:
            print(f"\n计算交易数量:")
            print(f"当前价格: {price:.2f}")
            print(f"当前总持仓: {self.total_position}")
            
            # 更新并获取基础交易量
            current_quantity = self.update_base_quantity(price)
            
            # 检查资金占用
            estimated_capital = (self.total_position + current_quantity) * price
            print(f"预估资金占用: {estimated_capital:.2f}/{self.available_capital:.2f}")
            
            if estimated_capital > self.available_capital:
                print("超过可用资金限制")
                return 0
                
            return current_quantity
            
        except Exception as e:
            print(f"计算交易数量出错: {str(e)}")
            return 0

    def check_sell_grids(self, price):
        """检查可获利了结的持仓"""
        try:
            print(f"\n检查卖出条件,当前价格: {price:.1f}")
            sell_grids = {}
            
            for grid_price, grid in self.grids.items():
                if grid['total_quantity'] > 0:
                    print(f"\n检查网格 {grid_price}, 当前持仓量: {grid['total_quantity']}")
                    positions_to_sell = []
                    total_sell_quantity = 0
                    
                    for position in grid['positions']:
                        target_price = self.round_price(position['price'] * (1 + self.profit_percentage/100))
                        print(f"- 持仓信息: 买入价格={position['price']}, 数量={position['quantity']}, 目标价格={target_price}")
                        
                        if price >= target_price:
                            print("  > 达到获利目标,将加入卖出列表")
                            positions_to_sell.append(position)
                            total_sell_quantity += position['quantity']
                        else:
                            print("  > 继续持有")
                            
                    if positions_to_sell:
                        sell_price = self.round_price(price)
                        print(f"网格 {grid_price} 共有 {len(positions_to_sell)} 个持仓需要卖出,总数量: {total_sell_quantity}")
                        sell_grids[sell_price] = {
                            'total_quantity': total_sell_quantity,
                            'grids': [(grid_price, grid)],
                            'positions': positions_to_sell
                        }
                    else:
                        print(f"网格 {grid_price} 没有需要卖出的持仓")
                        
            if not sell_grids:
                print("没有找到需要卖出的持仓")
                
            return sell_grids
            
        except Exception as e:
            print(f"检查卖出网格出错: {str(e)}")
            return {}

    def execute_buy_order(self, grid_price, current_price):
        """执行买入订单"""
        try:
            qty = self.calculate_position_size(current_price)
            if qty <= 0:
                return
                
            success, filled_qty, order_id, filled_price = self.place_order_with_check(
                symbol=self.trading_symbol,
                price=current_price,
                qty=qty,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if success and filled_qty > 0:
                current_time = device_time(TimeZone.ET)
                grid = self.grids[grid_price]
                grid['positions'].append({
                    'price': filled_price,
                    'quantity': filled_qty,
                    'time': current_time,
                    'order_id': order_id
                })
                grid['total_quantity'] += filled_qty
                grid['last_trade_time'] = current_time
                self.total_position += filled_qty
                
                print(f"买入成功: 网格={grid_price}, 数量={filled_qty}, 成交价格={filled_price}, 总持仓={self.total_position}")
                self.print_position_summary()
                
        except Exception as e:
            print(f"执行买入订单出错: {str(e)}")

    def execute_sell_orders(self, sell_grids):
        """执行卖出订单"""
        try:
            current_time = device_time(TimeZone.ET)
            for sell_price, sell_info in sell_grids.items():
                success, filled_qty, order_id, filled_price = self.place_order_with_check(
                    symbol=self.trading_symbol,
                    price=sell_price,
                    qty=sell_info['total_quantity'],
                    side=OrderSide.SELL,
                    time_in_force=TimeInForce.DAY
                )
                
                if success and filled_qty > 0:
                    self.last_trade_time = current_time
                    for grid_price, grid in sell_info['grids']:
                        # 移除已卖出的持仓
                        new_positions = [pos for pos in grid['positions'] 
                                       if pos not in sell_info['positions']]
                        grid['positions'] = new_positions
                        grid['total_quantity'] -= filled_qty
                        grid['last_trade_time'] = current_time
                        self.total_position -= filled_qty
                        print(f"成功卖出网格 {grid_price} 的 {filled_qty} 股，实际成交价格: {filled_price}")
                    
                    self.print_position_summary()
                    
        except Exception as e:
            print(f"执行卖出订单出错: {str(e)}")

    def handle_data(self):
        """优化的主策略逻辑"""
        try:
            # 使用统一的时间获取函数
            current_time = self.get_current_time()
            if not current_time:
                return
                
            # 严格检查交易时间
            if not self.is_trading_time():
                return
                
            # 检查当日是否可交易
            if not self.can_trade_today():
                return
                
            print(f"\n开始执行交易决策，时间: {current_time}")
            
            try:
                # 只获取前一个交易日的收盘价
                prev_close = bar_close(
                    symbol=self.trading_symbol, 
                    bar_type=BarType.D1, 
                    select=1
                )
                if prev_close is None or prev_close <= 0:
                    print("获取价格数据无效")
                    return
                    
            except APIException as e:
                print(f"获取K线数据失败: {str(e)}")
                return
                
            # 执行策略逻辑
            if self.base_price is None or self.need_reset_grids(prev_close):
                print(f"初始化/重置网格，基准价格: {prev_close}")
                self.initialize_grids(prev_close)
                if self.total_position == 0:
                    self.execute_first_position(prev_close)
                return
                
            # 检查卖出机会
            sell_grids = self.check_sell_grids(prev_close)
            if sell_grids:
                self.execute_sell_orders(sell_grids)
                return  # 执行卖出后直接返回，避免同一天买入
                
            # 检查买入机会
            for grid_price in sorted(self.grids.keys()):
                grid = self.grids[grid_price]
                
                if len(grid['positions']) >= self.max_positions_per_grid:
                    continue
                    
                # 使用统一的日期检查
                if grid['last_trade_time'] and \
                   grid['last_trade_time'].date() == current_time.date():
                    continue
                
                # 计算价格区间
                lower_bound = self.round_price(grid_price * (1 - self.grid_percentage/100))
                upper_bound = self.round_price(grid_price * (1 + self.grid_percentage/100))
                
                if lower_bound <= prev_close <= upper_bound and \
                   self.find_closest_grid(prev_close, self.grids.keys()) == grid_price:
                    self.execute_buy_order(grid_price, prev_close)
                    break
                    
        except Exception as e:
            print(f"策略执行出错: {str(e)}")

    def print_position_summary(self):
        """打印持仓摘要"""
        try:
            print("\n==== 持仓摘要 ====")
            print(f"策略总持仓: {self.total_position}")
            actual_total = 0
            
            for grid_price, grid in sorted(self.grids.items()):
                if grid['total_quantity'] > 0:
                    print(f"\n网格 {grid_price} 持仓:")
                    grid_total = sum(pos['quantity'] for pos in grid['positions'])
                    if grid_total != grid['total_quantity']:
                        print(f"警告：网格持仓统计不一致 ({grid_total} != {grid['total_quantity']})")
                        grid['total_quantity'] = grid_total
                    print(f"网格总量: {grid['total_quantity']}")
                    for pos in sorted(grid['positions'], key=lambda x: x['price']):
                        print(f"- 数量: {pos['quantity']}, 价格: {pos['price']:.2f}")
                    actual_total += grid['total_quantity']
            
            if actual_total != self.total_position:
                print(f"警告：总持仓统计不一致 ({actual_total} != {self.total_position})")
                self.total_position = actual_total
                
        except Exception as e:
            print(f"打印持仓摘要出错: {str(e)}")