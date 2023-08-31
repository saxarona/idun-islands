# A short script to get the minimum value of each of the test functions

using CSV
using DataFrames

path = "./singlecore/"
fs = readdir(path)
const SAVE = true

post = []

#for each  function
for eachf in fs
    dirs = readdir("$(path)/$(eachf)/")
    cols = []
    #for each dimension
    for eachdir in dirs
        d = []
        dfs = []
        # read eachfile
        for i in 1:64
            push!(dfs, CSV.read("$(path)$(eachf)/$(eachdir)/data_$(i).csv", DataFrame))
            df = filter(row -> all(x -> !(x isa Number && isnan(x)), row), dfs[i])
            push!(d, minimum(skipmissing(df.minimum)))
        end
        push!(cols, d)
    end
    tab = DataFrame(Dict(zip(dirs, cols)))
    if SAVE
        CSV.write("./analysis/$(eachf)_s.csv", tab)
    end
    push!(post, tab)
    print("for f=$(eachf) \n $(tab) \n")
end
