# A short script to get the minimum value of each of the test functions
# We remove NaNs which appeared in some of the calculations using d=3

using CSV
using DataFrames

path = "./data/"
fs = readdir(path)

#for each  function
for eachf in fs
    dirs = readdir("$(path)/$(eachf)/")
    cols = []
    #for each dimension
    for eachdir in dirs
        d = []
        dfs = []
        # read eachfile
        for i in 1:32
            push!(dfs, CSV.read("$(path)$(eachf)/$(eachdir)/data_$(i-1).csv", DataFrame))
            df = filter(row -> all(x -> !(x isa Number && isnan(x)), row), dfs[i])
            push!(d, minimum(skipmissing(df.min)))
        end
        push!(cols, d)
    end
    print("$eachf\n $(DataFrame(Dict(zip(dirs, cols))))\n\n")
end
