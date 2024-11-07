class Strategy(StrategyBase):
    def initialize(self):
        """初始化策略"""
        self.trigger_symbols()  # 必须首先调用
        self.custom_indicator()  # 其次调用
        self.global_variables()  # 最后调用

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
        self.grid_percentage = show_variable(2.0, GlobalType.FLOAT)  # 网格间距(百分比)
        self.initial_capital = show_variable(10000.0, GlobalType.FLOAT)  # 初始资金
        self.position_limit = show_variable(0.05, GlobalType.FLOAT)  # 单次建仓资金比例
        self.max_positions_per_grid = show_variable(3, GlobalType.INT)  # 单网格最大持仓次数
        self.capital_reserve = show_variable(0.1, GlobalType.FLOAT)  # 资金保留比例
        self.min_quantity = show_variable(1, GlobalType.INT)  # 最小交易数量
        self.max_quantity = show_variable(100, GlobalType.INT)  # 最大交易数量
        
        # 资金管理
        self.available_capital = self.initial_capital * (1 - self.capital_reserve)  # 可用资金
        
        # 内部状态变量
        self.grids = {}  # 存储网格信息的字典
        self.base_price = None  # 基准价格
        self.total_position = 0  # 跟踪总持仓
        self.last_buy_time = None   # 记录最后买入时间
        self.last_sell_time = None  # 记录最后卖出时间
        self.base_quantity = None  # 基础交易量
        self.last_quantity_update = None  # 上次更新基础交易量的时间
        self.last_trade_time = None  # 记录最后一次交易时间

    def calculate_base_quantity(self, current_price):
        """计算基础交易量"""
        try:
            # 计算可用资金
            available_capital = self.initial_capital * (1 - self.capital_reserve)
            
            # 计算每网格的目标资金量
            grid_capital = available_capital * self.position_limit
            
            # 计算理论上的交易数量
            theoretical_quantity = int(grid_capital / current_price)
            
            # 确保数量是10的倍数
            base_quantity = max(20, (theoretical_quantity // 10) * 10)
            
            # 限制在最小和最大交易数量之间
            base_quantity = min(base_quantity, self.max_quantity)
            
            return base_quantity
                
        except Exception as e:
            print(f"计算基础交易量出错: {str(e)}")
            return self.min_quantity

    def update_base_quantity(self, current_price):
        """定期更新基础交易量"""
        try:
            current_time = device_time(TimeZone.ET)
        
            # 首次设置或者超过7天没有更新
            if (self.base_quantity is None or 
                self.last_quantity_update is None or
                (current_time - self.last_quantity_update).days >= 7):
                
                new_quantity = self.calculate_base_quantity(current_price)
                
                # 如果已经有基础交易量，确保新的交易量变化不会太大
                if self.base_quantity is not None:
                    max_change = 0.3  # 最大允许30%的变化
                    min_new = int(self.base_quantity * (1 - max_change))
                    max_new = int(self.base_quantity * (1 + max_change))
                    new_quantity = max(min_new, min(new_quantity, max_new))
                    new_quantity = (new_quantity // 10) * 10  # 确保是10的倍数
                
                self.base_quantity = new_quantity
                self.last_quantity_update = current_time
                
                print(f"更新基础交易量: {self.base_quantity} 股, 当前价格: {current_price}")
                
            return self.base_quantity
            
        except Exception as e:
            print(f"更新基础交易量出错: {str(e)}")
            return self.min_quantity

    def calculate_position_size(self, price):
        """计算每次交易的数量"""
        try:
            # 更新基础交易量
            current_quantity = self.update_base_quantity(price)
            
            # 计算此次交易后的预估总资金占用
            estimated_capital = (self.total_position + current_quantity) * price
            max_allowed_capital = self.initial_capital * (1 - self.capital_reserve)
            
            # 如果超过最大资金限制，返回0
            if estimated_capital > max_allowed_capital:
                print(f"达到最大资金限制 {max_allowed_capital:.2f}，当前资金占用 {estimated_capital:.2f}")
                return 0
                
            return current_quantity
            
        except Exception as e:
            print(f"计算交易数量出错: {str(e)}")
            return 0

    def initialize_grids(self, price):
        """初始化网格"""
        try:
            self.base_price = price
            percentage_interval = self.grid_percentage / 100
            
            # 创建网格价位，精确到小数点后1位
            grid_prices = []
            for i in range(-5, 6):
                # 计算网格价格并四舍五入到1位小数
                price_float = price * (1 + i * percentage_interval)
                grid_price = round(price_float * 10) / 10  # 乘10再除10来保留1位小数
                grid_prices.append(grid_price)
            
            self.grids = {
                price: {
                    'positions': [],
                    'total_quantity': 0,
                    'last_trade_time': None,
                    'trades_today': 0
                }
                for price in grid_prices
            }
            
            grid_prices_str = ', '.join([f"{p:.1f}" for p in sorted(grid_prices)])
            print(f"网格初始化完成，基准价格: {price:.1f}，网格价格: [{grid_prices_str}]")
                
        except Exception as e:
            print(f"初始化网格出错: {str(e)}")

    def need_reset_grids(self, price):
        """判断是否需要重置网格"""
        try:
            if not self.grids:
                return True
                    
            grid_prices = sorted(self.grids.keys())
            lowest_grid = grid_prices[0]
            highest_grid = grid_prices[-1]
            
            # 计算边界价格并保留1位小数
            lower_bound = round(lowest_grid * (1 - self.grid_percentage/100) * 10) / 10
            upper_bound = round(highest_grid * (1 + self.grid_percentage/100) * 10) / 10
            
            # 如果价格超出网格范围，需要重置
            need_reset = price < lower_bound or price > upper_bound
            
            # 如果需要重置，也要遵循交易频率限制
            if need_reset:
                if not self.can_trade_in_period(self.last_buy_time):
                    return False
                print(f"价格 {price:.1f} 超出网格范围 [{lower_bound:.1f}, {upper_bound:.1f}], 需要重置网格")
                
            return need_reset
                       
        except Exception as e:
            print(f"检查网格重置出错: {str(e)}")
            return False

    def can_trade_in_period(self, last_trade_time):
        """检查当前K线周期是否可以交易"""
        current_time = device_time(TimeZone.ET)
        
        if last_trade_time is None:
            return True
            
        # 检查是否同一天
        return current_time.date() != last_trade_time.date()

    def place_order_with_check(self, symbol, price, qty, side, time_in_force):
        """下单并验证订单状态"""
        try:
            print(f"准备下单: 方向={side}, 价格={price}, 数量={qty}")
            order_id = place_limit(
                symbol=symbol,
                price=price,
                qty=qty,
                side=side,
                time_in_force=time_in_force
            )
            
            print(f"订单提交成功，订单ID: {order_id}")
            if order_id:
                status = order_status(order_id)
                print(f"订单状态: {status}")
                if status == "FILLED_ALL":
                    filled_qty = order_filled_qty(order_id)
                    print(f"订单完全成交，成交数量: {filled_qty}")
                    return True, filled_qty, order_id
            return False, 0, None
                
        except APIException as ex:
            print(f"下单失败: {ex.err_code}")
            return False, 0, None
        except Exception as e:
            print(f"下单异常: {str(e)}")
            return False, 0, None

    def execute_first_position(self, price):
        """执行首次建仓"""
        try:
            print(f"尝试执行首次建仓，价格: {price}")
            if not self.can_trade_in_period(self.last_buy_time):
                print("当日已有买入交易，不能建仓")
                return
                    
            qty = self.calculate_position_size(price)
            print(f"计算建仓数量: {qty}")
            if qty <= 0:
                print("建仓数量为0，不执行建仓")
                return
                    
            print(f"开始执行建仓订单，数量: {qty}, 价格: {price}")
            success, filled_qty, order_id = self.place_order_with_check(
                symbol=self.trading_symbol,
                price=price,
                qty=qty,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
                
            print(f"建仓订单执行结果: 成功={success}, 成交数量={filled_qty}, 订单ID={order_id}")
            
            if success:
                current_time = device_time(TimeZone.ET)
                
                # 找到最接近的网格价格
                closest_diff = float('inf')  # 初始化一个很大的差值
                closest_grid = None
                
                # 遍历所有网格价格找到最接近的
                for grid_price in self.grids.keys():
                    diff = abs(grid_price - price)
                    if diff < closest_diff:
                        closest_diff = diff
                        closest_grid = grid_price
                
                if closest_grid is not None:
                    grid = self.grids[closest_grid]
                    grid['positions'].append({
                        'price': price,
                        'quantity': filled_qty,
                        'time': current_time
                    })
                    grid['total_quantity'] += filled_qty
                    grid['last_trade_time'] = current_time
                    self.total_position += filled_qty
                    self.last_buy_time = current_time
                    print(f"持仓更新到网格 {closest_grid}")
                else:
                    print("未找到合适的网格价格")
                
        except Exception as e:
            print(f"执行首次建仓出错: {str(e)}")

    def execute_buy_order(self, grid_price, current_price):
        """执行买入订单"""
        try:
            qty = self.calculate_position_size(current_price)
            if qty <= 0:
                return
                
            print(f"执行买入: 网格={grid_price:.1f}, 价格={current_price:.1f}, 数量={qty}")
            success, filled_qty, order_id = self.place_order_with_check(
                symbol=self.trading_symbol,
                price=current_price,
                qty=qty,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if success:
                current_time = device_time(TimeZone.ET)
                
                # 更新网格信息
                grid = self.grids[grid_price]
                grid['positions'].append({
                    'price': current_price,
                    'quantity': filled_qty,
                    'time': current_time
                })
                grid['total_quantity'] += filled_qty
                grid['last_trade_time'] = current_time
                self.total_position += filled_qty
                self.last_buy_time = current_time
                print(f"买入成功: 持仓更新到网格 {grid_price:.1f}")
                        
        except Exception as e:
            print(f"执行买入订单出错: {str(e)}")

    def check_sell_grids(self, price):
        """检查是否有网格满足卖出条件"""
        try:
            sell_grids = {}
            for grid_price, grid in self.grids.items():
                if grid['total_quantity'] > 0:
                    for position in grid['positions']:
                        # 计算获利目标价并保留1位小数
                        profit_target = round(position['price'] * (1 + self.grid_percentage/100) * 10) / 10
                        if price >= profit_target:
                            sell_price = profit_target  # 直接使用计算好的获利目标价
                            print(f"网格 {grid_price:.1f} 达到获利目标价 {profit_target:.1f} (成本: {position['price']:.1f})")
                            if sell_price not in sell_grids:
                                sell_grids[sell_price] = {
                                    'total_quantity': position['quantity'],
                                    'grids': [(grid_price, grid)]
                                }
                    
            return sell_grids
                
        except Exception as e:
            print(f"检查卖出网格出错: {str(e)}")
            return {}

    def handle_data(self):
        """主策略逻辑"""
        try:
            # 使用美东时间 ET
            current_time = device_time(TimeZone.ET)
            
            # 检查是否是交易时间（美东时间9:30）
            if current_time.hour != 9 or current_time.minute != 30:
                print(f"当前时间 {current_time} 不是交易时间，等待9:30")
                return
            
            print(f"开始执行交易决策，当前时间: {current_time}")
            
            # 获取前一日K线收盘价作为交易决策依据
            try:
                prev_close = bar_close(
                    symbol=self.trading_symbol, 
                    bar_type=BarType.D1, 
                    select=1
                )
                if prev_close is None:
                    print("未获取到前一日收盘价")
                    return
                print(f"获取前一日收盘价: {prev_close:.2f}")
            except APIException as ex:
                print(f"获取K线数据失败: {ex.err_code}")
                return
            
            # 检查是否可以在当日交易
            if not self.can_trade_in_period(self.last_trade_time):
                print(f"当日已交易，最后交易时间: {self.last_trade_time}")
                return
                
            print(f"当日可以交易")
                
            # 首次交易或需要重置网格
            if self.base_price is None or self.need_reset_grids(prev_close):
                print(f"初始化/重置网格，基准价格: {self.base_price} -> {prev_close:.2f}")
                self.initialize_grids(prev_close)
                # 只在首次持仓为0时建仓
                if self.total_position == 0:
                    self.execute_first_position(prev_close)
                return
                
            print(f"当前总持仓: {self.total_position}")
                
            # 先检查是否有可以获利了结的持仓
            sell_grids = self.check_sell_grids(prev_close)
            if sell_grids:
                print(f"执行平仓操作")
                self.execute_sell_orders(sell_grids, prev_close)
                self.last_trade_time = current_time
                return
                
            print("检查建仓机会")
            
            # 检查建仓机会
            for grid_price in sorted(self.grids.keys()):
                grid = self.grids[grid_price]
                
                # 先检查网格持仓次数
                if len(grid['positions']) >= self.max_positions_per_grid:
                    print(f"网格 {grid_price:.1f} 已达到最大持仓次数")
                    continue
                    
                # 检查该网格今日是否已建仓
                if grid['last_trade_time'] and grid['last_trade_time'].date() == current_time.date():
                    print(f"网格 {grid_price:.1f} 今日已建仓")
                    continue
                
                # 计算价格区间并保留1位小数
                lower_bound = round(grid_price * (1 - self.grid_percentage/100) * 10) / 10
                upper_bound = round(grid_price * (1 + self.grid_percentage/100) * 10) / 10
                
                # 检查是否最适合的网格（价格最接近）
                is_best_grid = True
                for other_price in self.grids.keys():
                    if abs(other_price - prev_close) < abs(grid_price - prev_close):
                        is_best_grid = False
                        break
                        
                if lower_bound <= prev_close <= upper_bound and is_best_grid:
                    print(f"网格 {grid_price:.1f} 满足建仓条件: [{lower_bound:.1f}, {upper_bound:.1f}]")
                    self.execute_buy_order(grid_price, prev_close)
                    self.last_trade_time = current_time
                    break
                        
        except Exception as e:
            print(f"策略执行出错: {str(e)}")
            
    def execute_sell_orders(self, sell_grids, current_price):
        """执行卖出订单"""
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            for sell_price, sell_info in sell_grids.items():
                success, filled_qty, order_id = self.place_order_with_check(
                    symbol=self.trading_symbol,
                    price=sell_price,
                    qty=sell_info['total_quantity'],
                    side=OrderSide.SELL,
                    time_in_force=TimeInForce.DAY
                )
                
                if success:
                    self.last_sell_time = current_time
                    # 更新网格状态
                    for grid_price, grid in sell_info['grids']:
                        self.total_position -= grid['total_quantity']
                        grid['positions'] = []
                        grid['total_quantity'] = 0
                        grid['last_trade_time'] = current_time
                        
        except Exception as e:
            print(f"执行卖出订单出错: {str(e)}")