using Iterators

# now, for simplicity, start with n agents and k goods. 
# allow all endowments to be between 0 and 100. 
# thus, prices are bounded above. 

n=5
k=3

# now generate the space of possible endowments
goodSpaces=[]
for i in 1:k
    push!(goodSpaces,collect(0:1:100))
end

totSpace=collect(Iterators.product(goodSpaces...))

# now, what are the rules for a utility function?

# >= our ordering. 
# a la Savage, we read x >= y as y is not preferred to x
# in this order / graph theoretic framework for utility, indifference is represented as x >= y and y >= x. 
# we indicate the not preferred relation by an arrow pointing from y to x. 
# so indifferent bundles have arrows in both directions. 
# the network is directed. All points in it should be connected by at least one arrow. 
# now, in the discrete framework we are working in, we need only the following rules:
# if x >= y and y >= z then x >= z (transitivity)
# Let >> mean "weakly greater" which means that at least one element in the bundle x exceeds the corresponding element in y and all others are equal
# if x >> y then x >= y

# now, we can design utility functions that fill out the utility graph as needed

# further, we can store these huge graphs efficiently. 
# in the list, we can indicate which direction in which x and y and connected. 

# so now, when we execute U(x,y) then we ask:
# is there an arrow between x and y?
# if so, we are done
# if not, should x >= y meaning y=> x?
# if x >= z and z >= y, we are done
# else if x >> y, we are done
# else, we flip a coin
# and log the preference in the sparse matrix

# what would an advantageous sparse matrix format be?
# firstly, we list the two bundles as tuples and then the relation
struct bundle
    contents::Array{Int64}
end

mutable struct agent
    endowment::bundle
end

import Base: >=
import Base: >>
 
function >>(x::bundle,y::bundle)
    #println(x.contents)
    #println(y.contents)
    return all(((x.contents .> y.contents)) .|| (x.contents.==y.contents))

end

function wGreater(agt::agent,x::bundle,y::bundle)

end

function utility(agt::agent,x::bundle,y::bundle)

end



# we can also define demand curves
# and demand curve relates the set of price vectors to the set of 
