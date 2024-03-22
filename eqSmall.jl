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
        for j in i:goodNum
            push!(keyVec,(i,j))
        end
    end
    
        
    priceDict=Dict{Tuple{Int64,Int64},Array{Float64}}()
    for ky in keyVec
        priceDict[ky]=Float64[]
    end
    agt=agent(alpha,alloc,priceDict,.5,Float64[])
    return agt
end



agt1=agtGen(Float64[.3,.7],Float64[100.0,10.0])
agt2=agtGen(Float64[.7,.3],Float64[10.0,100.0])
agt3=agtGen(Float64[.2,.8],Float64[50.0,30.0])
agt4=agtGen(Float64[.8,.2],Float64[50.0,130.0])

function util(agt::agent,x::Array{Float64})
    return sum(x.^agt.utilAlpha)
end

function tradeGen(agt1::agent,agt2::agent)
    offerType=sample(1:length(agt1.alloc),2,replace=false)
    offer1=rand(U,1)[1]*agt1.alloc[offerType[1]]
    offer2=rand(U,1)[1]*agt2.alloc[offerType[2]]

    return (offerType,(offer1,offer2))
end

function geometric_mean(x::Vector{Float64})
    n = length(x)
    product = prod(x)
    return product ^ (1 / n)
end


# we need the function where by agents evaluate their potential gains from trade

function agtEval(agt1::agent,agt2::agent,tradePair::Tuple)
    # agt 1 trades which good?
    agtOffer1=tradePair[1]
    # agt 2 trades which good?
    agtOffer2=tradePair[2]
    # make a blank vector
    tradeTuple=(agtOffer1,agtOffer2)
    global goodNum
    deltaVec=zeros(10000,goodNum)
    # now, simulate the possible trades
    deltaVec[:,agtOffer1]=-rand(U,10000).*agt1.alloc[agtOffer1]
    deltaVec[:,agtOffer2]=+rand(U,10000)*agt2.alloc[agtOffer2]

    # now find the gains from trade
    uVec =[]
    push!(uVec,(x) -> util(agt1,x))
    push!(uVec,(x) -> util(agt2,x))
    # note, agent one gets what's in the left column and gives what is in the right
    # this means that agt one prefers lower prices
    # and agent two prefers higher
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
    if length(agt1.priceHistory[tradeTuple])==0
        push!(agt1.priceHistory[tradeTuple],geometric_mean(prices))
    end

    if length(agt2.priceHistory[tradeTuple])==0
        push!(agt2.priceHistory[tradeTuple],geometric_mean(prices))
    end

    #(mxPrice-offerPrice)/(mxPrice-fairPrice)
    function acceptFunc1(offerPrice)
        # now take the geometric mean of all observed trade prices. We call this the "fair price"
        fairPrice=geometric_mean(agt1.priceHistory[tradeTuple])
        # now build agent one probability 
        # the agent will accept any beneficial trade at or above what it perceives as the equilibrium price
        mnPrice=minimum(prices) 
        mxPrice=maximum(prices)
        
        # reminder, agt 1 will accept trade with probability 1 at or below the perceived equilibrium price
        if offerPrice <= fairPrice
            return true
        else
            # get probability threshold for current price
            threshold=(mxPrice-offerPrice)/(mxPrice-fairPrice)
            Beta1=Beta(1+agt1.betaParam,1)
            pThres=quantile(Beta1,threshold)
            if rand(U,1)[1] >= pThres
                return true
            else
                return false
            end
        end
    end

    function acceptFunc2(offerPrice)
        # now take the geometric mean of all observed trade prices. We call this the "fair price"
        fairPrice=geometric_mean(agt2.priceHistory[tradeTuple])
        # now build agent one probability 
        # the agent will accept any beneficial trade at or above what it perceives as the equilibrium price
        mnPrice=minimum(prices) 
        mxPrice=maximum(prices)
        
        # reminder, agt 2 will accept trade with probability 1 at or above the perceived equilibrium price
        tradeBool::Bool=false
        if offerPrice <= fairPrice
            return true
        else
            # get probability threshold for current price
            threshold=(offerPrice-mnPrice)/(mxPrice-mnPrice)
            Beta1=Beta(1+agt1.betaParam,1)
            pThres=quantile(Beta1,threshold)
            if rand(U,1)[1] >= pThres
                return true
            else
                return false
            end
        end
    end
    # now, find a trade
    pIndex=sample(1:length(prices),length(prices),replace=false)

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

