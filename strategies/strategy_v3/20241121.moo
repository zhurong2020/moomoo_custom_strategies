class Strategy(StrategyBase):
    """网格交易策略V3 - 修订策略意外中断问题"""

    def initialize(self):
        """初始化策略"""
        import threading
        try:
            self._position_lock = threading.RLock()
            self._order_lock = threading.RLock()

            # 初始化基本数据结构
            self.positions = {}          # 记录每个网格的持仓
            self.grid_prices = []        # 存储网格价格
            self.position_records = {}   # 记录每个网格的交易详情
            self.total_position = 0      # 总持仓跟踪
            self.is_initialized = False
            self.last_trade_time = None  # 上次交易时间记录
            self.pending_orders = set()  # 跟踪待处理订单
            self.order_records = {}      # 记录本策略的所有订单信息
            self.start_time = device_time(TimeZone.DEVICE_TIME_ZONE)  # 记录策略启动时间
            
            # 记录当前周期的交易状态
            self.current_period_trades = {
                'period': '',            # 当前周期标识
                'buy_count': 0,          # 买入次数
                'sell_count': 0,         # 卖出次数
                'grids': set()           # 已操作的网格
            }
            
            # 检查是否有未处理的持仓
            actual_position = position_holding_qty(self.stock)
            if actual_position > 0:
                print(f"检测到已有持仓{actual_position}股，尝试恢复持仓状态")
                if self._recover_positions():
                    print("持仓状态恢复成功，继续执行策略")
                else:
                    print("持仓状态恢复失败，停止策略")
                    return
            
            # 执行标准初始化流程
            self.trigger_symbols()
            self.custom_indicator()
            self.global_variables()
            print("策略初始化完成")
            
        except Exception as e:
            print(f"策略初始化发生错误: {str(e)}")

    def trigger_symbols(self):
        """定义交易标的"""
        try:
            self.stock = declare_trig_symbol()
            print("交易标的设置完成")
        except Exception as e:
            print(f"设置交易标的时发生错误: {str(e)}")

    def custom_indicator(self):
        """设置技术指标"""
        try:
            self.register_indicator(
                indicator_name='MA',
                script='MA5:MA(CLOSE,5),COLORFF8D1E;',
                param_list=[]
            )
            print("技术指标设置完成")
        except Exception as e:
            print(f"设置技术指标时发生错误: {str(e)}")

    def global_variables(self):
        """定义全局变量"""
        try:
            # 用户可配置参数
            self.initial_capital = show_variable(10000, GlobalType.FLOAT, "初始资金")
            self.max_total_position = show_variable(500, GlobalType.INT, "最大总持仓")
            self.min_order_quantity = show_variable(20, GlobalType.INT, "单次交易数量")
            self.position_limit = show_variable(80, GlobalType.INT, "单个网格持仓上限")
            self.time_interval = show_variable(60, GlobalType.INT, "交易间隔(分钟)")
            
            # 统一网格间距和盈利标准
            self.grid_percentage = show_variable(0.03, GlobalType.FLOAT, "网格间距/盈利标准")
            self.grid_num = show_variable(10, GlobalType.INT, "网格数量")
            
            # 其他配置参数
            self.max_capital_usage = show_variable(0.9, GlobalType.FLOAT, "最大资金使用率")
            self.max_order_timeout = show_variable(300, GlobalType.INT, "订单超时时间(秒)")
            print("全局变量设置完成")
            
        except Exception as e:
            print(f"设置全局变量时发生错误: {str(e)}")

    def check_strategy_status(self):
        """检查策略运行状态"""
        try:
            # 检查策略运行时长
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            running_hours = (current_time - self.start_time).total_seconds() / 3600
            
            # 检查持仓一致性
            actual_position = position_holding_qty(self.stock)
            if actual_position != self.total_position:
                self.send_alert(f"警告:策略运行{running_hours:.1f}小时后发现持仓不一致")
                return False
            
            # 检查网络连接
            if not current_price(self.stock):
                self.send_alert(f"警告:无法获取行情数据,请检查网络连接")
                return False
                
            return True
            
        except Exception as e:
            print(f"检查策略状态时发生错误: {str(e)}")
            return False

    def send_alert(self, message):
        """发送策略告警"""
        try:
            print(f"策略告警: {message}")
            # 这里可以根据实际情况添加其他通知方式
        except Exception as e:
            print(f"发送告警时发生错误: {str(e)}")

    def _recover_positions(self):
        """恢复已有持仓状态"""
        try:
            actual_position = position_holding_qty(self.stock)
            if actual_position == 0:
                return True

            # 获取当前价格和持仓成本
            latest_price = current_price(self.stock)
            avg_cost = position_cost(self.stock, cost_price_model=CostPriceModel.AVG)
            
            if not latest_price or not avg_cost:
                print("无法获取价格或成本信息，恢复失败")
                return False

            print(f"当前持仓: {actual_position}股")
            print(f"平均成本: {avg_cost:.2f}")
            print(f"当前价格: {latest_price:.2f}")

            # 基于当前价格初始化网格
            grid_spacing = latest_price * self.grid_percentage
            base_grid = int(latest_price * 10) / 10
            half_grids = self.grid_num // 2
            
            # 生成网格价格
            self.grid_prices = [base_grid]
            for i in range(half_grids):
                up_price = int((base_grid + (i + 1) * grid_spacing) * 10) / 10
                down_price = int((base_grid - (i + 1) * grid_spacing) * 10) / 10
                self.grid_prices.extend([up_price, down_price])
            self.grid_prices.sort()

            # 找到最接近成本价的网格
            cost_grid = self._find_nearest_grid(avg_cost)
            if not cost_grid:
                print("无法找到合适的网格来分配持仓")
                return False

            # 将持仓分配到对应网格
            self.positions = {cost_grid: actual_position}
            self.position_records = {
                cost_grid: {
                    'buy_price': avg_cost,
                    'quantity': actual_position,
                    'update_time': time.time()
                }
            }
            self.total_position = actual_position

            print(f"持仓已恢复到网格 {cost_grid:.1f}")
            self._print_grid_status(show_all=True)
            
            # 验证恢复后的持仓状态
            return self._verify_positions()

        except Exception as e:
            print(f"恢复持仓状态时发生错误: {str(e)}")
            return False

    def _initialize_grids(self, base_price):
        """初始化或重置网格"""
        try:
            print(f"\n初始化网格 - 基准价格: {base_price}")
            
            # 获取实际持仓用于验证
            actual_position = position_holding_qty(self.stock)
            print(f"当前实际持仓: {actual_position}股")
            
            with self._position_lock:
                if not self.is_initialized and actual_position > 0:
                    # 如果是首次初始化且有持仓，走恢复流程
                    print("检测到未初始化的持仓，进行恢复")
                    if not self._recover_positions():
                        print("持仓恢复失败，中止网格初始化")
                        return
                    return
                
                if self.total_position != actual_position:
                    # 如果持仓不一致，先修正持仓
                    print("检测到持仓不一致，先进行修正")
                    if not self._verify_and_fix_positions():
                        print("持仓修正失败，中止网格初始化")
                        return
                    
                # 保存持仓信息
                if actual_position > 0:
                    old_positions = {k: v for k, v in self.positions.items() if v > 0}
                    old_records = {k: v for k, v in self.position_records.items() 
                                if v.get('quantity', 0) > 0}
                else:
                    old_positions = {}
                    old_records = {}
                    
                # 生成新网格
                grid_spacing = int(base_price * self.grid_percentage * 10) / 10
                half_grids = self.grid_num // 2
                new_grid_prices = []
                base_grid = int(base_price * 10) / 10
                new_grid_prices.append(base_grid)
                
                for i in range(half_grids):
                    new_grid_prices.append(int((base_grid + (i + 1) * grid_spacing) * 10) / 10)
                    new_grid_prices.append(int((base_grid - (i + 1) * grid_spacing) * 10) / 10)
                
                new_grid_prices.sort()
                
                # 初始化新网格，保持原有持仓信息
                new_positions = {price: 0 for price in new_grid_prices}
                new_records = {price: {'buy_price': price, 'quantity': 0} 
                            for price in new_grid_prices}
                
                # 添加原有持仓到新网格
                if old_positions:
                    # 找到最近的网格迁移持仓
                    nearest_grid = self._find_nearest_grid(base_price)
                    if nearest_grid:
                        total_pos = sum(old_positions.values())
                        total_value = 0
                        for price, qty in old_positions.items():
                            record = old_records.get(price, {})
                            total_value += qty * record.get('buy_price', price)
                        
                        avg_cost = int(total_value / total_pos * 10) / 10
                        new_positions[nearest_grid] = total_pos
                        new_records[nearest_grid] = {
                            'buy_price': avg_cost,
                            'quantity': total_pos,
                            'update_time': time.time()
                        }
                        print(f"迁移持仓 - 总数量:{total_pos}股 到网格{nearest_grid}, 平均成本:{avg_cost}")
                
                # 更新类属性
                self.grid_prices = new_grid_prices
                self.positions = new_positions
                self.position_records = new_records
                self.total_position = sum(new_positions.values())
                
                # 验证更新后的持仓
                if not self._verify_positions():
                    print("警告：网格初始化后持仓验证失败")
                    if not self._verify_and_fix_positions():
                        print("持仓修正失败")
                        return
                
                # 如果没有持仓，在基准价格开仓
                if self.total_position == 0:
                    self._place_buy_order(base_grid, base_price)
                
                self._print_grid_status(show_all=True, show_time=False)

        except Exception as e:
            print(f"初始化网格时发生错误: {str(e)}")
            raise e

    def _get_position_cost(self):
        """获取当前持仓的成本价"""
        try:
            # 优先使用API获取成本价
            avg_cost = position_cost(self.stock, cost_price_model=CostPriceModel.AVG)
            if avg_cost:
                return avg_cost
            
            # 如果API获取失败，计算内存中记录的加权平均成本
            total_value = 0
            total_quantity = 0
            for grid_price, qty in self.positions.items():
                if qty <= 0:
                    continue
                record = self.position_records.get(grid_price, {})
                buy_price = record.get('buy_price', grid_price)
                total_value += qty * buy_price
                total_quantity += qty
            
            if total_quantity > 0:
                return int(total_value / total_quantity * 10) / 10
            
            # 如果无法计算成本，返回当前价格
            return current_price(self.stock)
            
        except Exception as e:
            print(f"获取持仓成本价时发生错误: {str(e)}")
            return None

    def _verify_and_fix_positions(self):
        """验证并修正持仓数据"""
        try:
            actual_position = position_holding_qty(self.stock)
            print(f"当前实际持仓: {actual_position}股")
            
            # 如果无持仓，清空记录
            if actual_position == 0:
                self.positions = {}
                self.position_records = {}
                self.total_position = 0
                print("实际持仓为0，已清空所有持仓记录")
                return True
            
            # 如果持仓不一致，需要修正
            if self.total_position != actual_position:
                print(f"持仓不一致 - 系统记录:{self.total_position}, 实际持仓:{actual_position}")
                
                # 获取API的持仓成本
                avg_cost = position_cost(self.stock, cost_price_model=CostPriceModel.AVG)
                if not avg_cost:
                    print("无法获取持仓成本价，尝试计算现有记录的加权平均成本")
                    # 计算现有持仓的加权平均成本作为备选
                    total_value = 0
                    total_quantity = 0
                    for grid_price, qty in self.positions.items():
                        record = self.position_records.get(grid_price, {})
                        buy_price = record.get('buy_price', grid_price)
                        total_value += qty * buy_price
                        total_quantity += qty
                    
                    if total_quantity > 0:
                        avg_cost = int(total_value / total_quantity * 10) / 10
                    else:
                        # 如果无法计算成本，使用当前价格
                        avg_cost = current_price(self.stock)
                
                # 找到最适合的网格
                nearest_grid = self._find_nearest_grid(avg_cost)
                if nearest_grid:
                    # 将所有持仓合并到该网格
                    self.positions = {nearest_grid: actual_position}
                    self.position_records = {nearest_grid: {
                        'buy_price': avg_cost,
                        'quantity': actual_position,
                        'update_time': time.time()
                    }}
                    self.total_position = actual_position
                    print(f"已将所有持仓({actual_position}股)合并到网格{nearest_grid}，成本价:{avg_cost:.1f}")
                else:
                    print("无法找到合适的网格，需要重新初始化网格")
                    return False
            
            return self._verify_positions()
            
        except Exception as e:
            print(f"验证和修正持仓时发生错误: {str(e)}")
            return False

    def _verify_positions(self):
        """验证持仓数据一致性"""
        try:
            total_from_positions = sum(self.positions.values())
            total_from_records = sum(r.get('quantity', 0) 
                                for r in self.position_records.values())
            
            # 验证每个网格的数据一致性
            for grid_price in self.grid_prices:
                pos = self.positions.get(grid_price, 0)
                rec = self.position_records.get(grid_price, {}).get('quantity', 0)
                
                if pos != rec:
                    print(f"警告: 网格 {grid_price:.1f} 持仓不一致 - position:{pos}, record:{rec}")
                    return False
                    
            if total_from_positions != total_from_records:
                print(f"警告: 总持仓不一致 - positions:{total_from_positions}, records:{total_from_records}")
                return False
                
            if self.total_position != total_from_positions:
                print(f"警告: total_position({self.total_position}) != sum of positions({total_from_positions})")
                return False
                
            # 验证与实际持仓的一致性
            actual_position = position_holding_qty(self.stock)
            if actual_position != self.total_position:
                print(f"警告: 实际持仓不一致 - actual:{actual_position}, total:{self.total_position}")
                return False
                
            return True
            
        except Exception as e:
            print(f"验证持仓失败: {str(e)}")
            return False

    def _should_reset_grid(self, latest_price):
        """判断是否需要重置网格"""
        try:
            if not self.grid_prices:
                return True
                    
            closest_grid = self._find_nearest_grid(latest_price)
            if closest_grid:
                deviation = abs(latest_price - closest_grid) / closest_grid
                if deviation > self.grid_percentage:
                    print(f"价格偏离网格过大: {deviation:.2%}, 需要重置网格")
                    return True
            return False
                
        except Exception as e:
            print(f"检查网格重置时发生错误: {str(e)}")
            return False

    def _find_nearest_grid(self, target_price):
        """找到最接近目标价格的网格"""
        try:
            if not self.grid_prices:
                return None
                
            target_price = int(target_price * 10) / 10  # 保持1位小数
            
            nearest_grid = self.grid_prices[0]
            min_distance = abs(target_price - nearest_grid)
            
            for grid in self.grid_prices[1:]:
                distance = abs(target_price - grid)
                if distance < min_distance:
                    min_distance = distance
                    nearest_grid = grid
                    
            return nearest_grid
            
        except Exception as e:
            print(f"查找最近网格失败: {str(e)}")
            return None

    def _is_new_period(self, current_time):
        """判断是否是新的交易周期"""
        current_period = current_time.strftime('%Y%m%d_%H%M')
        if current_period != self.current_period_trades['period']:
            # 新周期，重置交易状态
            self.current_period_trades = {
                'period': current_period,
                'buy_count': 0,
                'sell_count': 0,
                'grids': set()
            }
            return True
        return False

    def _can_trade_in_period(self, grid_price, is_buy=True):
        """检查是否可以在当前周期交易"""
        if is_buy and self.current_period_trades['buy_count'] > 0:
            print(f"当前周期已执行过买入操作")
            return False
        if not is_buy and self.current_period_trades['sell_count'] > 0:
            print(f"当前周期已执行过卖出操作")
            return False
        if grid_price in self.current_period_trades['grids']:
            print(f"当前周期已在网格{grid_price:.1f}执行过交易")
            return False
        return True

    def _update_period_trade_status(self, grid_price, is_buy=True):
        """更新周期交易状态"""
        if is_buy:
            self.current_period_trades['buy_count'] += 1
        else:
            self.current_period_trades['sell_count'] += 1
        if grid_price is not None:
            self.current_period_trades['grids'].add(grid_price)

    def handle_data(self):
        """主要策略逻辑"""
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            
            # 定期检查策略状态
            if not self.check_strategy_status():
                print("策略状态异常，跳过本次交易")
                return
            
            # 获取当前价格
            latest_price = current_price(self.stock)
            if not latest_price:
                return
                    
            print(f"\n当前时间: {current_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"当前价格: {latest_price:.1f}")
            self._print_grid_status(show_all=False, show_time=True)
                
            # 初始化或重置网格
            if not self.is_initialized or self._should_reset_grid(latest_price):
                self._initialize_grids(latest_price)
                self.is_initialized = True
                return
            
            # 检查是否新周期
            if not self._is_new_period(current_time):
                print(f"当前周期已执行交易, 等待下一周期")
                return
                
            # 先检查是否有盈利机会
            if self._check_and_execute_sell(latest_price):
                self.last_trade_time = current_time
                return
                
            # 找到当前价格所属网格
            current_grid = self._find_nearest_grid(latest_price)
            if not current_grid:
                return
                    
            print(f"当前所属网格: {current_grid:.1f}")
            
            # 检查是否可以买入
            if not self._can_trade_in_period(current_grid, is_buy=True):
                return
                
            # 执行买入
            if self._place_buy_order(current_grid, latest_price):
                self._update_period_trade_status(current_grid, is_buy=True)
                self.last_trade_time = current_time
                
        except Exception as e:
            print(f"策略运行时发生错误: {str(e)}")
            import traceback
            print(traceback.format_exc())

    def _check_and_execute_sell(self, current_price):
        """检查并执行卖出操作"""
        try:
            if not self._can_trade_in_period(None, is_buy=False):
                return False
                
            sell_price = bid(self.stock, level=1)
            if not sell_price:
                sell_price = current_price
                
            profitable_grids = []
            total_sell_quantity = 0
            
            with self._position_lock:
                for grid_price, position in sorted(self.positions.items()):
                    if position <= 0:
                        continue
                        
                    record = self.position_records.get(grid_price)
                    if not record or 'buy_price' not in record:
                        continue
                        
                    price_diff = (sell_price - record['buy_price']) / record['buy_price']
                    if price_diff >= self.grid_percentage:
                        profitable_grids.append((grid_price, position, record['buy_price']))
                        total_sell_quantity += position
                        print(f"网格 {grid_price:.1f} 符合盈利条件: 成本={record['buy_price']:.1f}, 盈利={price_diff:.1%}")
                
                if not profitable_grids:
                    return False

                # 一次性卖出所有符合条件的持仓
                if total_sell_quantity > 0:
                    try:
                        print(f"执行批量卖出: 总数量={total_sell_quantity}")
                        sell_order_id = place_market(
                            symbol=self.stock,
                            qty=total_sell_quantity,
                            side=OrderSide.SELL,
                            time_in_force=TimeInForce.DAY
                        )
                        
                        if not sell_order_id:
                            print("批量卖出订单创建失败")
                            return False
                            
                        # 记录订单信息
                        self.order_records[sell_order_id] = {
                            'side': OrderSide.SELL,
                            'grid_prices': [g[0] for g in profitable_grids],
                            'qty': total_sell_quantity
                        }
                        
                        self.pending_orders.add(sell_order_id)
                        
                        if self._check_order_status(sell_order_id):
                            # 更新所有卖出网格的持仓信息
                            success = True
                            for grid_price, qty, _ in profitable_grids:
                                if not self._update_position(grid_price, qty, sell_price, is_buy=False):
                                    success = False
                                    print(f"网格 {grid_price:.1f} 清仓数据更新失败")
                                else:
                                    print(f"网格 {grid_price:.1f} 清仓完成")
                            
                            if success:
                                self._update_period_trade_status(None, is_buy=False)
                                # 清仓后立即在当前价格网格开仓
                                current_grid = self._find_nearest_grid(current_price)
                                if current_grid:
                                    return self._place_buy_order(current_grid, current_price)
                            return success
                        else:
                            print("批量卖出订单执行失败")
                            return False
                            
                    finally:
                        self.pending_orders.discard(sell_order_id)
                
                return False
                
        except Exception as e:
            print(f"检查并执行卖出操作失败: {str(e)}")
            return False

    def _place_buy_order(self, grid_price, latest_price):
        """执行买入订单"""
        try:
            # 检查当前网格是否已存在持仓
            current_pos = self.positions.get(grid_price, 0)
            if current_pos >= self.position_limit:
                print(f"网格{grid_price:.1f}持仓{current_pos}已达上限{self.position_limit}")
                return False
                
            # 检查总持仓限制
            if self.total_position >= self.max_total_position:
                print(f"总持仓{self.total_position}已达上限{self.max_total_position}")
                return False
                
            with self._order_lock:
                try:
                    # 获取实时买入价格
                    buy_price = ask(self.stock, level=1)  # 使用卖一价
                    if not buy_price:
                        buy_price = latest_price
                        
                    print(f"执行买入: 网格={grid_price:.1f} 数量={self.min_order_quantity} @ {buy_price:.1f}")
                    buy_order_id = place_market(
                        symbol=self.stock,
                        qty=self.min_order_quantity,
                        side=OrderSide.BUY,
                        time_in_force=TimeInForce.DAY
                    )
                    
                    if not buy_order_id:
                        print("买入订单创建失败")
                        return False

                    # 记录订单信息
                    self.order_records[buy_order_id] = {
                        'side': OrderSide.BUY,
                        'grid_price': grid_price,
                        'qty': self.min_order_quantity
                    }

                    self.pending_orders.add(buy_order_id)
                    
                    if self._check_order_status(buy_order_id):
                        # 更新持仓信息
                        if self._update_position(grid_price, self.min_order_quantity, buy_price, is_buy=True):
                            print(f"买入订单成交: {buy_order_id}, 更新后持仓: {self.positions[grid_price]}")
                            return True
                        else:
                            print(f"买入成功但更新持仓失败: {buy_order_id}")
                            return False
                    else:
                        print(f"买入订单执行失败: {buy_order_id}")
                        return False
                        
                finally:
                    self.pending_orders.discard(buy_order_id)
                    
        except Exception as e:
            print(f"提交买入订单时发生错误: {str(e)}")
            return False

    def _update_position(self, grid_price, qty, price, is_buy=True):
        """更新持仓信息"""
        try:
            with self._position_lock:
                before_total = self.total_position
                grid_price = int(grid_price * 10) / 10  # 保持网格价格1位小数
                price = int(price * 10) / 10  # 保持价格1位小数
                
                if is_buy:
                    current_pos = self.positions.get(grid_price, 0)
                    new_qty = current_pos + qty
                    
                    # 验证单网格持仓限制
                    if new_qty > self.position_limit:
                        print(f"警告：网格{grid_price:.1f}更新后持仓{new_qty}将超过限制{self.position_limit}")
                        return False
                        
                    # 验证总持仓限制
                    if before_total + qty > self.max_total_position:
                        print(f"警告：更新后总持仓{before_total + qty}将超过限制{self.max_total_position}")
                        return False
                    
                    self.positions[grid_price] = new_qty
                    self.position_records[grid_price] = {
                        'buy_price': price,
                        'quantity': new_qty,
                        'update_time': time.time()
                    }
                else:
                    if grid_price in self.positions:
                        current_pos = self.positions[grid_price]
                        if current_pos >= qty:
                            self.positions[grid_price] = current_pos - qty
                            if self.positions[grid_price] == 0:
                                self.positions.pop(grid_price)
                                self.position_records[grid_price] = {
                                    'buy_price': 0,
                                    'quantity': 0,
                                    'update_time': time.time()
                                }
                            else:
                                # 保持原有成本价
                                original_record = self.position_records.get(grid_price, {})
                                self.position_records[grid_price].update({
                                    'quantity': self.positions[grid_price],
                                    'update_time': time.time()
                                })
                
                # 重新计算总持仓
                self.total_position = sum(self.positions.values())
                print(f"持仓更新 - 网格:{grid_price:.1f} 操作:{'买入' if is_buy else '卖出'} "
                    f"数量:{qty} 价格:{price:.1f} 总持仓:{self.total_position}")
                
                self._print_grid_status(show_all=False, show_time=True)
                return self._verify_positions()
                    
        except Exception as e:
            print(f"更新持仓失败: {str(e)}")
            return False

    def _check_order_status(self, order_id, max_retries=120, retry_interval=0.5):
        """检查订单状态"""
        from datetime import datetime, timedelta, timezone
        
        if not order_id:
            return False
            
        try:
            start_time = time.time()
            wait_count = 0
            
            while True:
                status = order_status(order_id)
                wait_count += 1
                
                if status == "FILLED_ALL":
                    return True
                    
                if status in ["CANCELLED_ALL", "FAILED", "DISABLED", "DELETED"]:
                    print(f"订单{order_id}已{status}")
                    return False
                    
                # 检查是否达到最大等待时间
                elapsed_time = time.time() - start_time
                if elapsed_time >= self.max_order_timeout:
                    print(f"订单{order_id}等待超时({elapsed_time:.1f}秒),准备撤单")
                    cancel_order_by_orderid(order_id)
                    return False
                    
                # 如果订单未成交但状态正常，继续等待
                if wait_count >= max_retries:
                    print(f"订单{order_id}等待次数达到上限,准备撤单")
                    cancel_order_by_orderid(order_id)
                    return False
                    
                time.sleep(retry_interval)
                
        except Exception as e:
            print(f"检查订单状态出错: {str(e)}")
            return False

    def _print_grid_status(self, show_all=True, show_time=False):
        """打印网格状态"""
        print("\n网格状态:")
        if show_all:
            for grid in sorted(self.grid_prices):
                pos = self.positions.get(grid, 0)
                record = self.position_records.get(grid, {})
                status_str = f"网格 {grid:.1f}: 持仓={pos}, 成本={record.get('buy_price', 0):.1f}"
                if show_time and pos > 0:
                    update_time = record.get('update_time', 0)
                    if update_time:
                        time_str = time.strftime('%H:%M:%S', time.localtime(update_time))
                        status_str += f", 更新时间={time_str}"
                print(status_str)
        else:
            for grid_price, qty in sorted(self.positions.items()):
                if qty > 0:
                    record = self.position_records.get(grid_price, {})
                    status_str = f"网格 {grid_price:.1f}: 持仓={qty}, 成本={record.get('buy_price', 0):.1f}"
                    if show_time:
                        update_time = record.get('update_time', 0)
                        if update_time:
                            time_str = time.strftime('%H:%M:%S', time.localtime(update_time))
                            status_str += f", 更新时间={time_str}"
                    print(status_str)
        
        print(f"总持仓: {self.total_position}")

    def _get_actual_position_from_trades(self):
        """根据实际持仓和最近成交记录验证持仓"""
        try:
            # 获取当前实际持仓
            actual_position = position_holding_qty(self.stock)
            print(f"当前实际持仓: {actual_position}股")
            
            # 验证与成交记录的一致性
            execution_ids = request_executionid(symbol=self.stock)
            if not execution_ids:
                print("无法获取成交记录")
                return actual_position
                
            total_buy = 0
            total_sell = 0
            
            # 当前策略的成交情况统计
            strategy_orders = set(self.order_records.keys())
            executed_orders = set()
            
            for eid in execution_ids:
                status = order_status(eid)
                if status != "FILLED_ALL":
                    continue
                    
                # 如果这个成交ID对应的订单是本策略的订单
                if eid in strategy_orders:
                    qty = execution_qty(eid)
                    if self.order_records[eid]['side'] == OrderSide.BUY:
                        total_buy += qty
                    else:
                        total_sell += qty
                    executed_orders.add(eid)
                    
            calculated_position = total_buy - total_sell
            
            # 检查是否有未统计到的订单
            missing_orders = strategy_orders - executed_orders
            if missing_orders:
                print(f"警告: 有{len(missing_orders)}个订单未在成交记录中找到")
                
            if actual_position != calculated_position:
                print(f"警告: 持仓不一致 - 实际持仓:{actual_position}, 成交计算持仓:{calculated_position}")
                print(f"成交统计 - 总买入:{total_buy}股, 总卖出:{total_sell}股")
                
            return actual_position
            
        except Exception as e:
            print(f"获取实际持仓时发生错误: {str(e)}")
            return 0