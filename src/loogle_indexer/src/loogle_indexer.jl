module loogle_indexer

using Base.Threads

# TODO: verify if this works when compiled
const JULIA_NUM_THREADS = Threads.nthreads()

@static if !@isdefined(PARSERS_JL_INCLUDED)
    include("parsers.jl")
end
@static if !@isdefined(INDEX_JL_INCLUDED)
    include("index.jl")
end

function main()::Cint
    index = Index(ARGS[1])
    show(index)
    indexDir(index)
    show(index)
    return 0
end

function julia_main()::Cint
    return main()
end

#= people = [Dict("name"=>"CoolGuy", "company"=>"tech") for i=1:1000]
companies = [Dict("name"=>"CoolTech", "address"=>"Bay Area") for i=1:100]

data = Dict("people"=>people, "companies"=>companies)
json_string = JSON.json(data)

open("foo.json","w") do f
  JSON.print(f, json_string)
end =#

end # module loogle_indexer
