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
        self.pending_buy_after_sell = False

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
        return True

    def _check_execution_details(self, order_id):
        execution_ids = order_executionid(order_id)
        if execution_ids:
            filled_qty = order_filled_qty(order_id)
            exec_price = execution_price(execution_ids[-1])
            return filled_qty, exec_price
        return None, None

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
                self.pending_buy_after_sell = True
                return True
        return False

    def _place_buy_order(self, curr_price):
        if self.pending_buy_after_sell or \
           (not any(info['type'] == 'buy' for info in self.processing_orders.values())):
            total_position = sum(g['quantity'] for g in self.active_grids)
            total_pending = sum(order['quantity'] for order in self.processing_orders.values() if order['type'] == 'buy')
            
            if total_position + total_pending >= self.max_position:
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
        sell_orders = []
        curr_price = None
        
        # 先处理卖单
        for order_id in list(self.processing_orders.keys()):
            order_info = self.processing_orders.get(order_id)
            if order_info and order_info['type'] == 'sell':
                status = self._check_order_status(order_id)
                if status is True:
                    filled_qty, exec_price = self._check_execution_details(order_id)
                    if filled_qty and exec_price:
                        curr_price = exec_price
                        for grid in order_info['grids']:
                            if grid in self.active_grids:
                                self.active_grids.remove(grid)
                        print(f"卖出订单成交 - 价格:{exec_price} 数量:{filled_qty}")
                        # 立即更新网格并尝试开仓
                        if self._update_grid(exec_price):
                            self._place_buy_order(exec_price)
                            self.pending_buy_after_sell = False
                        sell_orders.append(order_id)
                        executed = True
        
        # 删除已处理的卖单
        for order_id in sell_orders:
            if order_id in self.processing_orders:
                del self.processing_orders[order_id]
        
        # 处理买单
        for order_id in list(self.processing_orders.keys()):
            order_info = self.processing_orders.get(order_id)
            if order_info and order_info['type'] == 'buy':
                status = self._check_order_status(order_id)
                if status is True:
                    filled_qty, exec_price = self._check_execution_details(order_id)
                    if filled_qty and exec_price:
                        curr_price = exec_price
                        self.active_grids.append({
                            'price': exec_price,
                            'quantity': filled_qty,
                            'time': device_time(TimeZone.ET),
                            'order_id': order_id
                        })
                        print(f"买入订单成交 - 价格:{exec_price} 数量:{filled_qty}")
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
            
            # 处理任何未完成的订单
            self._process_executions()
            
            # 交易时段检查
            if time_obj.hour < 9 or \
               (time_obj.hour == 9 and time_obj.minute < 30) or \
               time_obj.hour >= 16:
                return
                
            curr_price = current_price(self.stock, price_type=THType.FTH)
            if not curr_price:
                return
            
            # 检查新的盈利机会
            if self._check_grid_profit(curr_price):
                return
            
            # 检查是否需要网格重置和开仓
            if self.pending_buy_after_sell or \
               (self.base_price is None or \
               curr_price > self.upper_grid or \
               curr_price < self.lower_grid):
                if self._update_grid(curr_price):
                    self._place_buy_order(curr_price)
                return
            
            # 常规开仓检查
            if self._place_buy_order(curr_price):
                return
                
        except Exception as e:
            print(f"Error: {e}")