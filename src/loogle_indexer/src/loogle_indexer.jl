module loogle_indexer

include("index.jl")
include("parsers.jl")

function main()
    index = Index(ARGS[1])
    show(index)
    indexDir(index)
    show(index)
end

function julia_main()::Cint
    main()
    return 0
end

#= people = [Dict("name"=>"CoolGuy", "company"=>"tech") for i=1:1000]
companies = [Dict("name"=>"CoolTech", "address"=>"Bay Area") for i=1:100]

data = Dict("people"=>people, "companies"=>companies)
json_string = JSON.json(data)

open("foo.json","w") do f
  JSON.print(f, json_string)
end =#

end # module loogle_indexer
