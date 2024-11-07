class Strategy(StrategyBase):
    # Moomoo Order Analyzer(Moomoo订单分析器)
    def initialize(self):
        """初始化策略"""
        try:
            print("[开始运行] 20241028Moomoo Order History Analyzer策略已开始回测。")
            print("内容: ======== 开始历史订单分析器 ========。")
            print("内容: 需正确初始化完成。")

            # 定义标准字段分类
            self.FIELD_CATEGORIES = {
                'basic': {
                    'code': '代码',
                    'name': '名称',
                    'status': '交易状态',
                    'direction': '方向',
                },
                'price': {
                    'order_price': '订单价格',
                    'filled_price': '成交价格',
                    'filled_avg_price': '已成交@均价',
                },
                'quantity': {
                    'order_quantity': '订单数量',
                    'filled_quantity': '成交数量',
                },
                'time': {
                    'order_time': '下单时间',
                    'filled_time': '成交时间',
                },
                'market': {
                    'market': '市场',
                    'currency': '币种',
                    'session': '时段',
                    'pre_market': '盘前竞价',
                },
                'fee': {
                    'trading_fee': '交易活动费',
                    'sec_fee': '证监会规费',
                    'total_fee': '合计费用',
                }
            }
            
            # 订单状态流转
            self.STATUS_FLOW = {
                'initial': '等待提交',    # 初始状态
                'submitted': '已提交',    # 提交订单后
                'normal': '正常',        # 交易所接受
                'filled': '全部成交'      # 最终成交
            }
            
            # 交易统计数据
            self.trade_stats = {
                'orders': [],                # 订单记录
                'total_orders': 0,           # 总订单数
                'total_buy_amount': 0.0,     # 总买入金额
                'total_sell_amount': 0.0,    # 总卖出金额
                'total_fees': 0.0,           # 总费用
                'symbols': set(),            # 交易标的
                'time_distribution': {},     # 时间分布
                'price_distribution': {},    # 价格分布
                'order_types': set(),        # 订单类型
                'execution_rate': {          # 成交率统计
                    'success': 0,            # 全部成交
                    'partial': 0,            # 部分成交
                    'pending': 0,            # 等待中
                    'cancelled': 0,          # 已撤销
                    'rejected': 0,           # 已拒绝
                    'other': 0               # 其他状态
                }
            }
            
            # 测试状态
            self.test_states = {
                'buy_tested': False,
                'sell_tested': False,
                'test_complete': False,
                'analyzed': False
            }
            
            # 测试订单跟踪
            self.test_orders = {
                'buy': {
                    'order_id': None,
                    'info': {},
                    'status_flow': []
                },
                'sell': {
                    'order_id': None,
                    'info': {},
                    'status_flow': []
                }
            }
            
            # 调用标准约定函数
            self.trigger_symbols()
            self.custom_indicator()
            self.global_variables()
            
            print("初始化完成")
            
        except Exception as e:
            print(f"初始化失败: {str(e)}")

    def trigger_symbols(self):
        """定义交易标的"""
        try:
            self.test_symbol = declare_trig_symbol()
            print(f"测试标的设置完成")
        except Exception as e:
            print(f"设置交易标的失败: {str(e)}")
            
    def custom_indicator(self):
        """设置技术指标"""
        pass
        
    def global_variables(self):
        """定义全局变量"""
        pass

    def handle_data(self):
        if self.test_states['test_complete']:
            return
            
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            
            # 执行测试流程    
            if not self.test_states['buy_tested']:
                print(f"内容: ======== 运行分析 {current_time.strftime('%Y-%m-%d %H:%M:%S-%H:00')} ========。")
                print("内容:")
                print("内容: 执行买入分析。")
                self._execute_buy_order(current_price(self.test_symbol))
            elif not self.test_states['sell_tested']:
                print(f"内容: ======== 运行分析 {current_time.strftime('%Y-%m-%d %H:%M:%S-%H:00')} ========。")
                print("内容:")
                print("内容: 执行卖出分析。")
                self._execute_sell_order(current_price(self.test_symbol))
            elif not self.test_states['analyzed']:
                self._analyze_orders()
                self._generate_report()
                self.test_states['test_complete'] = True
                
        except Exception as e:
            print(f"订单分析执行失败: {str(e)}")
            
            
    def _execute_buy_order(self, price):
        """执行买入订单"""
        try:
            print("\n执行买入测试:")
            
            # 设置价格 (保留两位小数)
            trade_price = float(int(price * 100)) / 100.0
            
            # 创建订单
            order_id = place_limit(
                symbol=self.test_symbol,
                price=trade_price,
                qty=100,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                self._record_order('buy', order_id, trade_price, OrderSide.BUY)
                self.test_states['buy_tested'] = True
                print(f"买入订单执行成功: {order_id} @ {trade_price}")
                
        except Exception as e:
            print(f"买入订单执行失败: {str(e)}")
            
    def _execute_sell_order(self, price):
        """执行卖出订单"""
        try:
            print("\n执行卖出测试:")
            
            # 设置价格 (保留两位小数)
            trade_price = float(int(price * 100)) / 100.0
            
            # 创建订单
            order_id = place_limit(
                symbol=self.test_symbol,
                price=trade_price,
                qty=100,
                side=OrderSide.SELL,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                self._record_order('sell', order_id, trade_price, OrderSide.SELL)
                self.test_states['sell_tested'] = True
                print(f"卖出订单执行成功: {order_id} @ {trade_price}")
                
        except Exception as e:
            print(f"卖出订单执行失败: {str(e)}")
            
    def _record_order(self, direction, order_id, price, side):
        """记录订单信息"""
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            formatted_time = current_time.strftime('%Y/%m/%d %H:%M:%S')
            
            # 创建订单基本信息
            order_info = {
                '代码': str(self.test_symbol),
                '名称': 'MARA Holdings',
                '交易状态': self.STATUS_FLOW['submitted'],
                '方向': '买入' if side == OrderSide.BUY else '卖出',
                '订单价格': str(price),
                '订单数量': '100',
                '已成交@均价': '',
                '下单时间': formatted_time,
                '订单类型': '限价单',
                '期限': '当日有效',
                '盘前竞价': '不允许',
                '时段': '盘中',
                '市场': '美国市场',
                '币种': '美元',
                '订单ID': order_id
            }
            
            # 添加费用信息（仅卖出订单）
            if side == OrderSide.SELL:
                order_info.update({
                    '交易活动费': '0.02',
                    '证监会规费': '0.05',
                    '合计费用': '0.07'
                })
            
            # 记录订单
            self.test_orders[direction]['order_id'] = order_id
            self.test_orders[direction]['info'] = order_info
            
            # 记录状态流转
            self.test_orders[direction]['status_flow'].append({
                'time': formatted_time,
                'status': self.STATUS_FLOW['submitted'],
                'price': price
            })
            
            # 更新统计数据
            self.trade_stats['orders'].append(order_info)
            self.trade_stats['total_orders'] += 1
            self.trade_stats['symbols'].add(str(self.test_symbol))
            self.trade_stats['order_types'].add('限价单')
            
        except Exception as e:
            print(f"记录订单信息失败: {str(e)}")
            
    def _update_order_status(self, direction, new_status, filled_price=None):
        """更新订单状态"""
        try:
            order = self.test_orders[direction]
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            formatted_time = current_time.strftime('%Y/%m/%d %H:%M:%S')
            
            # 更新状态
            order['info']['交易状态'] = new_status
            
            # 记录状态流转
            order['status_flow'].append({
                'time': formatted_time,
                'status': new_status,
                'price': filled_price if filled_price else float(order['info']['订单价格'])
            })
            
            # 成交时更新额外信息
            if new_status == self.STATUS_FLOW['filled'] and filled_price:
                # 更新成交信息
                order['info'].update({
                    '成交价格': str(filled_price),
                    '成交数量': '100',
                    '成交时间': formatted_time,
                    '成交金额': f"{filled_price * 100:.2f}"
                })
                
                # 更新统计数据
                self.trade_stats['execution_rate']['success'] += 1
                amount = filled_price * 100
                
                if direction == 'buy':
                    self.trade_stats['total_buy_amount'] += amount
                else:
                    self.trade_stats['total_sell_amount'] += amount
                    self.trade_stats['total_fees'] += float(order['info'].get('合计费用', 0))
                    
            print(f"\n订单状态更新 [{direction.upper()}]:")
            print(f"状态: {new_status}")
            print(f"时间: {formatted_time}")
            print(f"价格: {filled_price if filled_price else order['info']['订单价格']}")
            
        except Exception as e:
            print(f"更新订单状态失败: {str(e)}")
            
    def _analyze_orders(self):
        """分析订单执行情况"""
        try:
            print("\n分析订单执行情况...")
            
            # 更新订单状态
            for direction in ['buy', 'sell']:
                order = self.test_orders[direction]
                if order['order_id']:
                    # 模拟订单状态变化
                    self._update_order_status(direction, self.STATUS_FLOW['normal'])
                    self._update_order_status(
                        direction,
                        self.STATUS_FLOW['filled'],
                        float(order['info']['订单价格'])
                    )
            
            # 分析时间分布
            for order in self.trade_stats['orders']:
                if '下单时间' in order:
                    from datetime import datetime
                    time = datetime.strptime(order['下单时间'], '%Y/%m/%d %H:%M:%S')
                    hour = time.hour
                    self.trade_stats['time_distribution'][hour] = (
                        self.trade_stats['time_distribution'].get(hour, 0) + 1
                    )
            
            # 分析价格分布
            for order in self.trade_stats['orders']:
                if '成交价格' in order:
                    price = float(order['成交价格'])
                    price_range = int(price)
                    self.trade_stats['price_distribution'][price_range] = (
                        self.trade_stats['price_distribution'].get(price_range, 0) + 1
                    )
            
            self.test_states['analyzed'] = True
            
        except Exception as e:
            print(f"订单分析失败: {str(e)}")
            
    def _generate_report(self):
        """生成分析报告"""
        try:
            current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
            print("\n========== 订单分析报告 ==========")
            print(f"生成时间: {current_time.strftime('%Y/%m/%d %H:%M:%S')}")
            
            # 1. 交易概况
            print("\n1. 交易概况:")
            print(f"总订单数: {self.trade_stats['total_orders']}")
            print(f"交易标的: {', '.join(self.trade_stats['symbols'])}")
            print(f"订单类型: {', '.join(self.trade_stats['order_types'])}")
            print(f"总买入金额: ${self.trade_stats['total_buy_amount']:.2f}")
            print(f"总卖出金额: ${self.trade_stats['total_sell_amount']:.2f}")
            print(f"总手续费: ${self.trade_stats['total_fees']:.2f}")
            
            # 计算收益
            gross_profit = self.trade_stats['total_sell_amount'] - self.trade_stats['total_buy_amount']
            net_profit = gross_profit - self.trade_stats['total_fees']
            print(f"毛收益: ${gross_profit:.2f}")
            print(f"净收益: ${net_profit:.2f}")
            
            # 2. 成交统计
            print("\n2. 成交统计:")
            total_executions = sum(self.trade_stats['execution_rate'].values())
            if total_executions > 0:
                for status, count in self.trade_stats['execution_rate'].items():
                    if count > 0:
                        percentage = (count / total_executions * 100)
                        print(f"{status}: {count}笔 ({percentage:.1f}%)")
            
            # 3. 时间分布
            if self.trade_stats['time_distribution']:
                print("\n3. 交易时间分布:")
                for hour in sorted(self.trade_stats['time_distribution'].keys()):
                    count = self.trade_stats['time_distribution'][hour]
                    print(f"{hour:02d}:00 - {hour+1:02d}:00: {count}笔")
            
            # 4. 价格分布
            if self.trade_stats['price_distribution']:
                print("\n4. 价格分布:")
                for price in sorted(self.trade_stats['price_distribution'].keys()):
                    count = self.trade_stats['price_distribution'][price]
                    print(f"${price:.0f} - ${price+1:.0f}: {count}笔")
            
            # 5. 订单详情
            print("\n5. 订单详情:")
            for direction in ['buy', 'sell']:
                order = self.test_orders[direction]
                if order['order_id']:
                    print(f"\n{direction.upper()}订单:")
                    info = order['info']
                    print(f"订单ID: {info['订单ID']}")
                    print(f"状态: {info['交易状态']}")
                    print(f"价格: {info['订单价格']}")
                    print(f"数量: {info['订单数量']}")
                    if '成交价格' in info:
                        print(f"成交价格: {info['成交价格']}")
                        print(f"成交时间: {info['成交时间']}")
                        if direction == 'sell':
                            print(f"手续费: {info['合计费用']}")
            
            print("\n=================================")
            
        except Exception as e:
            print(f"生成报告失败: {str(e)}")