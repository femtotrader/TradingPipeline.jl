using DataFrames
using ReversedSeries
using ReversedSeries: find_index
using TechnicalIndicatorCharts
using TechnicalIndicatorCharts: Chart
using LightweightCharts
import ExchangeOperations as XO

function make_result(open::XO.SimulatorMarketBuyFill, close::XO.SimulatorMarketSellFill)
    r = @pnl open.price close.price close.amount
    return (action      = :long,
            open_ts     = open.ts,
            open_price  = open.price,
            close_ts    = close.ts,
            close_price = close.price,
            amount      = close.amount,
            pnl         = r.profit_loss)
end

function make_result(open::XO.SimulatorMarketSellFill, close::XO.SimulatorMarketBuyFill)
    r = @pnls open.price close.price close.amount
    return (action      = :short,
            open_ts     = open.ts,
            open_price  = open.price,
            close_ts    = close.ts,
            close_price = close.price,
            amount      = close.amount,
            pnl         = r.profit_loss)
end

"""report(session::XO.SimulatorSession) -> DataFrame

Return a list of trades that happened during the simulator session.
"""
function report(session::XO.SimulatorSession)
    neutral = true
    open = missing
    close = missing
    trades = []
    for fill in session.order_log
        if neutral
            open = fill
            neutral = false
        else
            close = fill
            push!(trades, make_result(open, close))
            neutral = true
        end
    end
    if !neutral
        # INFO: This is a marker for a position that was left open at the end of the simulation.
        dt = DateTime(2222, 11, 11)
        close = if typeof(open) == XO.SimulatorMarketBuyFill
            XO.SimulatorMarketSellFill(;ts=dt, price=session.state.price, amount=open.amount)
        else
            XO.SimulatorMarketBuyFill(;ts=dt, price=session.state.price, amount=open.amount)
        end
        push!(trades, make_result(open, close))
    end
    return DataFrame(trades)
end

"""$(TYPEDSIGNATURES)

Let's see if I can visualize trades on top of a chart.
"""
function TechnicalIndicatorCharts.visualize(t::Tuple{Chart, XO.AbstractSession})
    (chart, session) = t
    rdf = report(session)
    layout = TechnicalIndicatorCharts.visualize(chart)
    cell11 = layout.panels["cell11"]
    stix = cell11.charts[1]
    index_of = ts::DateTime -> find_index(chart.df.ts, t -> t >= ts)
    for row in eachrow(rdf)
        index2 = if ismissing(index_of(row.close_ts))
            lastindex(chart.df.ts)
        else
            index_of(row.close_ts)
        end
        trade_marker = lwc_trend_line(
            index_of(row.open_ts),
            row.open_price,
            index2-1,
            row.close_price;
            line_color="#7CB518"
        )
        push!(stix.plugins, trade_marker)
    end
    return layout
end

#=
layout = chart_subject[:trend] |> visualize
cell11 = layout.panels["cell11"]
typeof(cell11) <: LWCPanel
cell11.charts
stix = cell11.charts[1]                 # candlestick chart is here
typeof(stix) <: LWCChart
stix.plugins                            # Vector{LWCPlugin}
=#
