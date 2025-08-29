# 可自动化的期权策略设计文档

**版本**: 1.0
**日期**: 2025-08-29

## 1. 文档概述

本文档旨在为多种基于Moomoo平台的、可自动化的期权策略提供清晰、统一的需求与设计规范。它将作为后续策略开发工作的核心指导蓝图。

---

## 2. 策略一：滚轮策略 (The Wheel Strategy)

### 2.1. 策略概述

*   **目标**: 对用户指定的优质股票，进行长期的、自动化的“滚轮”期权交易，以产生现金流并降低潜在持股成本。
*   **核心逻辑**: 
    1.  **卖出看跌期权 (Sell Cash-Secured Puts)**: 在无持股时，持续卖出由现金担保的虚值(OTM)看跌期权。
    2.  **等待行权/到期**: 若期权到期作废，重复此过程。若被行权，则买入股票。
    3.  **卖出看涨期权 (Sell Covered Calls)**: 持有股票后，转为持续卖出虚值(OTM)的备兑看涨期权。
    4.  **等待行权/到期**: 若期权到期作废，重复此过程。若被行权，股票被卖出，回到现金状态，重新开始整个循环。
*   **市场观点**: 对标的长期温和看涨。

### 2.2. 自动化工作流

策略主要在 `SELLING_PUTS` 和 `SELLING_CALLS` 两个状态间切换。

*   **`SELLING_PUTS` 状态**: 
    1.  **进入条件**: `position_holding_qty()` == 0。
    2.  **选择合约**: 使用 `option_screener` 和 `option_delta` 寻找30-45天到期、Delta最接近 **-0.30** 的Put合约。
    3.  **下单**: 检查 `available_fund`，通过 `place_limit` 卖出该合约。
*   **`SELLING_CALLS` 状态**: 
    1.  **进入条件**: `position_holding_qty()` > 0。
    2.  **选择合约**: 使用 `option_screener` 和 `option_delta` 寻找30-45天到期、Delta最接近 **0.30** 的Call合约。
    3.  **下单**: 根据持股数，通过 `place_limit` 卖出相应手数的Call合约。

### 2.3. 关键参数配置

*   `target_underlying`: (string) 目标股票代码。
*   `contracts_to_sell`: (int) 每次卖出的合约数量。
*   `days_to_expiration_min`/`max`: (int) 到期日范围 (如 30-45)。
*   `put_target_delta`/`call_target_delta`: (float) 目标Delta值。
*   `profit_target_pct`: (float) 提前平仓的盈利目标百分比。

### 2.4. API依赖清单

`position_holding_qty`, `available_fund`, `option_screener`, `option_delta`, `option_strike_price`, `mid_price`, `place_limit`, `current_price` (期权价格)。

---

## 3. 策略二：铁鹰组合 (Iron Condor)

### 3.1. 策略概述

*   **目标**: 在股价区间震荡时，通过卖出期权组合来赚取权利金，并严格控制风险。
*   **核心逻辑**: 本质是同时卖出一个看涨期权价差（Bear Call Spread）和一个看跌期权价差（Bull Put Spread）。它由四条“腿”组成：
    1.  卖一个虚值Put (Sell OTM Put)
    2.  买一个更虚值的Put (Buy further OTM Put)
    3.  卖一个虚值Call (Sell OTM Call)
    4.  买一个更虚值的Call (Buy further OTM Call)
*   **市场观点**: 股价将在一个可预见的范围内横盘整理，或隐含波动率(IV)将下降。
*   **核心优势**: **风险和收益均在建仓时就已确定**。最大亏损被严格限定，非常适合自动化交易。

### 3.2. 自动化工作流

*   **入场 (Entry)**:
    1.  **选择到期日**: 使用 `option_screener` 筛选30-45天到期的期权。
    2.  **确定卖方合约 (Short Legs)**: 
        *   使用 `option_delta` 找到Delta最接近 **-0.15** 的Put合约，作为 `Sell Put` 的目标。
        *   使用 `option_delta` 找到Delta最接近 **0.15** 的Call合约，作为 `Sell Call` 的目标。
    3.  **确定买方合约 (Long Legs)**: 
        *   在 `Sell Put` 的行权价基础上，减去一个固定的“宽度”(`condor_width`)，确定 `Buy Put` 的行权价。
        *   在 `Sell Call` 的行权价基础上，加上一个固定的“宽度”(`condor_width`)，确定 `Buy Call` 的行权价。
    4.  **下单**: 分别通过 `place_limit` 提交这四个订单，构建完整的Iron Condor仓位。
*   **管理 (Management)**:
    *   监控整个组合的价值。当盈利达到最大理论盈利的50% (`profit_target_pct`) 时，提前平仓所有四条腿，锁定利润。
    *   当股价接近某一边卖出的行权价时，可考虑提前移仓或平仓以规避风险。

### 3.3. 关键参数配置

*   `target_underlying`: (string) 目标股票代码。
*   `days_to_expiration_min`/`max`: (int) 到期日范围。
*   `short_leg_delta`: (float) 卖方合约的目标Delta值 (例如 0.15)。
*   `condor_width`: (float) 两条腿之间的行权价宽度 (例如 $5 或 $10)。
*   `profit_target_pct`: (float) 提前平仓的盈利目标百分比。
*   `contracts_per_side`: (int) 每边交易的合约数量。

### 3.4. API依赖清单

与滚轮策略基本相同，额外需要更频繁地查询四条腿的 `current_price` 来计算组合的整体价值。

---

## 4. 风险与免责声明

*   **风险提示**: 所有期权策略均涉及风险。Iron Condor虽然风险可控，但在股价大幅突破预期范围时，依然会发生已计算好的最大亏损。
*   **免责声明**: 本自动化策略仅为交易执行工具，不构成任何投资建议。所有交易决策的风险由用户自行承担。