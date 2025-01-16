import os
from typing import Optional, Dict, Any
from datetime import datetime
from alpaca.trading.client import TradingClient
from alpaca.trading.requests import MarketOrderRequest, LimitOrderRequest
from alpaca.trading.enums import OrderSide, TimeInForce, OrderStatus as AlpacaOrderStatus
from alpaca.data.historical import StockHistoricalDataClient
from alpaca.data.requests import StockBarsRequest
from alpaca.data.timeframe import TimeFrame

class AlpacaService:
    def __init__(self, api_key: str = None, secret_key: str = None, paper: bool = True):
        """Initialize Alpaca API clients"""
        self.api_key = api_key or os.getenv('ALPACA_API_KEY')
        self.secret_key = secret_key or os.getenv('ALPACA_SECRET_KEY')
        self.paper = paper if api_key else os.getenv('ALPACA_PAPER', 'True').lower() == 'true'

        if not all([self.api_key, self.secret_key]):
            raise ValueError("Alpaca API keys not found")

        # Initialize trading client
        self.trading_client = TradingClient(self.api_key, self.secret_key, paper=self.paper)
        
        # Initialize data client
        self.data_client = StockHistoricalDataClient(self.api_key, self.secret_key)

    async def get_account(self) -> Dict[str, Any]:
        """Get account information"""
        account = self.trading_client.get_account()
        return {
            "id": account.id,
            "status": account.status,
            "currency": account.currency,
            "buying_power": float(account.buying_power),
            "cash": float(account.cash),
            "portfolio_value": float(account.portfolio_value),
            "pattern_day_trader": account.pattern_day_trader,
            "trading_blocked": account.trading_blocked,
            "transfers_blocked": account.transfers_blocked,
            "account_blocked": account.account_blocked,
            "created_at": account.created_at,
            "shorting_enabled": account.shorting_enabled,
            "long_market_value": float(account.long_market_value),
            "short_market_value": float(account.short_market_value),
            "equity": float(account.equity),
            "last_equity": float(account.last_equity),
            "multiplier": account.multiplier,
        }

    async def place_order(self, 
                         symbol: str,
                         qty: float,
                         side: str,
                         order_type: str,
                         limit_price: Optional[float] = None) -> Dict[str, Any]:
        """Place an order"""
        side = OrderSide.BUY if side.upper() == 'BUY' else OrderSide.SELL
        
        if order_type.upper() == 'MARKET':
            order_data = MarketOrderRequest(
                symbol=symbol,
                qty=qty,
                side=side,
                time_in_force=TimeInForce.DAY
            )
        else:  # LIMIT order
            if not limit_price:
                raise ValueError("Limit price is required for limit orders")
            order_data = LimitOrderRequest(
                symbol=symbol,
                qty=qty,
                side=side,
                time_in_force=TimeInForce.DAY,
                limit_price=limit_price
            )
        
        order = self.trading_client.submit_order(order_data)
        return {
            "order_id": order.id,
            "client_order_id": order.client_order_id,
            "created_at": order.created_at,
            "updated_at": order.updated_at,
            "submitted_at": order.submitted_at,
            "filled_at": order.filled_at,
            "expired_at": order.expired_at,
            "canceled_at": order.canceled_at,
            "failed_at": order.failed_at,
            "asset_id": order.asset_id,
            "symbol": order.symbol,
            "asset_class": order.asset_class,
            "qty": order.qty,
            "filled_qty": order.filled_qty,
            "type": order.type,
            "side": order.side,
            "status": order.status,
            "limit_price": order.limit_price,
        }

    async def get_order_status(self, order_id: str) -> Dict[str, Any]:
        """Get status of a specific order"""
        order = self.trading_client.get_order_by_id(order_id)
        return {
            "order_id": order.id,
            "status": order.status,
            "filled_qty": order.filled_qty,
            "filled_avg_price": order.filled_avg_price,
            "limit_price": order.limit_price,
            "created_at": order.created_at,
            "updated_at": order.updated_at,
        }

    async def get_position(self, symbol: str) -> Dict[str, Any]:
        """Get position information for a specific symbol"""
        try:
            position = self.trading_client.get_open_position(symbol)
            return {
                "symbol": position.symbol,
                "qty": float(position.qty),
                "avg_entry_price": float(position.avg_entry_price),
                "market_value": float(position.market_value),
                "cost_basis": float(position.cost_basis),
                "unrealized_pl": float(position.unrealized_pl),
                "unrealized_plpc": float(position.unrealized_plpc),
                "current_price": float(position.current_price),
                "lastday_price": float(position.lastday_price),
                "change_today": float(position.change_today),
            }
        except Exception as e:
            return {"error": str(e)}

    async def get_positions(self) -> list:
        """Get all open positions"""
        positions = self.trading_client.get_all_positions()
        return [{
            "symbol": pos.symbol,
            "qty": float(pos.qty),
            "avg_entry_price": float(pos.avg_entry_price),
            "market_value": float(pos.market_value),
            "cost_basis": float(pos.cost_basis),
            "unrealized_pl": float(pos.unrealized_pl),
            "unrealized_plpc": float(pos.unrealized_plpc),
            "current_price": float(pos.current_price),
            "lastday_price": float(pos.lastday_price),
            "change_today": float(pos.change_today),
        } for pos in positions]

    async def get_historical_bars(self, 
                                symbol: str,
                                start: datetime,
                                end: datetime,
                                timeframe: str = '1D') -> Dict[str, Any]:
        """Get historical bar data for a symbol"""
        timeframe_map = {
            '1Min': TimeFrame.Minute,
            '1H': TimeFrame.Hour,
            '1D': TimeFrame.Day,
        }
        
        tf = timeframe_map.get(timeframe, TimeFrame.Day)
        
        request = StockBarsRequest(
            symbol_or_symbols=symbol,
            timeframe=tf,
            start=start,
            end=end
        )
        
        bars = self.data_client.get_stock_bars(request)
        return bars.data
