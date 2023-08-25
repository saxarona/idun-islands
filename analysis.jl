# A short script to get the minimum value of each of the test functions

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
            push!(d, minimum(skipmissing(df.minimum)))
        end
        push!(cols, d)
    end
    print("$eachf\n $(DataFrame(Dict(zip(dirs, cols))))\n\n")
end
