class Strategy(StrategyBase):
    def initialize(self):
        self.trigger_symbols()
        self.global_variables()
        self.custom_indicator()
        print("策略初始化开始...")
        
    def trigger_symbols(self):
        self.stock = declare_trig_symbol()
        print("交易标的设置完成。")

    def custom_indicator(self):
        pass
        
    def global_variables(self):
        # 添加K线周期选择，使用INT类型
        self.kline_type = show_variable(0, GlobalType.INT)  # 0:M30, 1:H1, 2:H2
        self.min_order_quantity = show_variable(1, GlobalType.INT)
        
        # 将数值映射到K线类型
        self.kline_type_map = {
            0: ("M30", BarType.M30),
            1: ("H1", BarType.H1),
            2: ("H2", BarType.H2)
        }
        
        # 各类型K线第一根形成时间（相对开盘时间的分钟数）
        self.first_bar_offset = {
            0: 30,    # M30: 9:30 -> 10:00
            1: 60,    # H1:  9:30 -> 10:30
            2: 120    # H2:  9:30 -> 11:30
        }
        
        self.last_order_id = None
        self.is_order_pending = False
        
        kline_name = self.kline_type_map[self.kline_type][0]
        print("全局变量初始化完成。")
        print(f"K线类型: {kline_name}")
        print(f"最小下单数量: {self.min_order_quantity}")
        
    def is_trading_time(self, current_time):
        """判断当前是否为交易时间,且K线已经形成"""
        offset_minutes = self.first_bar_offset[self.kline_type]
        
        # 计算开盘后的分钟数
        market_open = current_time.replace(hour=9, minute=30, second=0, microsecond=0)
        minutes_from_open = (current_time - market_open).total_seconds() / 60
        
        # 检查是否已经形成了完整K线
        if minutes_from_open < offset_minutes:
            return False
                
        hour = current_time.hour
        minute = current_time.minute
        
        # 修改交易时间判断
        # 9:30开始到16:00结束,考虑K线形成时间
        trading_start = (hour == 10 and minute == 0)  # 第一根K线在10:00形成
        trading_period = (hour >= 10 and hour < 16) or (hour == 16 and minute == 0)  # 最后一根K线在16:00形成
        
        return trading_start or trading_period

    def handle_data(self):
        current_time = device_time(TimeZone.DEVICE_TIME_ZONE)
        
        if not self.is_trading_time(current_time):
            return
                
        if self.is_order_pending and self.last_order_id:
            status = order_status(self.last_order_id)
            if status == 'FILLED_ALL':
                self.is_order_pending = False
                self.last_order_id = None
            else:
                return
                
        try:
            # 根据设置的K线类型获取数据
            bar_type = self.kline_type_map[self.kline_type][1]
            kline_name = self.kline_type_map[self.kline_type][0]
            
            # 获取完整K线数据
            bar_open_price = bar_open(self.stock, bar_type, select=1)
            bar_high_price = bar_high(self.stock, bar_type, select=1)
            bar_low_price = bar_low(self.stock, bar_type, select=1)
            bar_close_price = bar_close(self.stock, bar_type, select=1)  # 添加收盘价
            
            print(f"""
    K线时间: {current_time.strftime('%Y-%m-%d %H:%M:%S')}
    K线类型: {kline_name}
    K线数据:
    - 开盘价: {bar_open_price}
    - 最高价: {bar_high_price}
    - 最低价: {bar_low_price}
    - 收盘价: {bar_close_price}
    """)
                
            # 使用K线收盘价进行下单
            if not self.is_order_pending:
                try:
                    order_id = place_limit(
                        symbol=self.stock,
                        price=bar_close_price,  # 使用K线收盘价而不是实时价格
                        qty=self.min_order_quantity,
                        side=OrderSide.BUY,
                        time_in_force=TimeInForce.DAY
                    )
                    
                    self.last_order_id = order_id
                    self.is_order_pending = True
                    
                    print(f"""
    下单信息:
    - 订单ID: {order_id}
    - 下单价格: {bar_close_price}
    - 下单数量: {self.min_order_quantity}
    - 下单时间: {current_time.strftime('%Y-%m-%d %H:%M:%S')}
    """)
                    
                except Exception as e:
                    print(f"下单失败: {str(e)}")
                    
        except Exception as e:
            print(f"数据获取失败: {str(e)}")