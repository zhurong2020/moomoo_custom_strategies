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
        self.grid_size = show_variable(50, GlobalType.INT)
        self.grid_height = show_variable(0.02, GlobalType.FLOAT)
        self.profit_ratio = show_variable(0.02, GlobalType.FLOAT)
        self.min_reset_interval = show_variable(0, GlobalType.INT)
        self.order_timeout = show_variable(60, GlobalType.INT)

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

    def _is_trading_time(self, time_obj):
        return (time_obj.hour > 9 or 
                (time_obj.hour == 9 and time_obj.minute >= 30)) and time_obj.hour < 16

    def _check_profit_grids(self, curr_price):
        """检查是否有网格达到盈利目标"""
        if not self.active_grids or not curr_price:
            print(f"\n诊断: active_grids为空或价格无效 - active_grids长度:{len(self.active_grids) if self.active_grids else 0}, 当前价格:{curr_price}")
            return []
        
        try:
            # 打印所有活跃网格状态
            print("\n==== 活跃网格状态 ====")
            for grid in self.active_grids:
                profit_ratio = (curr_price - grid['price']) / grid['price']
                print(f"网格价格:{grid['price']} 数量:{grid['quantity']} 当前盈亏比例:{profit_ratio*100:.2f}% 目标盈利比例:{self.profit_ratio*100:.2f}%")
            
            # 不处理已经有未完成卖单的网格
            existing_sell_grids = set()
            for order_info in self.processing_orders.values():
                if order_info['type'] == 'sell':
                    for grid in order_info['grids']:
                        existing_sell_grids.add(id(grid))
            
            if existing_sell_grids:
                print(f"诊断: 当前有 {len(existing_sell_grids)} 个网格正在处理卖单")
            
            profit_grids = []
            print(f"\n检查网格盈利 - 当前价格:{curr_price}")
            for grid in self.active_grids:
                if id(grid) in existing_sell_grids:
                    print(f"诊断: 跳过正在处理卖单的网格 价格:{grid['price']}")
                    continue
                    
                profit_ratio = (curr_price - grid['price']) / grid['price']
                print(f"网格价格:{grid['price']} 数量:{grid['quantity']} 盈利率:{profit_ratio*100:.2f}%")
                if profit_ratio >= self.profit_ratio:
                    print(f"网格达到盈利目标: 买入价:{grid['price']} 当前价:{curr_price} 收益率:{profit_ratio*100:.2f}%")
                    profit_grids.append(grid)
            
            if not profit_grids:
                print("诊断: 没有网格达到盈利目标")
            
            return profit_grids
        except Exception as e:
            print(f"Error in _check_profit_grids: {str(e)}")
            return []

    def _create_sell_orders(self, curr_price, profit_grids):
        """根据盈利网格创建卖单，成功后立即尝试开启新买单"""
        if not profit_grids:
            return False
            
        # 计算总卖出数量
        total_quantity = sum(grid['quantity'] for grid in profit_grids)
        limit_price = self._format_price(curr_price)
        
        order_id = place_limit(
            symbol=self.stock,
            price=limit_price,
            qty=total_quantity,
            side=OrderSide.SELL,
            time_in_force=TimeInForce.DAY
        )
        
        if order_id:
            self.processing_orders[order_id] = {
                'type': 'sell',
                'price': limit_price,
                'quantity': total_quantity,
                'create_time': device_time(TimeZone.ET),
                'grids': profit_grids
            }
            print(f"创建卖出订单 - 价格:{limit_price} 数量:{total_quantity}")
            
            # 立即尝试在当前价位创建新的买入订单
            buy_success = self._place_buy_order(curr_price)
            if buy_success:
                print(f"卖出后立即创建买入订单成功 - 价格:{curr_price}")
                
            return True
            
        return False

    def _create_rebuy_order(self, price):
        """在卖出价位重新创建买入订单"""
        buy_price = self._format_price(price)
        
        # 检查是否已有相同价格的未完成买单
        if any(info['type'] == 'buy' and abs(info['price'] - buy_price) < 0.01 
            for info in self.processing_orders.values()):
            return False
            
        # 检查是否超过最大持仓
        total_position = sum(g['quantity'] for g in self.active_grids)
        if total_position + self.grid_size > self.max_position:
            return False
            
        curr_price = current_price(self.stock, price_type=THType.FTH)
        # 如果当前价格比目标买入价格低，使用当前价格
        if curr_price and curr_price < buy_price:
            buy_price = self._format_price(curr_price)
            
        order_id = place_limit(
            symbol=self.stock,
            price=buy_price,
            qty=self.grid_size,
            side=OrderSide.BUY,
            time_in_force=TimeInForce.DAY
        )
        
        if order_id:
            print(f"创建平仓后重新买入订单 - 价格:{buy_price} 数量:{self.grid_size}")
            self.processing_orders[order_id] = {
                'type': 'buy',
                'price': buy_price,
                'quantity': self.grid_size,
                'create_time': device_time(TimeZone.ET),
                'is_rebuy': True
            }
            return True
            
        return False

    def _place_buy_order(self, latest_price):
        """创建买入订单"""
        try:
            # 检查已有买单
            if any(info['type'] == 'buy' for info in self.processing_orders.values()):
                return False
                
            # 检查最大持仓
            total_position = sum(g['quantity'] for g in self.active_grids)
            if total_position >= self.max_position:
                return False
            
            limit_price = self._format_price(latest_price)
            order_id = place_limit(
                symbol=self.stock,
                price=limit_price,
                qty=self.grid_size,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                self.processing_orders[order_id] = {
                    'type': 'buy',
                    'price': limit_price,
                    'quantity': self.grid_size,
                    'create_time': device_time(TimeZone.ET)
                }
                print(f"创建买入订单 - 价格:{limit_price} 数量:{self.grid_size}")
                return order_id
                
            return False
            
        except Exception as e:
            print(f"创建买入订单失败: {str(e)}")
            return False

    def _print_position_summary(self):
        """打印持仓汇总信息"""
        total_position = sum(g['quantity'] for g in self.active_grids)
        total_buy_pending = sum(order['quantity'] for order in self.processing_orders.values() 
                              if order['type'] == 'buy')
        total_sell_pending = sum(order['quantity'] for order in self.processing_orders.values() 
                               if order['type'] == 'sell')
        
        print("\n===== 持仓汇总 =====")
        if total_position > 0:
            total_cost = sum(g['price'] * g['quantity'] for g in self.active_grids)
            avg_cost = total_cost / total_position
            print(f"总持仓: {total_position}股")
            print(f"活跃网格数: {len(self.active_grids)}个")
            print(f"平均成本: {avg_cost:.2f}")
        else:
            print("当前无持仓")
            
        print(f"待买入: {total_buy_pending}股")
        print(f"待卖出: {total_sell_pending}股")
        print("==================\n")

    def _check_orders_timeout(self):
        """检查订单超时"""
        try:
            time_obj = device_time(TimeZone.ET)
            for order_id, order_info in list(self.processing_orders.items()):
                if (time_obj - order_info['create_time']).total_seconds() > self.order_timeout:
                    # 先检查订单状态
                    status = order_status(order_id)
                    # 只有当订单仍处于活跃状态时才尝试撤单
                    if status not in [OrderStatus.FILLED_ALL, OrderStatus.CANCELLED_ALL, OrderStatus.FAILED]:
                        try:
                            cancel_order_by_orderid(order_id)
                            print(f"订单超时已撤销 - ID:{order_id}")
                        except Exception as e:
                            print(f"撤销订单失败 - ID:{order_id}, Error: {str(e)}")
                    del self.processing_orders[order_id]
        except Exception as e:
            print(f"Error in _check_orders_timeout: {str(e)}")

    def _update_grid(self, curr_price):
        """更新网格价格范围"""
        self.base_price = curr_price
        self.upper_grid = self._format_price(curr_price * (1 + self.grid_height))
        self.lower_grid = self._format_price(curr_price * (1 - self.grid_height))
        self.last_reset_time = device_time(TimeZone.ET)
        
        print(f"网格更新 - 上轨:{self.upper_grid} 基准:{self.base_price} 下轨:{self.lower_grid}")
        return True

    def order_callback(self, order_info):
        """订单状态回调"""
        try:
            order_id = order_info.order_id
            status = order_info.status
            
            print(f"\n订单回调 - ID:{order_id} 状态:{status}")
            
            if status == OrderStatus.FILLED_ALL:
                filled_qty = order_info.filled_qty
                exec_price = order_info.filled_price
                
                order_data = self.processing_orders.get(order_id)
                if not order_data:
                    print(f"未找到订单数据: {order_id}")
                    return
                    
                print(f"订单完全成交 - 类型:{order_data['type']} 价格:{exec_price} 数量:{filled_qty}")
                
                if order_data['type'] == 'buy':
                    # 买单成交后添加网格
                    new_grid = {
                        'price': exec_price,
                        'quantity': filled_qty,
                        'time': device_time(TimeZone.ET)
                    }
                    self.active_grids.append(new_grid)
                    print(f"新增网格 - 价格:{exec_price} 数量:{filled_qty}")
                    
                elif order_data['type'] == 'sell':
                    # 更新网格持仓
                    for grid in order_data['grids']:
                        self.active_grids.remove(grid)
                    print(f"移除已平仓网格 - 数量:{len(order_data['grids'])}")
                    
                    # 立即尝试在当前价位重新买入
                    curr_price = current_price(self.stock, price_type=THType.FTH)
                    if curr_price:
                        new_order_id = self._place_buy_order(curr_price)
                        if new_order_id:
                            print(f"卖出后立即下单买入 - 价格:{curr_price}")
                        else:
                            print("卖出后重新买入失败")
                
                del self.processing_orders[order_id]
                print(f"当前活跃网格数量: {len(self.active_grids)}")
                
        except Exception as e:
            print(f"订单回调处理错误: {str(e)}")
            import traceback
            print(traceback.format_exc())

    def handle_data(self):
        """主循环处理"""
        try:
            time_obj = device_time(TimeZone.ET)
            
            # 交易时段检查
            if not self._is_trading_time(time_obj):
                return
                    
            curr_price = current_price(self.stock, price_type=THType.FTH)
            if not curr_price:
                return
                    
            # 1. 检查订单超时
            self._check_orders_timeout()
                    
            # 2. 更新网格价格范围
            if (self.base_price is None or 
                curr_price > self.upper_grid or 
                curr_price < self.lower_grid):
                self._update_grid(curr_price)
                    
            # 3. 检查是否有需要平仓的网格
            profit_grids = self._check_profit_grids(curr_price)
            if profit_grids:
                self._create_sell_orders(curr_price, profit_grids)
                return
                    
            # 4. 如果没有盈利平仓，检查是否需要创建新的买单
            if not any(info['type'] == 'buy' for info in self.processing_orders.values()):
                self._place_buy_order(curr_price)
                        
        except Exception as e:
            import traceback
            print(f"Error: {str(e)}\n{traceback.format_exc()}")