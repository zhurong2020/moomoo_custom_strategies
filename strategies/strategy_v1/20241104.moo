class Strategy(StrategyBase):
    def initialize(self):
        """初始化策略"""
        try:
            print("------------------------")
            print("开始策略初始化...")
            
            # 初始化数据结构
            self.position_records = {}
            self.trade_history = []
            self.total_profit = 0
            self.trade_count = 0
            self.win_count = 0
            self.total_position = 0
            
            # 执行标准初始化流程
            self.trigger_symbols()
            self.custom_indicator()
            
            # 先调用global_variables获取初始资金和其他UI可配置参数
            self.global_variables()
            
            # 初始化重要参数
            self.price_precision = 3      
            self.max_loss_ratio = 0.15    # 提高最大亏损容忍度
            self.max_capital_usage = 0.9  # 提高资金使用率上限
            
            # 网格交易相关参数
            self.grid_extension_factor = 0.5  
            self.grid_max_levels = 15     
            self.grid_min_price_gap = 0.003  # 降低最小网格间距
            self.grid_price_ranges = {}
            
            # 持仓和网格相关
            self.positions = {}          
            self.grid_prices = []        
            self.is_initialized = False  
            self.reset_threshold = 0.08  # 降低网格重置阈值
            
            # 新增：记录每个网格最后交易时间
            self.last_trade_time = {}
            
            # 新增：最小交易间隔(秒)
            self.min_trade_interval = 300  # 5分钟
            
            # 计算并设置策略参数
            recommended_params = self._calculate_initial_parameters()
            if recommended_params:
                self.global_variables(recommended_params)
                
            print("策略初始化完成")
            print("------------------------")
            
        except Exception as e:
            print(f"策略初始化发生错误：{str(e)}")
            import traceback
            print(traceback.format_exc())

    def trigger_symbols(self):
        """定义交易标的"""
        try:
            self.stock = declare_trig_symbol()
            print("交易标的设置完成")
        except Exception as e:
            print("设置交易标的时发生错误：", str(e))

    def custom_indicator(self):
        """设置技术指标"""
        try:
            self.register_indicator(
                indicator_name='MA',
                script='''MA5:MA(CLOSE,5),COLORFF8D1E;
                         MA10:MA(CLOSE,10),COLOR2196F3;
                         MA20:MA(CLOSE,20),COLORFF5252;''',
                param_list=[]
            )
            print("技术指标设置完成")
        except Exception as e:
            print(f"设置技术指标时发生错误: {str(e)}")
            
    def global_variables(self, recommended_params=None):
        """定义全局变量"""
        try:
            # 固定显示在UI上的变量
            self.initial_capital = show_variable(50000, GlobalType.FLOAT)
            self.position_limit = show_variable(50, GlobalType.INT)
            self.max_total_position = show_variable(500, GlobalType.INT)
            self.profit_ratio = show_variable(0.008, GlobalType.FLOAT)  # 降低目标收益率
            self.price_deviation = show_variable(0.005, GlobalType.FLOAT)  # 降低价格偏离阈值
            self.grid_num = show_variable(7, GlobalType.INT)
            
            # 其他参数设置
            if recommended_params:
                self.position_step = recommended_params.get('position_step', 0.2)
                self.min_order_quantity = recommended_params.get('min_order_quantity', 10)
            else:
                self.min_order_quantity = 10
                self.position_step = 0.2
                print("使用默认仓位步长：20%")
                
            # 内部变量初始化
            self.grid_prices = []      
            self.positions = {}        
            self.is_initialized = False
            self.total_position = 0
            
        except Exception as e:
            print("设置全局变量时发生错误：", str(e))
            self.position_step = 0.2

    def _calculate_initial_parameters(self):
        try:
            initial_price = current_price(self.stock)
            if not initial_price:
                print("获取初始价格失败")
                return None
                
            print("\n初始参数计算:")
            print(f"初始价格: {initial_price:.2f}")
            print(f"初始资金: {self.initial_capital:.2f}")
            
            # 设置基础参数
            min_trade_value = 500  # 最小交易金额
            
            # 根据资金量调整参数
            if self.initial_capital >= 50000:
                capital_level = "large"
                target_grid_ratio = 0.15  # 提高单网格占比
                total_capital_ratio = 0.8  # 提高总资金使用率
            else:
                capital_level = "small"
                target_grid_ratio = 0.18
                total_capital_ratio = 0.85
                
            # 计算基础交易数量
            ideal_grid_capital = self.initial_capital * target_grid_ratio
            base_quantity = int(ideal_grid_capital / (3 * initial_price))
            
            # 调整最小交易数量
            min_quantity = max(10, int(min_trade_value / initial_price))
            min_quantity = (min_quantity // 10) * 10
            
            # 根据价格动态调整网格数量
            if initial_price >= 100:
                trade_quantity = max(min_quantity, 20)
                grid_num = 6
            else:
                trade_quantity = max(min_quantity, 50)
                grid_num = 8
                
            # 计算网格最大持仓
            max_grid_position = int(self.initial_capital * target_grid_ratio / initial_price)
            max_grid_position = (max_grid_position // trade_quantity) * trade_quantity
            max_grid_position = max(max_grid_position, trade_quantity * 3)
            
            # 计算最大总持仓
            max_total_position = int(self.initial_capital * total_capital_ratio / initial_price)
            max_total_position = (max_total_position // trade_quantity) * trade_quantity
            
            # 计算推荐参数
            recommended_params = {
                'position_limit': max_grid_position,
                'max_total_position': max_total_position,
                'min_order_quantity': trade_quantity,
                'grid_num': grid_num,
                'price_deviation': 0.004, 
                'position_step': 0.2,
                'profit_ratio': 0.005
            }
            
            # 打印参数和资金分配预览
            print("\n参数推荐:")
            print(f"资金等级: {'小资金' if capital_level == 'small' else '大资金'}")
            print(f"单格最大持仓限制: {recommended_params['position_limit']} 股")
            print(f"最大总持仓限制: {recommended_params['max_total_position']} 股")
            print(f"每次交易数量: {recommended_params['min_order_quantity']} 股")
            print(f"网格数量: {recommended_params['grid_num']}")
            print(f"网格间距: {recommended_params['price_deviation']:.1%}")
            print(f"目标收益率: {recommended_params['profit_ratio']:.1%}")
            
            # 计算资金分配预览
            single_trade_value = trade_quantity * initial_price
            max_grid_value = max_grid_position * initial_price
            max_total_value = max_total_position * initial_price
            
            print(f"\n资金分配预览:")
            print(f"单次交易金额: {single_trade_value:.2f} (资金占比: {(single_trade_value/self.initial_capital)*100:.1f}%)")
            print(f"单格最大金额: {max_grid_value:.2f} (资金占比: {(max_grid_value/self.initial_capital)*100:.1f}%)")
            print(f"最大总金额: {max_total_value:.2f} (资金占比: {(max_total_value/self.initial_capital)*100:.1f}%)")
            
            return recommended_params
                
        except Exception as e:
            print(f"计算初始参数失败: {str(e)}")
            return None
                    
    def _calculate_grid_deviation(self, price):
        """计算动态网格间距"""
        try:
            volatility = self._calculate_volatility()
            if not volatility:
                return 0.005  # 默认0.5%
                
            # 基于波动率动态调整网格间距
            base_deviation = max(min(volatility * 0.3, 0.015), 0.003)
            
            # 根据价格区间微调
            if price < 20:
                return base_deviation * 1.2
            elif price < 50:
                return base_deviation * 1.1
            elif price < 200:
                return base_deviation
            else:
                return base_deviation * 0.9
                
        except Exception as e:
            print(f"计算网格间距失败: {str(e)}")
            return 0.005

    def _should_buy(self, grid_price, latest_price, current_position):
        """改进的买入判断方法，包含动态持仓限制"""
        try:
            # 获取动态持仓限制
            dynamic_position_limit = self._calculate_dynamic_position_limit(grid_price, latest_price)
            
            # 检查网格持仓是否达到动态限制
            grid_position = self.positions.get(grid_price, 0)
            if grid_position >= dynamic_position_limit:
                print(f"网格 {grid_price} 已达到动态持仓上限: {grid_position}/{dynamic_position_limit}")
                return False

            # 检查总持仓是否达到限制
            if self.total_position >= self.max_total_position:
                print(f"总持仓已达到上限: {self.total_position}/{self.max_total_position}")
                return False

            # 获取当前时间
            current_time = self._get_current_time()
            current_date = current_time.date()

            # 检查今日是否已经在该网格价位开仓
            grid_record = self.position_records.get(grid_price)
            if grid_record:
                # 确保daily_trade_count存在
                if 'daily_trade_count' not in grid_record:
                    grid_record['daily_trade_count'] = {}

                daily_trades = grid_record['daily_trade_count'].get(current_date, 0)
                if daily_trades >= 3:  # 允许每个网格每天最多3次交易
                    print(f"今日已在网格 {grid_price} 达到最大交易次数")
                    return False
            else:
                # 如果网格记录不存在，创建初始记录
                self.position_records[grid_price] = {
                    'positions': [],
                    'total_quantity': 0,
                    'average_cost': 0,
                    'last_trade_time': current_time,
                    'last_trade_price': latest_price,
                    'daily_trade_count': {},
                    'total_trades': 0
                }

            # 计算价格偏离度
            price_diff = abs(latest_price - grid_price) / grid_price
            print(f"价格偏离度: {price_diff:.2%}")

            # 对首次开仓和后续建仓采用不同策略
            if grid_position == 0:  # 首次开仓
                print("首次网格开仓检查")
                return price_diff <= self.price_deviation * 1.2  # 首次开仓允许更大的价格偏离
            
            # 后续建仓检查 - 放宽价格偏离限制
            if price_diff <= self.price_deviation * 1.5:  # 允许更大的价格偏离
                # 检查与上次交易的时间间隔
                last_trade_time = grid_record.get('last_trade_time')
                if last_trade_time:
                    time_diff = (current_time - last_trade_time).total_seconds()
                    if time_diff < self.min_trade_interval:
                        print(f"距离上次交易时间太短: {time_diff:.0f}秒")
                        return False
                return True

            return False

        except Exception as e:
            print(f"买入判断失败: {str(e)}")
            traceback.print_exc()
            return False
            
    def _should_sell(self, grid_price, latest_price, current_position):
        try:
            if current_position <= 0:
                return False, 0
                
            # 获取所有持仓的网格
            profitable_positions = []
            total_sell_quantity = 0
            
            # 检查所有网格的持仓盈利情况
            for grid, record in self.position_records.items():
                if record['total_quantity'] > 0:
                    avg_cost = record['average_cost']
                    current_profit_ratio = (latest_price - avg_cost) / avg_cost
                    
                    # 如果达到目标盈利比例，加入卖出列表
                    if current_profit_ratio >= self.profit_ratio:
                        print(f"网格 {grid} 达到目标盈利 {current_profit_ratio:.2%}")
                        # 加入全部持仓数量
                        profitable_positions.append({
                            'grid_price': grid,
                            'quantity': record['total_quantity'],  # 改为全部数量
                            'profit_ratio': current_profit_ratio,
                            'avg_cost': avg_cost
                        })
                        total_sell_quantity += record['total_quantity']
            
            if profitable_positions:
                # 打印卖出详情
                for pos in profitable_positions:
                    print(f"将卖出网格 {pos['grid_price']}: {pos['quantity']}股, "
                          f"成本 {pos['avg_cost']:.2f}, 盈利 {pos['profit_ratio']:.2%}")
                return True, total_sell_quantity
                    
            return False, 0
                    
        except Exception as e:
            print(f"卖出判断失败: {str(e)}")
            return False, 0

    def _execute_trades(self, market_data):
        """改进的交易执行逻辑，支持批量卖出和卖出后立即建仓"""
        try:
            latest_price = market_data['latest_price']
            if not latest_price:
                return
                
            print(f"\n当前价格: {latest_price}")
                
            # 首先处理总持仓为0的情况
            if self.total_position == 0:
                # 检查是否需要重置网格
                if self._should_reset_grid(latest_price):
                    print("初始化网格")
                    self._initialize_grids(latest_price)
                    self.is_initialized = True
                
                # 直接在当前价位尝试开仓
                quantity = self._calculate_order_quantity(latest_price, latest_price, 0)
                if quantity > 0:
                    print(f"总持仓为0，尝试在当前价位开仓 {quantity} 股 @ {latest_price}")
                    self.place_buy_order(latest_price, latest_price, quantity)
                    # 验证持仓 [新增]
                    self._safe_update_positions(operation_type='首次开仓')
                    return
                    
            # 常规情况下的网格检查和初始化
            if not self.is_initialized or self._should_reset_grid(latest_price):
                if self.total_position == 0:  # 只有在没有持仓时才重置网格
                    print("初始化网格")
                    self._initialize_grids(latest_price)
                    self.is_initialized = True
                
            # 找到当前价格所属的网格
            current_grid = self._find_suitable_grid(latest_price)
            if not current_grid:
                return
                
            print(f"匹配到网格价格: {current_grid}")
            
            # 检查资金使用情况
            total_value = self.total_position * latest_price
            capital_usage = total_value / self.initial_capital
            print(f"当前资金使用率: {capital_usage:.2%}")
            
            # 获取当前网格的持仓信息
            grid_position = self.positions.get(current_grid, 0)
            print(f"网格 {current_grid} 当前持仓: {grid_position}")
            
            # 收集所有需要卖出的网格
            sell_candidates = []
            total_sell_quantity = 0
            for grid_price, record in self.position_records.items():
                if record['total_quantity'] > 0:
                    avg_cost = record['average_cost']
                    current_profit_ratio = (latest_price - avg_cost) / avg_cost
                    if current_profit_ratio >= self.profit_ratio:
                        sell_candidates.append({
                            'grid_price': grid_price,
                            'quantity': record['total_quantity'],
                            'profit_ratio': current_profit_ratio
                        })
                        total_sell_quantity += record['total_quantity']

            # 批量卖出
            if sell_candidates:
                # 按profit_ratio降序排序，优先卖出高收益的网格
                sell_candidates.sort(key=lambda x: x['profit_ratio'], reverse=True)
                
                # 分批卖出，每批不超过100股
                batch_size = 100
                for i in range(0, len(sell_candidates), batch_size):
                    batch = sell_candidates[i:i+batch_size]
                    batch_quantity = sum(item['quantity'] for item in batch)
                    
                    # 执行卖出订单
                    sell_order_id = self.place_sell_order(latest_price, batch[0]['grid_price'], batch_quantity)
                    if sell_order_id:
                        print(f"批量卖出订单执行成功，订单号: {sell_order_id}")
                        
                        # 更新所有相关网格的持仓
                        for sell_item in batch:
                            self._update_position_after_sell(
                                sell_item['grid_price'], 
                                sell_item['quantity'],
                                latest_price,
                                self._get_current_time()
                            )
                        
                        # 验证持仓 [新增]
                        self._safe_update_positions(operation_type='批量卖出')
                        
                        # 等待一个最小交易间隔
                        time.sleep(self.min_trade_interval/10)  # 稍微延迟以确保订单处理完成
                
                        # 检查是否需要在当前网格重新建仓
                        if self._should_buy(current_grid, latest_price, 0):
                            quantity = self._calculate_order_quantity(current_grid, latest_price, 0)
                            if quantity > 0:
                                print(f"执行卖出后建仓: 尝试买入 {quantity} 股 @ {latest_price}")
                                self.place_buy_order(latest_price, current_grid, quantity)
                                # 验证持仓 [新增]
                                self._safe_update_positions(operation_type='卖出后重新建仓')
                                
                        # 如果全部卖出且买入失败，标记需要重新初始化网格
                        if self.total_position == 0:
                            self.is_initialized = False
                            
            else:
                # 如果没有卖出，检查是否可以买入
                if self._should_buy(current_grid, latest_price, grid_position):
                    quantity = self._calculate_order_quantity(current_grid, latest_price, grid_position)
                    if quantity > 0:
                        print(f"尝试在网格 {current_grid} 买入 {quantity} 股 @ {latest_price}")
                        self.place_buy_order(latest_price, current_grid, quantity)
                        # 验证持仓 [新增]
                        self._safe_update_positions(operation_type='常规买入')
                        
            # 方法结束前进行最后的持仓验证 [新增]
            self._safe_update_positions(operation_type='交易周期结束')
                            
        except Exception as e:
            print(f"执行交易失败: {str(e)}")
            print(traceback.format_exc())

    def _initialize_grids(self, base_price):
        try:
            print(f"\n初始化网格 - 基准价格: {base_price:.1f}")
                
            self.grid_prices = []
            self.positions = {}
            self.position_records = {}
                
            # 设置合适的网格间距（例如0.3元或1.5%）
            grid_spacing = 0.3  # 固定0.3元间距
                
            # 计算需要的网格数量
            price_range = base_price * 0.1  # 上下10%的价格范围
            grid_count = int(price_range / grid_spacing)
            
            current_time = self._get_current_time()
                
            # 生成网格价格
            for i in range(-grid_count, grid_count + 1):
                grid_price = self._format_price(base_price + i * grid_spacing)
                self.grid_prices.append(grid_price)
                self.positions[grid_price] = 0
                self.position_records[grid_price] = {
                    'positions': [],
                    'total_quantity': 0,
                    'average_cost': 0,
                    'last_trade_time': current_time,
                    'last_trade_price': grid_price,
                    'daily_trade_count': {},  # 新增：按日期统计交易次数
                    'total_trades': 0         # 新增：总交易次数
                }
                    
                print("\n网格配置信息:")
                for i in range(len(self.grid_prices) - 1):
                    current = self.grid_prices[i]
                    next_price = self.grid_prices[i + 1]
                    gap = next_price - current
                    print(f"网格 {current:.1f} -> {next_price:.1f}, 间距: {gap:.1f}")
                    
        except Exception as e:
            print(f"初始化网格错误: {str(e)}")
            traceback.print_exc()  # 添加详细的错误跟踪
    
    def _calculate_order_quantity(self, grid_price, latest_price, current_position):
        """改进的订单数量计算，考虑首次开仓情况"""
        try:
            # 计算网格剩余容量
            remaining_grid_capacity = self.position_limit - current_position
            remaining_total_capacity = self.max_total_position - self.total_position
            
            # 基础交易数量
            base_quantity = self.min_order_quantity
            
            # 首次开仓使用较大的建仓量
            if self.total_position == 0:
                base_quantity = int(self.min_order_quantity * 2)  # 首次建仓量加倍
            else:
                # 根据价格偏离度增加买入数量
                price_diff = (latest_price - grid_price) / grid_price
                if price_diff < -0.01:  # 价格低于网格价格1%
                    base_quantity = int(base_quantity * 1.5)  # 增加50%
                elif price_diff < -0.02:  # 价格低于网格价格2%
                    base_quantity = int(base_quantity * 2)  # 翻倍
            
            # 确保不超过各种限制
            order_quantity = min(
                base_quantity,
                remaining_grid_capacity,
                remaining_total_capacity,
                int(self.initial_capital * 0.1 / latest_price)  # 单次资金使用限制10%
            )
            
            # 确保是最小交易单位的整数倍
            order_quantity = (order_quantity // self.min_order_quantity) * self.min_order_quantity
            
            return max(order_quantity, self.min_order_quantity)
                
        except Exception as e:
            print(f"计算交易数量失败: {str(e)}")
            return 0
            
    def _update_position_records(self, grid_price, price, quantity, timestamp):
        """完整的持仓记录更新函数，包含错误处理和验证"""
        try:
            if not all([grid_price, price, quantity, timestamp]):
                return

            # 初始化网格记录
            if grid_price not in self.position_records:
                self.position_records[grid_price] = {
                    'positions': [],
                    'total_quantity': 0,
                    'average_cost': 0,
                    'last_trade_time': timestamp,
                    'last_trade_price': price,
                    'daily_trade_count': {},  # 按日期统计交易次数
                    'total_trades': 0         # 总交易次数
                }
                self.positions[grid_price] = 0

            record = self.position_records[grid_price]

            # 更新每日交易统计
            trade_date = timestamp.date()
            if trade_date not in record['daily_trade_count']:
                record['daily_trade_count'][trade_date] = 0
            record['daily_trade_count'][trade_date] += 1

            # 确保total_trades存在并更新
            if 'total_trades' not in record:
                record['total_trades'] = 0
            record['total_trades'] += 1

            # 记录新的买入交易
            new_position = {
                'price': price,
                'quantity': quantity,
                'timestamp': timestamp,
                'remaining': quantity,
                'trade_type': 'buy'
            }
            record['positions'].append(new_position)

            # 重新计算总持仓和平均成本
            valid_positions = [p for p in record['positions'] if p['remaining'] > 0]
            total_quantity = sum(p['remaining'] for p in valid_positions)
            if total_quantity > 0:
                total_cost = sum(p['price'] * p['remaining'] for p in valid_positions)
                record['average_cost'] = total_cost / total_quantity
            else:
                record['average_cost'] = 0

            # 更新网格状态
            record['total_quantity'] = total_quantity
            record['last_trade_time'] = timestamp
            record['last_trade_price'] = price

            # 同步更新全局状态
            self.positions[grid_price] = total_quantity
            # 重新计算总持仓
            self.total_position = sum(self.positions.values())

            # 清理已完全卖出的持仓记录
            record['positions'] = [p for p in record['positions'] if p['remaining'] > 0]

            # 验证持仓更新
            self._verify_total_position()

            # 打印更新信息
            print(f"\n更新持仓记录 - 网格 {grid_price:.2f}:")
            print(f"新增买入: {quantity}股 @ {price:.2f}")
            print(f"当前持仓: {total_quantity}")
            print(f"平均成本: {record['average_cost']:.2f}")
            print(f"总持仓量: {self.total_position}")
            print(f"当日交易次数: {record['daily_trade_count'][trade_date]}")
            print(f"累计交易次数: {record['total_trades']}")

        except Exception as e:
            print(f"更新持仓记录失败: {str(e)}")
            print(traceback.format_exc())
            
    def _update_position_after_sell(self, grid_price, sell_quantity, sell_price, timestamp):
        """改进的卖出后持仓更新"""
        try:
            if grid_price not in self.position_records:
                return
                
            record = self.position_records[grid_price]
            remaining_to_sell = sell_quantity
            profit = 0
            
            # 按FIFO顺序更新持仓
            for position in record['positions']:
                if remaining_to_sell <= 0:
                    break
                    
                if position['remaining'] > 0:
                    sell_from_position = min(position['remaining'], remaining_to_sell)
                    position_profit = (sell_price - position['price']) * sell_from_position
                    profit += position_profit
                    
                    position['remaining'] -= sell_from_position
                    remaining_to_sell -= sell_from_position
            
            # 清理已经全部卖出的记录
            record['positions'] = [p for p in record['positions'] if p['remaining'] > 0]
            
            # 更新总持仓和平均成本
            total_quantity = sum(p['remaining'] for p in record['positions'])
            if total_quantity > 0:
                total_cost = sum(p['price'] * p['remaining'] for p in record['positions'])
                record['average_cost'] = total_cost / total_quantity
            else:
                record['average_cost'] = 0
                
            record['total_quantity'] = total_quantity
            record['last_update'] = timestamp
            
            print(f"\n更新卖出记录 - 网格 {grid_price:.2f}:")
            print(f"卖出: {sell_quantity}股 @ {sell_price:.2f}")
            print(f"实现收益: {profit:.2f}")
            print(f"剩余持仓: {total_quantity}")
            if total_quantity > 0:
                print(f"新平均成本: {record['average_cost']:.2f}")
                
            self._verify_total_position() # 20241109
            return profit
                
        except Exception as e:
            print(f"更新卖出记录失败: {str(e)}")
            return 0

    def _should_reset_grid(self, latest_price):
        """改进的网格重置逻辑"""
        try:
            if not self.grid_prices:
                return True
                        
            # 当总持仓为0时，检查是否需要重置网格
            if self.total_position == 0:
                if not self.grid_prices:  # 如果没有网格，直接重置
                    return True
                    
                # 找到最接近当前价格的网格
                closest_deviation = None
                closest_grid = None
                
                for grid_price in self.grid_prices:
                    deviation = abs(grid_price - latest_price)
                    if closest_deviation is None or deviation < closest_deviation:
                        closest_deviation = deviation
                        closest_grid = grid_price
                
                if closest_grid:
                    # 计算偏离度
                    deviation = closest_deviation / closest_grid
                    
                    # 如果偏离度超过阈值，重置网格
                    if deviation > 0.05:  # 降低到5%就重置
                        print(f"价格偏离最近网格 {deviation:.2%}，且无持仓，将重置网格")
                        return True
                            
            return False
                        
        except Exception as e:
            print(f"检查网格重置失败: {str(e)}")
            return False

    def _analyze_market_condition(self):
        """改进的市场分析"""
        try:
            market_data = self._get_market_data()
            if not market_data:
                return None
                
            latest_price = market_data['latest_price'] 
            ma_values = {
                'MA5': market_data.get('ma5'),
                'MA10': market_data.get('ma10'),
                'MA20': market_data.get('ma20')
            }
            
            # 趋势判断
            trend = "震荡"
            if all(v is not None for v in ma_values.values()):
                if ma_values['MA5'] > ma_values['MA10'] > ma_values['MA20']:
                    trend = "上涨"
                elif ma_values['MA5'] < ma_values['MA10'] < ma_values['MA20']:
                    trend = "下跌"
                    
            # 计算波动性
            volatility = self._calculate_volatility()
            
            # 计算当前价格相对MA的位置
            price_position = "中间"
            if latest_price > ma_values['MA5']:
                price_position = "偏高"
            elif latest_price < ma_values['MA5']:
                price_position = "偏低"
                
            market_condition = {
                'price': latest_price,
                'ma_values': ma_values,
                'trend': trend,
                'volatility': volatility,
                'price_position': price_position
            }
            
            # 动态调整策略参数
            self._adjust_strategy_parameters(market_condition)
            
            return market_condition
            
        except Exception as e:
            print(f"分析市场状况失败: {str(e)}")
            return None

    def _adjust_strategy_parameters(self, market_condition):
        """动态调整策略参数"""
        try:
            if not market_condition:
                return
                
            volatility = market_condition.get('volatility')
            trend = market_condition.get('trend')
            price_position = market_condition.get('price_position')
            
            # 调整网格间距
            if volatility:
                new_grid_deviation = max(min(volatility * 0.3, 0.015), 0.003)
                if abs(new_grid_deviation - self.price_deviation) > 0.001:
                    self.price_deviation = new_grid_deviation
                    print(f"调整网格间距至: {self.price_deviation:.3%}")
            
            # 调整目标收益率
            base_profit_ratio = 0.006  # 基础收益率0.6%
            if trend == "上涨":
                self.profit_ratio = base_profit_ratio * 1.2
            elif trend == "下跌":
                self.profit_ratio = base_profit_ratio * 0.8
            else:  # 震荡
                self.profit_ratio = base_profit_ratio
                
            # 调整持仓限制
            if price_position == "偏低":
                self.position_limit = int(self.position_limit * 1.2)  # 允许更多持仓
            elif price_position == "偏高":
                self.position_limit = int(self.position_limit * 0.8)  # 减少持仓上限
                
        except Exception as e:
            print(f"调整策略参数失败: {str(e)}")

    def _check_risk_control(self):
        """改进的风险控制"""
        try:
            latest_price = current_price(symbol=self.stock)
            if latest_price is None:
                return False
                    
            total_value = 0
            total_cost = 0
            max_single_grid_loss = 0
            max_loss_grid = None
            
            # 检查持仓
            has_positions = False
            for grid_price, record in self.position_records.items():
                if record['total_quantity'] <= 0:
                    continue
                        
                has_positions = True
                position_value = record['total_quantity'] * latest_price
                grid_cost = record['total_quantity'] * record['average_cost']
                
                # 计算单个网格亏损
                grid_loss_ratio = (position_value - grid_cost) / grid_cost
                if grid_loss_ratio < max_single_grid_loss:
                    max_single_grid_loss = grid_loss_ratio
                    max_loss_grid = grid_price
                
                # 检查单个网格集中度
                grid_ratio = position_value / self.initial_capital
                if grid_ratio > 0.2:  # 单网格不超过20%资金
                    print(f"警告：网格 {grid_price:.2f} 持仓过高 ({grid_ratio:.1%})")
                
                total_value += position_value
                total_cost += grid_cost
                
            if has_positions:
                # 计算总体盈亏
                total_profit_ratio = (total_value - total_cost) / total_cost
                
                # 检查总体资金使用率
                capital_usage = total_value / self.initial_capital
                
                # 风险预警条件
                if capital_usage > 0.9:
                    print(f"警告：总资金使用率过高 ({capital_usage:.1%})")
                    
                if max_single_grid_loss < -0.1:  # 单网格亏损超过10%
                    print(f"警告：网格 {max_loss_grid:.2f} 亏损过大 ({max_single_grid_loss:.1%})")
                    
                if total_profit_ratio < -0.08:  # 总亏损超过8%
                    print(f"警告：总亏损过大 ({total_profit_ratio:.1%})")
                    
                # 打印状态
                print(f"\n总体状况: 市值 {total_value:.0f} / 成本 {total_cost:.0f} / "
                      f"盈亏 {total_profit_ratio:.1%}")
                
            return True
                
        except Exception as e:
            print(f"风险控制检查失败: {str(e)}")
            return False

    def handle_data(self):
        """主循环处理"""
        try:
            current_time = self._get_current_time()
            if not current_time:
                return
                
            # 获取市场数据
            market_data = self._get_market_data()
            if not market_data:
                return
                
            # 添加调试信息打印
            self._debug_market_status(market_data)
                
            # 分析市场状况
            market_condition = self._analyze_market_condition()
            
            # 风险控制检查
            if not self._check_risk_control():
                print("风险控制检查未通过，暂停交易")
                return
                
            # 网格初始化或重置检查
            if not self.is_initialized:
                self._initialize_grids(market_data['latest_price'])
                self.is_initialized = True
            elif self._should_reset_grid(market_data['latest_price']):
                if self.total_position == 0:
                    self._initialize_grids(market_data['latest_price'])
                        
            # 更新网格状态
            if self.total_position > 0:
                self._monitor_grid_status()
            
            # 执行交易逻辑
            self._execute_trades(market_data)
            
            # 更新每日统计
            self._update_daily_stats()
            
            # 验证总持仓 20241109
            self._verify_total_position()
                
        except Exception as e:
            print(f"主循环执行错误: {str(e)}")
            import traceback
            print(traceback.format_exc())
            
    def _find_suitable_grid(self, price):
        """改进的网格匹配逻辑"""
        try:
            if not self.grid_prices:
                return None
                
            # 找到最接近的网格价格
            closest_grid = None
            min_distance = float('inf')
            
            for grid_price in self.grid_prices:
                distance = abs(price - grid_price)
                min_distance = min(min_distance, distance)
                if distance == min_distance:  # 使用moomoo支持的min函数语法
                    closest_grid = grid_price
                    
            if closest_grid:
                # 放宽偏离度限制到5%
                deviation = min_distance / closest_grid
                if deviation <= 0.05:  # 允许最大5%的偏离
                    return closest_grid
                else:
                    # 如果偏离度太大，动态创建新网格
                    new_grid = int(price * 10) / 10  # 取整到0.1
                    self.grid_prices.append(new_grid)
                    self.positions[new_grid] = 0
                    self.position_records[new_grid] = {
                        'positions': [],
                        'total_quantity': 0,
                        'average_cost': 0,
                        'last_trade_time': 0,
                        'last_trade_price': 0
                    }
                    self.last_trade_time[new_grid] = 0
                    print(f"创建新网格价格: {new_grid}")
                    return new_grid
                    
            print(f"价格 {price} 未找到匹配的网格（最近网格: {closest_grid}, 偏离度: {(min_distance/closest_grid if closest_grid else 0):.2%})")
            return None
                
        except Exception as e:
            print(f"查找合适网格失败: {str(e)}")
            return None

    def _monitor_grid_status(self):
        """改进的网格状态监控函数"""
        try:
            print("\n========== 网格状态监控 ==========")
            
            active_grids = []
            latest_price = current_price(self.stock)
            current_time = self._get_current_time()
            current_date = current_time.date() if current_time else None
                
            for grid_price, record in self.position_records.items():
                if record['total_quantity'] > 0:  # 有效持仓
                    market_value = record['total_quantity'] * latest_price
                    cost_value = record['total_quantity'] * record['average_cost']
                    profit = market_value - cost_value
                    profit_ratio = profit / cost_value if cost_value > 0 else 0
                        
                    grid_info = {
                        'price': grid_price,
                        'quantity': record['total_quantity'],
                        'avg_cost': record['average_cost'],
                        'market_value': market_value,
                        'profit': profit,
                        'profit_ratio': profit_ratio,
                        'daily_trades': record['daily_trade_count'].get(current_date, 0) if current_date else 0,
                        'total_trades': record['total_trades']
                    }
                    active_grids.append(grid_info)
                
            if active_grids:
                print("\n活跃网格状态:")
                for grid in active_grids:
                    print(f"网格 {grid['price']:.2f}: "
                          f"持仓 {grid['quantity']} 股, "
                          f"均价 {grid['avg_cost']:.2f}, "
                          f"市值 {grid['market_value']:.2f}, "
                          f"盈亏 {grid['profit']:.2f} "
                          f"({grid['profit_ratio']:.2%})")
                    print(f"今日交易次数: {grid['daily_trades']}")
                    print(f"累计交易次数: {grid['total_trades']}")
            else:
                print("\n当前无活跃网格")
                    
            # 计算网格利用率
            total_grids = len(self.grid_prices)
            used_grids = len(active_grids)
            print(f"\n网格利用情况:")
            print(f"总网格数: {total_grids}")
            print(f"使用网格数: {used_grids}")
            print(f"网格利用率: {(used_grids/total_grids*100 if total_grids > 0 else 0):.1f}%")
                
        except Exception as e:
            print(f"监控网格状态失败: {str(e)}")
            print(traceback.format_exc())
            
    def on_terminate(self):
        """策略终止处理"""
        try:
            print("\n策略终止处理...")
            
            # 计算最终统计
            final_stats = self._calculate_trade_stats()
            if final_stats:
                print("\n交易统计:")
                print(f"总交易次数: {final_stats['trade_count']}")
                print(f"买入次数: {final_stats['buy_count']}")
                print(f"卖出次数: {final_stats['sell_count']}")
                print(f"总收益: {final_stats['total_profit']:.2f}")
                print(f"胜率: {final_stats['win_rate']:.2%}")
                if 'avg_holding_time' in final_stats:
                    print(f"平均持仓时间: {final_stats['avg_holding_time']:.1f}小时")
            
            # 生成最终报告
            self._generate_final_report()
            
        except Exception as e:
            print(f"策略终止处理失败: {str(e)}")
            
    def _calculate_trade_stats(self):
        """计算详细的交易统计（修正min/max语法）"""
        try:
            stats = {
                'trade_count': len(self.trade_history),
                'buy_count': len([t for t in self.trade_history if t['type'] == '买入']),
                'sell_count': len([t for t in self.trade_history if t['type'] == '卖出']),
                'total_profit': self.total_profit,
                'win_count': self.win_count
            }
            
            if stats['sell_count'] > 0:
                stats['win_rate'] = self.win_count / stats['sell_count']
            else:
                stats['win_rate'] = 0
                
            # 计算平均持仓时间
            holding_times = []
            buy_records = {}
            
            for trade in self.trade_history:
                if trade['type'] == '买入':
                    grid_key = f"{trade['grid_price']}_{trade['quantity']}"
                    buy_records[grid_key] = trade['timestamp']
                elif trade['type'] == '卖出':
                    grid_key = f"{trade['grid_price']}_{trade['quantity']}"
                    if grid_key in buy_records:
                        buy_time = buy_records[grid_key]
                        holding_time = (trade['timestamp'] - buy_time).total_seconds() / 3600
                        holding_times.append(holding_time)
            
            if holding_times:
                stats['avg_holding_time'] = sum(holding_times) / len(holding_times)
                
                # 修正min/max使用
                min_time = holding_times[0]
                max_time = holding_times[0]
                for time in holding_times[1:]:
                    min_time = min(min_time, time)
                    max_time = max(max_time, time)
                    
                stats['min_holding_time'] = min_time
                stats['max_holding_time'] = max_time
            
            return stats
            
        except Exception as e:
            print(f"计算交易统计失败: {str(e)}")
            return None

    def _calculate_volatility(self):
        """计算波动率"""
        try:
            # 获取最近20日收盘价
            prices = []
            for i in range(1, 21):
                price = ma(self.stock, period=1, bar_type=BarType.D1, 
                          data_type=DataType.CLOSE, select=i)
                if price:
                    prices.append(price)
                    
            if len(prices) < 2:
                return None
                
            # 计算日收益率波动
            returns = []
            for i in range(len(prices)-1):
                if prices[i+1] != 0:  # 避免除以零
                    ret = (prices[i] - prices[i+1]) / prices[i+1]
                    returns.append(abs(ret))
                    
            if not returns:
                return None
                
            # 计算平均波动率
            avg_volatility = sum(returns) / len(returns)
            
            # 年化处理（假设一年250个交易日）
            annualized_volatility = avg_volatility * (250 ** 0.5)
            
            return annualized_volatility
            
        except Exception as e:
            print(f"计算波动率失败: {str(e)}")
            return None

    def _format_price(self, price):
        """格式化价格到指定精度"""
        try:
            if price is None:
                return None
                
            # 使用乘除法实现保留1位小数
            return int(price * 10) / 10  # 先乘10转为整数，再除以10得到1位小数
                
        except Exception as e:
            print(f"价格格式化失败: {str(e)}")
            return None

    def _get_current_time(self):
        """获取当前时间"""
        try:
            return device_time(TimeZone.DEVICE_TIME_ZONE)
        except Exception as e:
            print(f"获取当前时间失败: {str(e)}")
            return None

    def _update_daily_stats(self):
        """更新每日统计"""
        try:
            current_time = self._get_current_time()
            if not current_time:
                return
            
            # 获取当日交易记录
            today_trades = [t for t in self.trade_history 
                           if t['timestamp'].date() == current_time.date()]
            
            # 计算当日统计数据
            daily_stats = {
                'trade_count': len(today_trades),
                'buy_count': len([t for t in today_trades if t['type'] == '买入']),
                'sell_count': len([t for t in today_trades if t['type'] == '卖出']),
                'buy_volume': sum(t['quantity'] for t in today_trades if t['type'] == '买入'),
                'sell_volume': sum(t['quantity'] for t in today_trades if t['type'] == '卖出'),
                'profit': sum(t.get('profit', 0) for t in today_trades if t['type'] == '卖出')
            }
            
            # 计算成功率
            if daily_stats['sell_count'] > 0:
                profit_trades = len([t for t in today_trades 
                                   if t['type'] == '卖出' and t.get('profit', 0) > 0])
                daily_stats['success_rate'] = profit_trades / daily_stats['sell_count']
            else:
                daily_stats['success_rate'] = 0
                
            # 打印统计信息
            print("\n每日统计:")
            print(f"交易次数: {daily_stats['trade_count']}")
            print(f"买入次数: {daily_stats['buy_count']}")
            print(f"卖出次数: {daily_stats['sell_count']}")
            print(f"买入量: {daily_stats['buy_volume']}")
            print(f"卖出量: {daily_stats['sell_volume']}")
            print(f"当日收益: {daily_stats['profit']:.2f}")
            if daily_stats['sell_count'] > 0:
                print(f"成功率: {daily_stats['success_rate']:.2%}")
            
        except Exception as e:
            print(f"更新每日统计失败: {str(e)}")
            
    def _generate_final_report(self):
        """生成最终报告"""
        try:
            print("\n=========== 策略最终报告 ===========")
            
            # 获取最新市场数据
            latest_price = current_price(self.stock)
            if latest_price is None:
                return
                
            # 计算当前持仓市值
            total_value = 0
            total_cost = 0
            unrealized_profit = 0
            
            for grid_price, record in self.position_records.items():
                if record['total_quantity'] > 0:
                    position_value = record['total_quantity'] * latest_price
                    position_total_cost = record['total_quantity'] * record['average_cost']  # 修改变量名
                    total_value += position_value
                    total_cost += position_total_cost
                    unrealized_profit += (position_value - position_total_cost)
            
            # 计算整体收益
            total_realized_profit = sum(t.get('profit', 0) for t in self.trade_history)
            total_profit = total_realized_profit + unrealized_profit
            
            # 计算收益率
            if self.initial_capital > 0:
                return_rate = total_profit / self.initial_capital * 100
            else:
                return_rate = 0
                
            # 计算交易统计
            trade_stats = self._calculate_trade_stats()
            
            # 输出报告
            print("\n资金状况:")
            print(f"初始资金: {self.initial_capital:.2f}")
            print(f"当前市值: {total_value:.2f}")
            print(f"持仓成本: {total_cost:.2f}")
            print(f"未实现盈亏: {unrealized_profit:.2f}")
            print(f"已实现盈亏: {total_realized_profit:.2f}")
            print(f"总收益: {total_profit:.2f}")
            print(f"收益率: {return_rate:.2f}%")
            
            if trade_stats:
                print(f"\n交易统计:")
                print(f"总交易次数: {trade_stats['trade_count']}")
                print(f"买入次数: {trade_stats['buy_count']}")
                print(f"卖出次数: {trade_stats['sell_count']}")
                print(f"胜率: {trade_stats.get('win_rate', 0):.2%}")
                if 'avg_holding_time' in trade_stats:
                    print(f"平均持仓时间: {trade_stats['avg_holding_time']:.1f}小时")
                    print(f"最短持仓时间: {trade_stats['min_holding_time']:.1f}小时")
                    print(f"最长持仓时间: {trade_stats['max_holding_time']:.1f}小时")
            
            # 输出风险指标
            if total_value > 0:
                max_drawdown = self._calculate_max_drawdown()
                if max_drawdown is not None:
                    print(f"\n风险指标:")
                    print(f"最大回撤: {max_drawdown:.2%}")
            
            print("=====================================")
            
        except Exception as e:
            print(f"生成最终报告失败: {str(e)}")

    def _get_ma_values(self):
        """获取MA指标值"""
        try:
            # 使用moomoo API获取MA值
            ma_values = {
                'ma5': ma(self.stock, period=5, bar_type=BarType.D1, 
                         data_type=DataType.CLOSE, select=1),
                'ma10': ma(self.stock, period=10, bar_type=BarType.D1, 
                          data_type=DataType.CLOSE, select=1),
                'ma20': ma(self.stock, period=20, bar_type=BarType.D1, 
                          data_type=DataType.CLOSE, select=1)
            }
            
            # 格式化MA值
            formatted_ma = {}
            for key, value in ma_values.items():
                if value is not None:
                    formatted_ma[key] = self._format_price(value)
                else:
                    formatted_ma[key] = None
                    
            return formatted_ma
            
        except Exception as e:
            print(f"获取MA值失败: {str(e)}")
            return None

    def _calculate_max_drawdown(self):
        """计算最大回撤"""
        try:
            if not self.trade_history:
                return None

            # 计算每日资金曲线
            daily_values = []
            current_date = None
            current_value = self.initial_capital

            # 对交易记录按时间排序
            sorted_trades = sorted(self.trade_history, key=lambda x: x['timestamp'])

            for trade in sorted_trades:
                trade_date = trade['timestamp'].date()
                
                # 新的交易日
                if trade_date != current_date:
                    if current_date is not None:
                        daily_values.append(current_value)
                    current_date = trade_date

                # 更新当前价值
                if trade['type'] == '买入':
                    current_value -= trade['price'] * trade['quantity']
                else:  # 卖出
                    current_value += trade['price'] * trade['quantity']
                    if 'profit' in trade:
                        current_value += trade['profit']

            # 添加最后一天的价值
            if current_date is not None:
                daily_values.append(current_value)

            if not daily_values:
                return None

            # 计算最大回撤
            max_drawdown = 0
            peak = daily_values[0]

            for value in daily_values[1:]:
                if value > peak:
                    peak = value
                else:
                    drawdown = (peak - value) / peak
                    max_drawdown = max(max_drawdown, drawdown)

            return max_drawdown

        except Exception as e:
            print(f"计算最大回撤失败: {str(e)}")
            return None
            
    def _get_market_data(self):
        """获取市场数据"""
        try:
            # 获取最新价格
            latest_price = current_price(symbol=self.stock)
            if latest_price is None:
                print("获取最新价格失败")
                return None
                
            # 获取MA值
            ma5 = ma(symbol=self.stock, period=5, bar_type=BarType.D1, 
                    data_type=DataType.CLOSE, select=1)
            ma10 = ma(symbol=self.stock, period=10, bar_type=BarType.D1, 
                     data_type=DataType.CLOSE, select=1)
            ma20 = ma(symbol=self.stock, period=20, bar_type=BarType.D1, 
                     data_type=DataType.CLOSE, select=1)
                     
            # 获取最新成交量
            volume = ma(symbol=self.stock, period=1, bar_type=BarType.D1,
                       data_type=DataType.VOLUME, select=1)
                       
            # 格式化价格数据
            formatted_data = {
                'latest_price': self._format_price(latest_price),
                'ma5': self._format_price(ma5),
                'ma10': self._format_price(ma10),
                'ma20': self._format_price(ma20),
                'volume': volume,
                'timestamp': self._get_current_time()
            }
            
            # 计算波动率
            volatility = self._calculate_volatility()
            if volatility is not None:
                formatted_data['volatility'] = volatility
            
            # 计算价格相对MA的位置
            if ma5 and ma10 and ma20:
                if latest_price > ma5:
                    formatted_data['price_position'] = "高于MA5"
                elif latest_price < ma20:
                    formatted_data['price_position'] = "低于MA20"
                else:
                    formatted_data['price_position'] = "区间内"
                    
                # 计算MA趋势
                if ma5 > ma10 > ma20:
                    formatted_data['ma_trend'] = "上升"
                elif ma5 < ma10 < ma20:
                    formatted_data['ma_trend'] = "下降"
                else:
                    formatted_data['ma_trend'] = "震荡"
            
            return formatted_data
            
        except Exception as e:
            print(f"获取市场数据失败: {str(e)}")
            return None
            
    def place_buy_order(self, latest_price, grid_price, quantity):
        """执行买入订单"""
        try:
            buy_price = self._format_price(latest_price)
            
            # 使用moomoo的place_order函数下单
            order_id = place_limit(
                symbol=self.stock,
                price=buy_price,
                qty=quantity,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                current_time = self._get_current_time()
                self._update_position_records(grid_price, buy_price, quantity, current_time)
                self.positions[grid_price] = self.positions.get(grid_price, 0) + quantity
                self.total_position += quantity
                self.last_trade_time[grid_price] = current_time
                
                trade_record = {
                    'order_id': order_id,
                    'type': '买入',
                    'price': buy_price,
                    'quantity': quantity,
                    'grid_price': grid_price,
                    'timestamp': current_time,
                    'status': '全部成交'
                }
                self.trade_history.append(trade_record)
                self._log_trade_details(trade_record)
                
            return order_id
            
        except Exception as e:
            print(f"买入订单执行失败: {str(e)}")
            return None

    def place_sell_order(self, latest_price, grid_price, quantity):
        """执行卖出订单"""
        try:
            sell_price = self._format_price(latest_price)
            
            # 获取网格的持仓记录
            grid_record = self.position_records.get(grid_price)
            if not grid_record:
                print(f"未找到网格 {grid_price} 的持仓记录")
                return None
                
            average_cost = grid_record['average_cost']
            
            # 下单
            order_id = place_limit(
                symbol=self.stock,
                price=sell_price,
                qty=quantity,
                side=OrderSide.SELL,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                current_time = self._get_current_time()
                
                # 计算收益
                profit = (sell_price - average_cost) * quantity
                profit_ratio = (sell_price - average_cost) / average_cost
                
                # 更新持仓记录
                self._update_position_after_sell(grid_price, quantity, sell_price, current_time)
                
                # 更新基本持仓统计
                self.positions[grid_price] = self.positions.get(grid_price, 0) - quantity
                self.total_position -= quantity
                self.last_trade_time[grid_price] = current_time
                
                # 更新收益统计
                self.total_profit += profit
                if profit > 0:
                    self.win_count += 1
                
                # 记录交易历史
                trade_record = {
                    'order_id': order_id,
                    'type': '卖出',
                    'price': sell_price,
                    'quantity': quantity,
                    'grid_price': grid_price,
                    'profit': profit,
                    'profit_ratio': profit_ratio,
                    'timestamp': current_time,
                    'status': '全部成交',
                    'cost_price': average_cost
                }
                self.trade_history.append(trade_record)
                
                self._log_trade_details(trade_record)
                
            return order_id
            
        except Exception as e:
            print(f"卖出订单执行失败: {str(e)}")
            return None
            
    def _log_trade_details(self, trade):
        """记录交易详情"""
        try:
            if trade['type'] == '买入':
                print(f"买入: {trade['quantity']}股 @ {trade['price']:.2f} [网格:{trade['grid_price']:.2f}]")
                
                # 记录网格相关信息
                grid_record = self.position_records.get(trade['grid_price'])
                if grid_record:
                    print(f"当前网格持仓: {grid_record['total_quantity']} 股")
                    print(f"平均成本: {grid_record['average_cost']:.2f}")
                    print(f"总持仓: {self.total_position} 股")
                    
            else:  # 卖出
                profit_amount = trade['profit']
                profit_ratio = trade['profit_ratio']
                print(f"卖出: {trade['quantity']}股 @ {trade['price']:.2f} "
                      f"[网格:{trade['grid_price']:.2f}] "
                      f"收益: {profit_amount:.2f} ({profit_ratio:.2%})")
                      
                # 记录结算后的网格信息
                grid_record = self.position_records.get(trade['grid_price'])
                if grid_record:
                    print(f"网格剩余持仓: {grid_record['total_quantity']} 股")
                    if grid_record['total_quantity'] > 0:
                        print(f"剩余均价: {grid_record['average_cost']:.2f}")
                    print(f"总持仓: {self.total_position} 股")
            
            # 记录当前资金使用情况
            latest_price = current_price(self.stock)
            if latest_price:
                total_value = self.total_position * latest_price
                capital_usage = total_value / self.initial_capital
                print(f"当前资金使用率: {capital_usage:.1%}")
                
        except Exception as e:
            print(f"记录交易详情失败: {str(e)}")

    def _log_grid_status(self, grid_price):
        """记录网格状态"""
        try:
            print(f"\n网格 {grid_price:.2f} 状态:")
            record = self.position_records.get(grid_price)
            if not record:
                print("无持仓记录")
                return
                
            latest_price = current_price(self.stock)
            if latest_price:
                market_value = record['total_quantity'] * latest_price
                cost_value = record['total_quantity'] * record['average_cost']
                unrealized_profit = market_value - cost_value
                unrealized_profit_ratio = unrealized_profit / cost_value if cost_value != 0 else 0
                
                print(f"持仓数量: {record['total_quantity']} 股")
                print(f"平均成本: {record['average_cost']:.2f}")
                print(f"最新价格: {latest_price:.2f}")
                print(f"市值: {market_value:.2f}")
                print(f"浮动盈亏: {unrealized_profit:.2f} ({unrealized_profit_ratio:.2%})")
                
        except Exception as e:
            print(f"记录网格状态失败: {str(e)}")

    def _log_trade_summary(self):
        """记录交易汇总信息"""
        try:
            print("\n========== 交易汇总 ==========")
            
            # 计算基本统计
            total_trades = len(self.trade_history)
            buy_trades = len([t for t in self.trade_history if t['type'] == '买入'])
            sell_trades = len([t for t in self.trade_history if t['type'] == '卖出'])
            
            print(f"总交易次数: {total_trades}")
            print(f"买入次数: {buy_trades}")
            print(f"卖出次数: {sell_trades}")
            
            # 计算盈亏统计
            if sell_trades > 0:
                win_rate = self.win_count / sell_trades
                print(f"盈利次数: {self.win_count}")
                print(f"胜率: {win_rate:.2%}")
                
            # 计算当前持仓盈亏
            latest_price = current_price(self.stock)
            if latest_price and self.total_position > 0:
                total_cost = sum(record['average_cost'] * record['total_quantity'] 
                               for record in self.position_records.values())
                total_value = self.total_position * latest_price
                unrealized_profit = total_value - total_cost
                
                print(f"\n当前持仓: {self.total_position} 股")
                print(f"持仓市值: {total_value:.2f}")
                print(f"持仓成本: {total_cost:.2f}")
                print(f"浮动盈亏: {unrealized_profit:.2f}")
                print(f"资金使用率: {(total_value/self.initial_capital):.1%}")
                
            print("==============================")
            
        except Exception as e:
            print(f"记录交易汇总失败: {str(e)}")
            
    def _debug_market_status(self, market_data):
        """用于调试的市场状态打印函数"""
        try:
            print("\n========== 市场状态调试 ==========")
            print(f"时间: {self._get_current_time()}")
            print(f"最新价格: {market_data.get('latest_price')}")
            print(f"MA5: {market_data.get('ma5')}")
            print(f"总持仓: {self.total_position}")
            print(f"活跃网格数: {len([p for p in self.positions.values() if p > 0])}")
            print("当前网格状态:")
            for grid_price in sorted(self.grid_prices):
                pos = self.positions.get(grid_price, 0)
                if pos > 0:
                    print(f"网格 {grid_price}: 持仓 {pos}")
            print("===================================")
        except Exception as e:
            print(f"打印调试信息失败: {str(e)}")
            
    def _calculate_dynamic_position_limit(self, grid_price, latest_price):
        """动态计算网格持仓上限20241109"""
        try:
            # 基础限制
            base_limit = self.position_limit

            # 价格因子：价格越低，允许持仓越多
            price_factor = min(2.0, max(0.5, 20/latest_price))

            # 资金使用率因子
            total_value = self.total_position * latest_price
            capital_usage = total_value / self.initial_capital
            capital_factor = min(1.5, max(0.5, 1 - capital_usage))

            # 波动率因子
            volatility = self._calculate_volatility()
            volatility_factor = 1.0
            if volatility:
                volatility_factor = min(1.5, max(0.5, 1 - volatility))

            # 趋势因子
            trend_factor = 1.0
            ma_values = self._get_ma_values()
            if ma_values and all(v is not None for v in ma_values.values()):
                if latest_price > ma_values['ma5'] > ma_values['ma10']:
                    trend_factor = 1.2  # 上升趋势
                elif latest_price < ma_values['ma5'] < ma_values['ma10']:
                    trend_factor = 0.8  # 下降趋势

            # 计算动态限制
            dynamic_limit = int(base_limit * price_factor * capital_factor * 
                              volatility_factor * trend_factor)

            # 确保不低于最小交易单位
            min_limit = max(self.min_order_quantity * 2, 50)
            dynamic_limit = max(dynamic_limit, min_limit)

            # 确保为最小交易单位的整数倍
            dynamic_limit = (dynamic_limit // self.min_order_quantity) * self.min_order_quantity

            # 打印计算过程
            print(f"\n网格 {grid_price} 动态持仓限制计算:")
            print(f"基础限制: {base_limit}")
            print(f"价格因子: {price_factor:.2f}")
            print(f"资金因子: {capital_factor:.2f}")
            print(f"波动率因子: {volatility_factor:.2f}")
            print(f"趋势因子: {trend_factor:.2f}")
            print(f"最终限制: {dynamic_limit}")

            return dynamic_limit

        except Exception as e:
            print(f"计算动态持仓限制失败: {str(e)}")
            return self.position_limit
            
    def _verify_total_position(self):
        """完整的持仓验证和修正方法20241109"""
        try:
            # 计算三个来源的持仓数量
            positions_total = sum(self.positions.values())
            records_total = sum(record['total_quantity'] 
                              for record in self.position_records.values())
            positions_detail_total = sum(
                sum(p['remaining'] for p in record['positions'])
                for record in self.position_records.values()
            )

            # 检查是否一致
            if positions_total != records_total or records_total != positions_detail_total:
                print("\n持仓不一致检测:")
                print(f"positions总计: {positions_total}")
                print(f"records总计: {records_total}")
                print(f"position详细总计: {positions_detail_total}")

                # 详细的网格持仓信息
                for grid_price in sorted(self.position_records.keys()):
                    record = self.position_records[grid_price]
                    grid_total = record['total_quantity']
                    positions_sum = sum(p['remaining'] for p in record['positions'])
                    if grid_total != positions_sum:
                        print(f"\n网格 {grid_price} 持仓不一致:")
                        print(f"记录总量: {grid_total}")
                        print(f"实际总量: {positions_sum}")

                # 以position详细记录为准进行修正
                for grid_price, record in self.position_records.items():
                    correct_quantity = sum(p['remaining'] for p in record['positions'])
                    record['total_quantity'] = correct_quantity
                    self.positions[grid_price] = correct_quantity

                # 更新总持仓
                self.total_position = positions_detail_total

                print("\n持仓已修正:")
                print(f"修正后总持仓: {self.total_position}")

            return all([
                positions_total == records_total,
                records_total == positions_detail_total,
                self.total_position == positions_detail_total
            ])

        except Exception as e:
            print(f"验证并修正持仓失败: {str(e)}")
            print(traceback.format_exc())
            return False
            
    def _safe_update_positions(self, operation_type='unknown'):
        """安全的持仓更新和验证"""
        try:
            if not self._verify_total_position():
                print(f"警告: 在{operation_type}操作后发现持仓不一致")
                # 可以添加其他处理逻辑，如发送通知等
                return False
            return True
        except Exception as e:
            print(f"持仓验证失败: {str(e)}")
            return False