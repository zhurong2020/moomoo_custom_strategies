class Strategy(StrategyBase):
    #Moomoo Fields Inspector(Moomoo字段检测器)
    def initialize(self):
        """初始化策略"""
        self.trigger_symbols()
        self.custom_indicator()
        self.global_variables()
            
    def trigger_symbols(self):
        """定义交易标的"""
        self.test_symbol = declare_trig_symbol()
            
    def custom_indicator(self):
        """设置技术指标"""
        pass
        
    def global_variables(self):
        """定义全局变量"""
        # 初始化测试状态
        self.test_states = {
            'buy_tested': False,
            'sell_tested': False,
            'test_complete': False
        }
        
        # 订单记录
        self.test_orders = {
            'BUY': {
                'order_id': None,
                'status_flow': [],
                'execution_time': None,
                'execution_price': None
            },
            'SELL': {
                'order_id': None,
                'status_flow': [],
                'execution_time': None,
                'execution_price': None
            }
        }

    def handle_data(self):
        """主要测试逻辑"""
        try:
            if self.test_states['test_complete']:
                return
                
            # 获取当前价格
            latest_price = current_price(self.test_symbol)
            if latest_price is None:
                return
                
            # 按顺序执行测试
            if not self.test_states['buy_tested']:
                self._execute_buy_test(latest_price)
            elif not self.test_states['sell_tested']:
                self._execute_sell_test(latest_price)
            else:
                self._print_field_report()
                self.test_states['test_complete'] = True
                
        except Exception as e:
            print(f"测试执行失败: {str(e)}")
            
    def _execute_buy_test(self, price):
        """执行买入测试"""
        try:
            order_id = place_limit(
                symbol=self.test_symbol,
                price=price,
                qty=100,
                side=OrderSide.BUY,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                self.test_orders['BUY']['order_id'] = order_id
                self.test_orders['BUY']['execution_time'] = device_time(TimeZone.DEVICE_TIME_ZONE)
                self.test_orders['BUY']['execution_price'] = price
                self.test_states['buy_tested'] = True
                
        except Exception as e:
            print(f"买入测试失败: {str(e)}")
            
    def _execute_sell_test(self, price):
        """执行卖出测试"""
        try:
            order_id = place_limit(
                symbol=self.test_symbol,
                price=price,
                qty=100,
                side=OrderSide.SELL,
                time_in_force=TimeInForce.DAY
            )
            
            if order_id:
                self.test_orders['SELL']['order_id'] = order_id
                self.test_orders['SELL']['execution_time'] = device_time(TimeZone.DEVICE_TIME_ZONE)
                self.test_orders['SELL']['execution_price'] = price
                self.test_states['sell_tested'] = True
                
        except Exception as e:
            print(f"卖出测试失败: {str(e)}")
            
    def _print_field_report(self):
        """打印字段检测报告"""
        print("\n========== Moomoo API 字段检测报告 ==========")
        print("内容:")
        print("1. 字段集合检验.")
        print("内容: 初期字段检验: 0.")
        print("内容: 实际字段检验: 0.")
        print("内容:")
        print("2. 子段分类.")
        print("内容:")
        print("basic类字段.")
        print("内容:    标的代码 (示例: US.MARA),")
        print("内容:    标的名称 (示例: MARA Holdings),")
        print("内容:    交易方向 (示例: 买入/卖出),")
        print("内容:    订单类型 (示例: 限价单),")
        print("内容:    订单状态 (示例: 等待提交/已提交/正常/全部成交),")
        print("内容:")
        print("quantity类字段.")
        print("内容:    订单数量 (示例: 100),")
        print("内容:    成交数量 (示例: 100),")
        print("内容:")
        print("price类字段.")
        print("内容:    订单价格 (示例: 18.40),")
        print("内容:    成交价格 (示例: 18.40),")
        print("内容:")
        print("time类字段.")
        print("内容:    委托时间 (示例: 2024/10/24 09:30:00),")
        print("内容:    成交时间 (示例: 2024/10/24 09:30:00),")
        print("内容:")
        print("additional类字段.")
        print("内容:    订单期限 (示例: 当日有效),")
        print("内容:    订单编号 (示例: FH000000000000001),")
        print("内容:")
        print("4. 状态流转记录.")
        print("内容:")
        print("BUY订单状态流转:")
        if self.test_orders['BUY']['execution_time']:
            print(f"内容:    - {self.test_orders['BUY']['execution_time'].strftime('%Y/%m/%d %H:%M:%S')}: 已提交 @ {self.test_orders['BUY']['execution_price']},")
        print("内容:")
        print("SELL订单状态流转:")
        if self.test_orders['SELL']['execution_time']:
            print(f"内容:    - {self.test_orders['SELL']['execution_time'].strftime('%Y/%m/%d %H:%M:%S')}: 已提交 @ {self.test_orders['SELL']['execution_price']},")
        print("内容:")
        print("========== 报告结束 ==========")