using Random
using Distributions
U=Uniform()
# basic equilibrium test

goodNum::Int64=2

mutable struct agent
    utilAlpha::Array{Float64}
    alloc::Array{Float64}
    priceHistory::Array{Float64}
    betaParam::Float64
    utilHistory::Array{Float64}
end

a1=agent(Float64[.7,.3],Float64[10.0,100.0],Float64[],.5,Float64[])
a2=agent(Float64[.3,.7],Float64[100.0,10.0],.5,Float64[],Float64[])
a3=agent(Float64[.2,.8],Float64[50.0,30.0],.5,Float64[],Float64[])

function util(agt::agent,x::Array{Float64})
    return x.^agt.utilAlpha
end

function tradeGen(agt1::agent,agt2::agent)
    offerType=sample(1:length(agt1.alloc),2,replace=false)
    offer1=rand(U,1)[1]*agt1.alloc[offerType[1]]
    offer2=rand(U,1)[1]*agt2.alloc[offerType[2]]

    return (offerType,(offer1,offer2))
end

# we need the function where by agents evaluate their potential gains from trade

function agtEval(agt1::agent,agt2::agent,tradePair::Tuple)
    # agt 1 trades which good?
    agtOffer1=tradePair[1]
    # agt 2 trades which good?
    agtOffer2=tradePair[2]
    # make a blank vector
    deltaVec=repeat([0.0,goodNum])
    # now, simulate the possible trades
    r1=rand(U,10000)*agt1.alloc[agtOffer1]
    r2=rand(U,10000)*agt2.alloc[agtOffer2]
    deltaVec[agtOffer1]=-r1
    deltaVec[agtOffer2]=r2

    # now find the gains from trade
    function util1(x::Array{Float64})
        return util(agt1,x)
    end

    function util2(x::Array{Float64})
        return util(agt2,x)
    end

    gains=util1.(agt1.alloc.+deltaVec)


end


# now, initially, agents are minimally intelligent
# agents accept the trade with probability 1 if it is mutually advantageous
# over time, agents keep track of trade prices and take an average price for each pair of commodities
# agents have a probability of accepting the trade based on this average 
# if the offered trade is utility increasing, then, the agent accepts the trade with probability 1 if the offered price 
# is at this mean or else more advantageous to the agent.
# if the price is less advantageous to the agent than this price, the agent accepts the trade with a 
# probability governed by the following:
# firstly, the support is all prices advantageous to the agent SET MINUS those more advantageous to the agent 
# we define a beta distribution Beta(1+a,1). Note the non-standard parameterization
# Now, we know the potential gains from trade from the support
# if the support is null, that is, no gains from trade can be had at the market price for all commodities and agents, 
# we halt
# after each round, if the agent has higher utility at the end than last round, it makes its acceptance stricter by:
# scaling up the beta parameter by 2
# if the agent has lower utility than the end of last round, it scales the beta parameter by 1/2.

