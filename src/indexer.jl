include("index.jl")

index = Index(ARGS[1])

show(index)

indexDir(index)

show(index)

#= people = [Dict("name"=>"CoolGuy", "company"=>"tech") for i=1:1000]
companies = [Dict("name"=>"CoolTech", "address"=>"Bay Area") for i=1:100]

data = Dict("people"=>people, "companies"=>companies)
json_string = JSON.json(data)

open("foo.json","w") do f
  JSON.print(f, json_string)
end =#