module TradingPipeline

# from the wider ecosystem
using Chain
using DataFrames
using Dates
using DocStringExtensions
using EnumX
using Printf
using UnPack
using Rocket

# work of people I've interacted with
import HierarchicalStateMachines as HSM
using OnlineTechnicalIndicators

# my own work
using CryptoMarketData
using TechnicalIndicatorCharts
using ReversedSeries
import ExchangeOperations as XO

include("util.jl")
include("pnl.jl")
include("report.jl")
include("explore.jl")
export report

include("abstract_strategy.jl")
include("strategies/goldencross.jl")
include("strategies/hma.jl")
include("strategies/hma2.jl")

include("abstract_stop.jl")
include("stops.jl")

export load_strategy
include("hsm_types.jl")
include("candles.jl")
include("rocket.jl")
include("pipeline.jl")
export simulate

end



# REPL work

#=

using Statistics
using CryptoMarketData
using TechnicalIndicatorCharts
using ReversedSeries
import ExchangeOperations as XO

using UnPack
using LightweightCharts

pancakeswap = PancakeSwap()
btcusd1m = load(pancakeswap, "BTCUSD"; span=Date("2023-07-01"):Date("2024-11-29"))

import TradingPipeline as TP
import HierarchicalStateMachines as HSM
using TradingPipeline
using TradingPipeline: simulate, GoldenCrossStrategy, HMAStrategy, HMA2Strategy, df_candles_observable
using TradingPipeline: load_strategy, report

candle_observable = df_candles_observable(btcusd1m)
@unpack hsm, simulator_session, chart_subject = simulate(candle_observable, HMA2Strategy);
rdf = report(simulator_session)

sum(rdf.pnl)
mean(rdf.pnl)
mean(rdf.percent)

=#
