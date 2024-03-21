using Random
using Distributions
using Statistics
U=Uniform()
# basic equilibrium test

goodNum::Int64=2

mutable struct agent
    utilAlpha::Array{Float64}
    alloc::Array{Float64}
    priceHistory::Dict{Tuple{Int64,Int64}}{Array{Float64}}
    betaParam::Float64
    utilHistory::Array{Float64}
end

agtList::Array{agent}=agent[]

function agtGen(alpha::Array{Float64},alloc::Array{Float64})
    global goodNum
    keyVec=[]
    for i in 1:goodNum
        for j in 1:i
            push!(keyvec,(i,j))
        end
    end
    priceDict=Dict{Tuple{Int64.Int64},Array{Float64}}()
    agt=agent(alpha,alloc,priceDict,.5,Float64[])
    return agt
end


agt1=agent(Float64[.7,.3],Float64[10.0,100.0],Float64[],.5,Float64[])
agt2=agent(Float64[.3,.7],Float64[100.0,10.0],Float64[],.5,Float64[])
agt3=agent(Float64[.2,.8],Float64[50.0,30.0],Float64[],.5,Float64[])

function util(agt::agent,x::Array{Float64})
    return sum(x.^agt.utilAlpha)
end

function tradeGen(agt1::agent,agt2::agent)
    offerType=sample(1:length(agt1.alloc),2,replace=false)
    offer1=rand(U,1)[1]*agt1.alloc[offerType[1]]
    offer2=rand(U,1)[1]*agt2.alloc[offerType[2]]

    return (offerType,(offer1,offer2))
end

# can we broadcast with single agents if we define length function for agents?

function length(agt::agent)
    return 10000
end

# we need the function where by agents evaluate their potential gains from trade

function agtEval(agt1::agent,agt2::agent,tradePair::Tuple)
    # agt 1 trades which good?
    agtOffer1=tradePair[1]
    # agt 2 trades which good?
    agtOffer2=tradePair[2]
    # make a blank vector
    global goodNum
    deltaVec=zeros(10000,goodNum)
    # now, simulate the possible trades
    deltaVec[:,agtOffer1]=rand(U,10000).*agt1.alloc[agtOffer1]
    deltaVec[:,agtOffer2]=-rand(U,10000)*agt2.alloc[agtOffer2]

    # now find the gains from trade
    uVec =[]
    push!(uVec,(x) -> util(agt1,x))
    push!(uVec,(x) -> util(agt2,x))
    
    gains1=mapslices(uVec[1],transpose(agt1.alloc).+deltaVec,dims=2)
    gains2=mapslices(uVec[2],transpose(agt2.alloc).-deltaVec,dims=2)

    # now, what utility does the agent currently have?
    currUtil1=util(agt1,agt1.alloc)
    currUtil2=util(agt2,agt2.alloc)

    better1= gains1 .> currUtil1
    better2=gains2 .> currUtil2

    gainsFromTrade=(better1 .&& better2)[:,1]
    # now, subset to gains from trade
    goodTrades=deltaVec[gainsFromTrade,:]
    prices=abs.(goodTrades[:,1]./goodTrades[:,2])
    # now, if the agent has no price history, the agent initializes by taking the geometric mean of the 
    # gainful trades. 


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

