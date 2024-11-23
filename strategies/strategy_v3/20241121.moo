class Strategy(StrategyBase):
    """20241121网格交易策略（基础版）V1"""

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
            # 记录当前周期的交易状态
            self.current_period_trades = {
                'period': '',            # 当前周期标识
                'buy_count': 0,          # 买入次数
                'sell_count': 0,         # 卖出次数
                'grids': set()          # 已操作的网格
            }
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
            # 用户可配置参数，使用10000元，最多500股，每次交易20股，单网格最多80股，1小时线交易
            self.initial_capital = show_variable(10000, GlobalType.FLOAT, "初始资金")
            self.max_total_position = show_variable(500, GlobalType.INT, "最大总持仓")
            self.min_order_quantity = show_variable(20, GlobalType.INT, "最小交易数量")
            self.position_limit = show_variable(80, GlobalType.INT, "单个网格持仓上限")
            self.time_interval = show_variable(60, GlobalType.INT, "交易间隔(分钟)")
            
            # 以下参数保持默认
            # todo: 可以针对mara进行优化，目前8个网格，网格间距约0.3元（1.5%），收益率0.5元（2.5%）
            # todo，偏离允许0.2元，最多使用9000元，订单超时5分钟
            self.grid_num = show_variable(8, GlobalType.INT, "网格数量")
            self.grid_percentage = show_variable(0.015, GlobalType.FLOAT, "网格间距")
            self.profit_ratio = show_variable(0.025, GlobalType.FLOAT, "目标收益率")
            self.price_deviation = show_variable(0.01, GlobalType.FLOAT, "价格偏离容忍度")
            self.max_capital_usage = show_variable(0.9, GlobalType.FLOAT, "最大资金使用率")
            self.max_order_timeout = show_variable(300, GlobalType.INT, "订单超时时间(秒)")
            print("全局变量设置完成")
        except Exception as e:
            print(f"设置全局变量时发生错误: {str(e)}")

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
            print(f"当前周期已在网格{grid_price}执行过交易")
            return False
        return True

    def _update_period_trade_status(self, grid_price, is_buy=True):
        """更新周期交易状态"""
        if is_buy:
            self.current_period_trades['buy_count'] += 1
        else:
            self.current_period_trades['sell_count'] += 1
        self.current_period_trades['grids'].add(grid_price)

    def handle_data(self):
        """主要策略逻辑"""
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            
            # 获取当前价格
            latest_price = current_price(self.stock)
            if not latest_price:
                return
                    
            print(f"\n当前时间: {current_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"当前价格: {latest_price}")
            self._print_grid_status(show_all=False, show_time=True)
                
            # 初始化或重置网格
            if not self.is_initialized or self._should_reset_grid(latest_price):
                self._initialize_grids(latest_price)
                self.is_initialized = True
                return  # 网格重置后本周期不再交易
            
            # 检查是否新周期
            is_new_period = self._is_new_period(current_time)
            if not is_new_period:
                print(f"当前周期已执行交易, 等待下一周期")
                return
                
            # 先尝试执行合并卖出
            if self._execute_merged_sell(latest_price):
                self.last_trade_time = current_time
                return  # 如果执行了合并卖出和重新开仓，本周期结束
                
            # 当前网格买入逻辑
            current_grid = self._find_nearest_grid(latest_price)
            if not current_grid:
                return
                    
            print(f"当前所属网格: {current_grid}")
            
            # 检查是否可以开仓
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

    def _initialize_grids(self, base_price):
        """初始化或重置网格"""
        try:
            print(f"\n初始化网格 - 基准价格: {base_price}")
            
            with self._position_lock:
                # 保存所有现有持仓
                old_total = self.total_position
                old_positions = {k: v for k, v in self.positions.items() if v > 0}
                old_records = {k: v for k, v in self.position_records.items() 
                            if v.get('quantity', 0) > 0}
                
                # 生成新网格
                grid_range = base_price * self.grid_percentage * (self.grid_num / 2)
                bottom_price = base_price - grid_range
                price_step = (grid_range * 2) / self.grid_num
                
                new_grid_prices = []
                for i in range(self.grid_num + 1):
                    grid_price = int((bottom_price + i * price_step) * 100) / 100
                    new_grid_prices.append(grid_price)
                
                # 初始化新网格数据结构
                new_positions = {price: 0 for price in new_grid_prices}
                new_records = {price: {'buy_price': 0, 'quantity': 0} 
                            for price in new_grid_prices}
                
                # 迁移旧持仓到最接近的新网格
                for old_price, qty in old_positions.items():
                    if qty > 0:
                        new_grid = self._find_nearest_grid(old_price, new_grid_prices)
                        if new_grid:
                            print(f"迁移持仓: 从{old_price}到{new_grid}, {qty}股")
                            new_positions[new_grid] = qty
                            if old_price in old_records:
                                new_records[new_grid] = old_records[old_price].copy()
                                print(f"迁移成本价: {new_records[new_grid]['buy_price']}")
                
                # 验证持仓总量
                new_total = sum(new_positions.values())
                if new_total != old_total:
                    print(f"警告：网格重置后持仓不一致 - 之前:{old_total}, 之后:{new_total}")
                    # 尝试修复不一致
                    if old_total > 0:
                        scale = old_total / new_total if new_total > 0 else 0
                        for grid in new_positions:
                            new_positions[grid] = int(new_positions[grid] * scale)
                
                # 更新类属性
                self.grid_prices = new_grid_prices
                self.positions = new_positions
                self.position_records = new_records
                self.total_position = sum(new_positions.values())
                
                self._print_grid_status(show_all=True, show_time=False)
                self._verify_positions()

        except Exception as e:
            print(f"初始化网格时发生错误: {str(e)}")
            raise e

    def _should_reset_grid(self, latest_price):
        """判断是否需要重置网格"""
        try:
            if not self.grid_prices:
                return True
                    
            closest_grid = self._find_nearest_grid(latest_price)
            if closest_grid:
                deviation = abs(latest_price - closest_grid) / closest_grid
                if deviation > self.grid_percentage * 2:
                    print(f"价格偏离网格过大: {deviation:.2%}, 需要重置网格")
                    return True
            return False
                
        except Exception as e:
            print(f"检查网格重置时发生错误: {str(e)}")
            return False

    def _find_nearest_grid(self, target_price, grid_prices=None):
        """找到最接近目标价格的网格"""
        try:
            if grid_prices is None:
                grid_prices = self.grid_prices
                
            if not grid_prices:
                return None
                
            nearest_grid = grid_prices[0]
            min_distance = abs(target_price - nearest_grid)
            
            for grid in grid_prices[1:]:
                distance = abs(target_price - grid)
                if distance < min_distance:
                    min_distance = distance
                    nearest_grid = grid
                    
            return nearest_grid
            
        except Exception as e:
            print(f"查找最近网格失败: {str(e)}")
            return None

    def _execute_merged_sell(self, current_price):
        """执行合并卖出操作"""
        try:
            if not self._can_trade_in_period(None, is_buy=False):
                return False
                
            profitable_grids = []
            total_quantity = 0
            
            # 获取实时卖出价格
            sell_price = bid(self.stock, level=1)  # 使用买一价保证成交
            if not sell_price:
                sell_price = current_price
            
            # 查找所有符合盈利条件的网格
            with self._position_lock:
                for grid_price, position in self.positions.items():
                    if position <= 0:
                        continue
                        
                    record = self.position_records.get(grid_price)
                    if not record or 'buy_price' not in record:
                        continue
                        
                    buy_price = record['buy_price']
                    profit_ratio = (sell_price - buy_price) / buy_price
                    
                    if profit_ratio >= self.profit_ratio:
                        profitable_grids.append(grid_price)
                        total_quantity += position
                        print(f"网格 {grid_price} 符合盈利条件: 成本={buy_price}, 盈利={profit_ratio:.2%}")
                
                if not profitable_grids or total_quantity == 0:
                    return False

            # 执行批量卖出
            with self._order_lock:
                print(f"执行合并卖出: {profitable_grids} 总数量:{total_quantity}")
                sell_order_id = place_market(
                    symbol=self.stock,
                    qty=total_quantity,
                    side=OrderSide.SELL,
                    time_in_force=TimeInForce.DAY
                )
                
                if not sell_order_id:
                    return False
                    
                self.pending_orders.add(sell_order_id)
                
                # 等待卖出订单完成
                if not self._check_order_status(sell_order_id):
                    self.pending_orders.remove(sell_order_id)
                    return False

            # 更新持仓信息
            with self._position_lock:
                before_total = self.total_position
                for grid in profitable_grids:
                    grid_position = self.positions[grid]
                    if grid_position > 0:
                        self._update_position(grid, grid_position, sell_price, is_buy=False)
                        print(f"网格 {grid} 清仓完成")
                
                # 验证持仓更新
                after_total = self.total_position
                if after_total != before_total - total_quantity:
                    print(f"警告：持仓不一致 - 之前:{before_total}, 之后:{after_total}, 应该为:{before_total - total_quantity}")
            
            # 更新周期交易状态
            self._update_period_trade_status(None, is_buy=False)
            
            # 基于当前价格重新开仓
            return self._execute_reopen_positions(current_price, len(profitable_grids))
            
        except Exception as e:
            print(f"合并卖出执行失败: {str(e)}")
            return False

    def _execute_reopen_positions(self, current_price, positions_count):
        """执行重新开仓"""
        try:
            if not self._can_trade_in_period(None, is_buy=True):
                return False
                
            # 获取买入价格
            buy_price = ask(self.stock, level=1)  # 使用卖一价
            if not buy_price:
                buy_price = current_price
                
            # 找到当前价格对应的网格
            current_grid = self._find_nearest_grid(current_price)
            if not current_grid:
                return False
                
            print(f"重新开仓 - 目标网格:{current_grid}, 数量:{self.min_order_quantity}")
            
            # 执行买入
            buy_order_id = place_market(
                symbol=self.stock,
                qty=self.min_order_quantity,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if not buy_order_id or not self._check_order_status(buy_order_id):
                return False
                
            # 更新持仓
            self._update_position(current_grid, self.min_order_quantity, buy_price, is_buy=True)
            
            # 更新周期交易状态
            self._update_period_trade_status(current_grid, is_buy=True)
            
            print(f"网格 {current_grid} 重新开仓成功")
            return True
            
        except Exception as e:
            print(f"重新开仓失败: {str(e)}")
            return False

    def _place_buy_order(self, grid_price, latest_price):
        """执行买入订单"""
        try:
            # 检查当前网格是否已存在持仓
            current_pos = self.positions.get(grid_price, 0)
            if current_pos >= self.position_limit:
                print(f"网格{grid_price}持仓{current_pos}已达上限")
                return False
                
            # 检查总持仓限制
            if self.total_position >= self.max_total_position:
                print(f"总持仓{self.total_position}已达上限{self.max_total_position}")
                return False
                
            with self._order_lock:
                # 获取实时买入价格
                buy_price = ask(self.stock, level=1)  # 使用卖一价
                if not buy_price:
                    buy_price = latest_price
                    
                print(f"执行买入: {self.min_order_quantity}股 @ {buy_price}")
                order_id = place_market(  # 使用市价单
                    symbol=self.stock,
                    qty=self.min_order_quantity,
                    side=OrderSide.BUY,
                    time_in_force=TimeInForce.DAY
                )
                
                if not order_id:
                    print("买入订单创建失败")
                    return False

                self.pending_orders.add(order_id)
                buy_success = self._check_order_status(order_id)
                self.pending_orders.discard(order_id)
                
                if buy_success:
                    # 更新持仓信息
                    if self._update_position(grid_price, self.min_order_quantity, buy_price, is_buy=True):
                        print(f"买入订单成交: {order_id}, 更新后持仓: {self.positions[grid_price]}")
                        return True
                    else:
                        print(f"买入成功但更新持仓失败: {order_id}")
                        return False
                else:
                    print(f"买入订单执行失败:{order_id}")
                    return False
                    
        except Exception as e:
            print(f"提交买入订单时发生错误: {str(e)}")
            return False

    def _update_position(self, grid_price, qty, price, is_buy=True):
        """更新持仓信息"""
        try:
            with self._position_lock:
                before_total = sum(self.positions.values())
                
                if is_buy:
                    # 买入更新
                    current_pos = self.positions.get(grid_price, 0)
                    new_qty = current_pos + qty
                    
                    # 验证单网格持仓限制
                    if new_qty > self.position_limit:
                        print(f"警告：网格{grid_price}更新后持仓{new_qty}将超过限制{self.position_limit}")
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
                    # 卖出更新
                    if grid_price in self.positions:
                        current_pos = self.positions.get(grid_price, 0)
                        if current_pos >= qty:  # 确保有足够的持仓可卖
                            self.positions[grid_price] = current_pos - qty
                            if self.positions[grid_price] == 0:
                                # 如果已无持仓，清除记录
                                self.positions.pop(grid_price, None)
                                self.position_records[grid_price] = {
                                    'buy_price': 0,
                                    'quantity': 0,
                                    'update_time': time.time()
                                }
                            else:
                                # 更新剩余持仓信息，保持原有成本价
                                original_record = self.position_records.get(grid_price, {})
                                self.position_records[grid_price] = {
                                    'buy_price': original_record.get('buy_price', 0),
                                    'quantity': self.positions[grid_price],
                                    'update_time': time.time()
                                }
                
                # 重新计算总持仓
                after_total = sum(self.positions.values())
                expected_total = before_total + qty if is_buy else before_total - qty
                
                if after_total != expected_total:
                    print(f"警告：持仓更新不一致 - 之前:{before_total}, 之后:{after_total}, 期望:{expected_total}")
                    return False
                
                self.total_position = after_total
                print(f"持仓更新 - 网格:{grid_price} 操作:{'买入' if is_buy else '卖出'} "
                    f"数量:{qty} 价格:{price} 总持仓:{self.total_position}")
                
                # 打印当前所有持仓状态
                self._print_grid_status(show_all=False, show_time=True)
                
                # 验证更新后的持仓数据
                return self._verify_positions()
                
        except Exception as e:
            print(f"更新持仓失败: {str(e)}")
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
                    print(f"警告: 网格 {grid_price} 持仓不一致 - position:{pos}, record:{rec}")
                    return False
                    
            if total_from_positions != total_from_records:
                print(f"警告: 总持仓不一致 - positions:{total_from_positions}, records:{total_from_records}")
                return False
                
            # 验证总持仓记录
            if self.total_position != total_from_positions:
                print(f"警告: total_position({self.total_position}) != sum of positions({total_from_positions})")
                return False
                
            return True
            
        except Exception as e:
            print(f"验证持仓失败: {str(e)}")
            return False

    def _check_order_status(self, order_id, max_retries=120, retry_interval=0.5):
        """检查订单状态"""
        from datetime import datetime, timedelta, timezone
        
        if not order_id:
            return False
            
        try:
            current_time = datetime.now(timezone(timedelta(hours=-5)))
            near_close = current_time.time().hour == 15 and current_time.time().minute >= 55
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
                    
                # 检查是否临近收盘
                if near_close:
                    print(f"临近收盘,取消订单{order_id}")
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
            # 显示所有网格，包括空仓
            for grid in sorted(self.grid_prices):
                pos = self.positions.get(grid, 0)
                record = self.position_records.get(grid, {})
                status_str = f"网格 {grid:.2f}: 持仓={pos}, 成本={record.get('buy_price', 0):.2f}"
                if show_time and pos > 0:  # 只对有持仓的显示时间
                    update_time = record.get('update_time', 0)
                    if update_time:
                        time_str = time.strftime('%H:%M:%S', time.localtime(update_time))
                        status_str += f", 更新时间={time_str}"
                print(status_str)
        else:
            # 只显示有持仓的网格
            for grid_price, qty in sorted(self.positions.items()):
                if qty > 0:
                    record = self.position_records.get(grid_price, {})
                    status_str = f"网格 {grid_price:.2f}: 持仓={qty}, 成本={record.get('buy_price', 0):.2f}"
                    if show_time:
                        update_time = record.get('update_time', 0)
                        if update_time:
                            time_str = time.strftime('%H:%M:%S', time.localtime(update_time))
                            status_str += f", 更新时间={time_str}"
                    print(status_str)
        
        print(f"总持仓: {self.total_position}")