class Strategy(StrategyBase):
    def initialize(self):
        self.trigger_symbols()
        self.custom_indicator()
        self.global_variables()
        self.positions = []
        self.total_position = 0
        self.is_initialized = False
        self.executed_orders = set()  # 记录已执行订单ID
        self.executed_trades = set()  # 记录已确认成交ID
        print("策略初始化完成")

    def trigger_symbols(self):
        self.stock = declare_trig_symbol()
        
    def custom_indicator(self):
        self.register_indicator(
            indicator_name='MA',
            script='MA5:MA(CLOSE,5),COLORFF8D1E;',
            param_list=[]
        )
        
    def global_variables(self):
        # 资金和仓位参数
        self.initial_capital = show_variable(10000, GlobalType.FLOAT)  
        self.max_total_position = show_variable(500, GlobalType.INT)   
        self.grid_trade_size = show_variable(50, GlobalType.INT)       
        
        # 网格参数
        self.grid_height = show_variable(0.03, GlobalType.FLOAT)      # 3%网格间距
        self.profit_ratio = show_variable(0.02, GlobalType.FLOAT)     # 2%盈利目标
        
        # 交易状态记录
        self.last_trade_time = None
        self.base_price = None

    def _format_price(self, price):
        if price is None:
            return None
        return int(price * 10) / 10

    def _check_trading_time(self):
       """检查是否为交易时间"""
       current_time = device_time(TimeZone.ET)
       return (current_time.hour == 9 and current_time.minute >= 30) or \
              (current_time.hour > 9 and current_time.hour < 16)

    def _check_daily_trade_limit(self, current_price):
        """检查日内交易限制"""
        current_time = device_time(TimeZone.ET)
        if self.last_trade_time and \
            self.last_trade_time.date() == current_time.date():
            return False
        return True
            
    def _initialize_grid(self, base_price):
        if not base_price:
            return False
            
        self.base_price = base_price    
        self.base_grid = self._format_price(base_price)
        self.upper_grid = self._format_price(base_price * (1 + self.grid_height))
        self.lower_grid = self._format_price(base_price * (1 - self.grid_height))
        
        self.is_initialized = True
        print(f"网格设置 - 上:{self.upper_grid} 基准:{self.base_grid} 下:{self.lower_grid}")
        return True

    def _find_grid_type(self, price):
        if not self.is_initialized:
            return None
            
        if price > self.upper_grid:
            return 'upper'
        elif price > self.base_grid:
            return 'base_to_upper'
        elif price > self.lower_grid:
            return 'lower_to_base'
        else:
            return 'lower'

    def _load_positions(self):
        """加载持仓数据"""
        try:
            holding_qty = position_holding_qty(symbol=self.stock)
            if holding_qty > 0:
                avg_cost = position_cost(self.stock, cost_price_model=CostPriceModel.AVG)
                current_time = device_time(TimeZone.ET)
                
                # 更新持仓记录
                self.positions = [{
                    'cost': avg_cost,
                    'quantity': holding_qty,
                    'time': current_time,
                    'date': current_time.date()
                }]
                self.total_position = holding_qty
                print(f"当前持仓: {holding_qty}股 @ {avg_cost}")
                
                # 检查并更新基准价格
                if not self.base_price:
                    self.base_price = avg_cost
                    
            else:
                self.positions = []
                self.total_position = 0
                print("当前无持仓")
                
        except Exception as e:
            print(f"加载持仓失败: {str(e)}")

    def _update_position(self, order_id):
        """更新持仓记录"""
        try:
            if order_status(order_id) != OrderStatus.FILLED_ALL:
                return False
                
            # 等待成交数据更新
            time.sleep(0.5)  # 增加小延时确保成交更新
            
            # 重新加载最新持仓
            self._load_positions()
            return True
                
        except Exception as e:
            print(f"更新持仓失败: {str(e)}")
            return False
            
    def _update_grid(self, current_price):
        """动态调整网格"""
        if not self.base_price:
            return self._initialize_grid(current_price)
            
        price_change = abs(current_price - self.base_price) / self.base_price
        if price_change > self.grid_height * 2:  # 两倍网格高度时重置
            print(f"价格变化{price_change*100:.1f}%, 重置网格")
            return self._initialize_grid(current_price)
        
        return True

    def _execute_grid_trades(self, current_price):
        try:
            # 检查盈利平仓机会
            if self.positions:
                profit_ratio = current_price/self.positions[0]['cost'] - 1
                if profit_ratio >= self.profit_ratio:
                    print(f"发现盈利: {self.total_position}股 @ {self.positions[0]['cost']}, 收益率: {profit_ratio*100:.1f}%")
                    return self._place_order(current_price, self.total_position, False)

            # 检查网格开仓机会
            if self.total_position < self.max_total_position and \
            self._check_daily_trade_limit(current_price):
                
                # 价格高于上轨，重置网格后买入
                if current_price >= self.upper_grid:
                    if self._update_grid(current_price):
                        print(f"上轨突破买入: 价格{current_price} >= {self.upper_grid}")
                        return self._place_order(current_price, self.grid_trade_size, True)
                        
                # 价格低于下轨，重置网格后买入
                elif current_price <= self.lower_grid:
                    if self._update_grid(current_price):
                        print(f"下轨突破买入: 价格{current_price} <= {self.lower_grid}")
                        return self._place_order(current_price, self.grid_trade_size, True)
                        
                # 价格在网格区间内，基于基准价格判断
                else:
                    # 价格高于基准价，买入
                    if current_price >= self.base_grid:
                        print(f"价格({current_price})高于基准价({self.base_grid})，买入")
                        return self._place_order(current_price, self.grid_trade_size, True)
                    # 价格低于基准价，买入
                    else:
                        print(f"价格({current_price})低于基准价({self.base_grid})，买入")
                        return self._place_order(current_price, self.grid_trade_size, True)
                
            return False
                
        except Exception as e:
            print(f"执行网格交易失败: {str(e)}")
            return False

    def handle_data(self):
        """主策略逻辑"""
        try:
            current_time = device_time(TimeZone.ET)
            if current_time.hour < 9 or \
               (current_time.hour == 9 and current_time.minute < 30) or \
               current_time.hour >= 16:
                return
                
            # 清理前一天的记录
            if self.last_trade_time and \
               self.last_trade_time.date() != current_time.date():
                self.executed_orders.clear()
                self.executed_trades.clear()
            
            self._load_positions()
            
            latest_price = current_price(self.stock, price_type=THType.FTH)
            if not latest_price:
                return
                
            print(f"当前价格: {latest_price}")
            
            if not self.is_initialized:
                if self._initialize_grid(latest_price):
                    result = self._place_order(latest_price, self.grid_trade_size, True)
                    if not result:
                        self.is_initialized = False
                    return
                
            self._execute_grid_trades(latest_price)
            self._print_position_summary(latest_price)
            
        except Exception as e:
            print(f"策略运行错误: {str(e)}")

    def _place_order(self, price, quantity, is_buy=True):
        """下单并确认成交"""
        try:
            limit_price = self._format_price(price)
            
            order_id = place_limit(
                symbol=self.stock,
                price=limit_price,
                qty=quantity,
                side=OrderSide.BUY if is_buy else OrderSide.SELL,
                time_in_force=TimeInForce.DAY
            )
            
            if not order_id or order_id in self.executed_orders:
                return False
                
            # 等待订单成交
            for _ in range(20):
                status = order_status(order_id)
                if status == OrderStatus.FILLED_ALL:
                    time.sleep(1)  # 等待成交数据更新
                    if self._update_position(order_id):
                        self.last_trade_time = device_time(TimeZone.ET)
                        self.executed_orders.add(order_id)
                        return True
                elif status in [OrderStatus.CANCELLED_ALL, OrderStatus.FAILED]:
                    return False
                time.sleep(0.5)
                
            return False
                
        except Exception as e:
            print(f"下单失败: {str(e)}")
            return False

    def _print_position_summary(self, current_price):
        """打印持仓汇总"""
        # 先更新一次持仓确保数据最新
        self._load_positions()
        
        if not self.positions:
            return
            
        total_cost = sum(pos['quantity'] * pos['cost'] for pos in self.positions)
        total_value = self.total_position * current_price
        
        if total_cost > 0:
            total_profit_ratio = (total_value/total_cost - 1) * 100
            print(f"持仓汇总: {self.total_position}股")
            print(f"成本: {total_cost:.2f}")
            print(f"市值: {total_value:.2f}")
            print(f"盈亏: {(total_value - total_cost):.2f} ({total_profit_ratio:.1f}%)")