class Strategy(StrategyBase):
    def initialize(self):
        self.trigger_symbols()
        self.custom_indicator()
        self.global_variables()
        self.init_grid_data()
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
        self.max_position = show_variable(500, GlobalType.INT)
        self.grid_size = show_variable(20, GlobalType.INT)
        self.grid_height = show_variable(0.02, GlobalType.FLOAT)
        self.profit_ratio = show_variable(0.02, GlobalType.FLOAT)
        self.min_reset_interval = show_variable(6, GlobalType.INT)
        self.order_timeout = show_variable(300, GlobalType.INT)

    def init_grid_data(self):
        self.active_grids = []
        self.processing_orders = {}
        self.base_price = None
        self.upper_grid = None
        self.lower_grid = None
        self.last_reset_time = None
        self.last_process_time = None

    def _format_price(self, raw_price):
        if raw_price is None:
            return None
        return int(raw_price * 10) / 10

    def _update_grid(self, curr_price):
        from datetime import datetime
        
        time_obj = device_time(TimeZone.ET)
        if self.last_reset_time and \
           (time_obj - self.last_reset_time).total_seconds() < 3600 * self.min_reset_interval:
            return False
            
        self.base_price = curr_price
        self.upper_grid = self._format_price(curr_price * (1 + self.grid_height))
        self.lower_grid = self._format_price(curr_price * (1 - self.grid_height))
        self.last_reset_time = time_obj
        
        print(f"网格更新 - 上轨:{self.upper_grid} 基准:{self.base_price} 下轨:{self.lower_grid}")
        self._print_position_summary()  # 修复：更新网格后实时打印持仓信息
        return True

    def _check_order_status(self, order_id):
        status = order_status(order_id)
        
        if status == OrderStatus.FILLED_ALL:
            return True
        elif status in [OrderStatus.CANCELLED_ALL, OrderStatus.FAILED]:
            if order_id in self.processing_orders:
                del self.processing_orders[order_id]
            return False
            
        from datetime import datetime
        time_obj = device_time(TimeZone.ET)
        
        if order_id in self.processing_orders:
            order_info = self.processing_orders[order_id]
            if (time_obj - order_info['create_time']).total_seconds() > self.order_timeout:
                cancel_order_by_orderid(order_id)
                del self.processing_orders[order_id]
                print(f"订单超时已撤销 - ID:{order_id}")
                return False
                
        return None

    def _check_grid_profit(self, curr_price):
        if not self.active_grids:
            return False
            
        profit_grids = []
        total_quantity = 0
        
        for grid in sorted(self.active_grids, key=lambda x: x['price']):
            profit_ratio = curr_price / grid['price'] - 1
            if profit_ratio >= self.profit_ratio:
                print(f"网格达到盈利目标: 买入价:{grid['price']} 当前价:{curr_price} 收益率:{profit_ratio*100:.1f}%")
                profit_grids.append(grid)
                total_quantity += grid['quantity']

        if profit_grids and not any(info['type'] == 'sell' for info in self.processing_orders.values()):
            limit_price = self._format_price(curr_price)
            order_id = place_limit(
                symbol=self.stock,
                price=limit_price,
                qty=total_quantity,
                side=OrderSide.SELL,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                print(f"创建卖出订单 - 价格:{limit_price} 数量:{total_quantity}")
                self.processing_orders[order_id] = {
                    'type': 'sell',
                    'price': limit_price,
                    'quantity': total_quantity,
                    'create_time': device_time(TimeZone.ET),
                    'grids': profit_grids
                }
                return True
        return False

    def _place_buy_order(self, curr_price):
        total_position = sum(g['quantity'] for g in self.active_grids)
        total_pending = sum(order['quantity'] for order in self.processing_orders.values() if order['type'] == 'buy')
        
        if total_position + total_pending >= self.max_position:
            return False
            
        if any(info['type'] == 'buy' for info in self.processing_orders.values()):
            return False

        limit_price = self._format_price(curr_price)
        order_id = place_limit(
            symbol=self.stock,
            price=limit_price,
            qty=self.grid_size,
            side=OrderSide.BUY,
            time_in_force=TimeInForce.DAY
        )
        
        if order_id:
            print(f"创建买入订单 - 价格:{limit_price} 数量:{self.grid_size}")
            self.processing_orders[order_id] = {
                'type': 'buy',
                'price': limit_price,
                'quantity': self.grid_size,
                'create_time': device_time(TimeZone.ET)
            }
            return True
        return False

    def _process_executions(self):
        executed = False
        for order_id in list(self.processing_orders.keys()):
            status = self._check_order_status(order_id)
            
            if status is True:
                order_info = self.processing_orders[order_id]
                
                if order_info['type'] == 'buy':
                    self.active_grids.append({
                        'price': order_info['price'],
                        'quantity': order_info['quantity'],
                        'time': device_time(TimeZone.ET),
                        'order_id': order_id
                    })
                    print(f"买入订单成交 - 价格:{order_info['price']} 数量:{order_info['quantity']}")
                    
                elif order_info['type'] == 'sell':
                    for grid in order_info['grids']:
                        if grid in self.active_grids:
                            self.active_grids.remove(grid)
                    print(f"卖出订单成交 - 价格:{order_info['price']} 数量:{order_info['quantity']}")
                    # 修复：卖出后尝试立即开仓
                    self._update_grid(order_info['price'])
                    self._place_buy_order(order_info['price'])
                
                del self.processing_orders[order_id]
                executed = True
                
        if executed:
            self._print_position_summary()
            
        return executed

    def _print_position_summary(self):
        total_position = sum(g['quantity'] for g in self.active_grids)
        total_buy_pending = sum(order['quantity'] for order in self.processing_orders.values() if order['type'] == 'buy')
        total_sell_pending = sum(order['quantity'] for order in self.processing_orders.values() if order['type'] == 'sell')
        
        if total_position > 0:
            total_cost = sum(g['price'] * g['quantity'] for g in self.active_grids)
            avg_cost = total_cost / total_position
            print(f"\n===== 持仓汇总 =====")
            print(f"总持仓: {total_position}股")
            print(f"活跃网格数: {len(self.active_grids)}个")
            print(f"平均成本: {avg_cost:.2f}")
            print(f"待买入: {total_buy_pending}股")
            print(f"待卖出: {total_sell_pending}股")
            print("==================\n")
        else:
            print("\n===== 持仓汇总 =====")
            print("当前无持仓")
            print(f"待买入: {total_buy_pending}股")
            print(f"待卖出: {total_sell_pending}股")
            print("==================\n")

    def handle_data(self):
        try:
            time_obj = device_time(TimeZone.ET)
            
            from datetime import datetime, timedelta
            current_minute = time_obj.replace(second=0, microsecond=0)
            if self.last_process_time != current_minute:
                self._process_executions()
                self.last_process_time = current_minute
            
            if time_obj.hour < 9 or \
               (time_obj.hour == 9 and time_obj.minute < 30) or \
               time_obj.hour >= 16:
                return
                
            curr_price = current_price(self.stock, price_type=THType.FTH)
            if not curr_price:
                return
            
            if self._check_grid_profit(curr_price):
                self._process_executions()
                return
            
            if self._place_buy_order(curr_price):
                self._process_executions()
                return
            
            if self.base_price is None or \
               curr_price > self.upper_grid or \
               curr_price < self.lower_grid:
                self._update_grid(curr_price)
                return
                
        except Exception as e:
            print(f"Error: {e}")
