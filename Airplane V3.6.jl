using SimJulia
using Distributions
using DataStructures
using RandomStreams
using PyPlot


include("TallyStat.jl")
using .TallyStat
include("TallyStoreStat.jl")
using .TallyStoreStat
include("AccumulateStat.jl")
using .AccumulateStat

const SEED = 12345
seeds = [SEED, SEED, SEED, SEED, SEED, SEED]

rng_gen = MRG32k3aGen(seeds)
rngArr = next_stream(rng_gen)
rngServ = next_stream(rng_gen)

#generate random value using MRG32k3a
RandDist(Dist::Distribution, rng::MRG32k3a) = quantile(Dist, rand(rng))

###### Type : Runway(env)
    type Runway  
      genArr:: Distribution
      genServ:: Distribution
      waitList::Deque
      servList::Deque
      accWait::accumulate
      tallyWaits::tally
      statStore::tallyStore
      
      # Constructor definition
      function Runway(env::Environment, lambda::Float64, mu::Float64)
          Que = new()
          Que.genArr = Exponential(1/lambda) # Airplane Arrival time                 
          Que.genServ = Exponential(1/mu) # Airplane landing and takeoff time
          
          Que.waitList = Deque{Airplane}()
          Que.servList = Deque{Airplane}()
          Que.accWait = accumulate("Size of Runway", env)
          Que.tallyWaits = tally("Waiting times")
          Que.statStore = tallyStore()
          println("Quantile genArr = ", quantile(Que.genArr, [0.5, 0.95]))
          println("Quantile genServ = ", quantile(Que.genServ, [0.5, 0.95]))
          return Que 
      end
    end     
    
###### Type : Airplane(name, Arrival Time, Service start Time)
    type Airplane
        name :: ASCIIString
        arrivTime :: Float64
        serviceTime :: Float64
        takeOffTime :: Float64
        proc :: Process
        
        # Constructor definition
        function Airplane(env::Environment, name::ASCIIString, bcs::Resource, Que::Runway)
          Aplane = new()
          Aplane.name = name
          Aplane.arrivTime = NaN
          Aplane.serviceTime = NaN
          Aplane.takeOffTime = NaN
          Aplane.proc = Process(env, name, arrDep, Aplane, bcs, Que)
          return Aplane
        end
    end   
    
#### Airplane Arrival, Waiting, landing and takeoff
function arrDep(env::Environment, Aplane::Airplane, bcs::Resource, Que::Runway)

    name = Aplane.name

    yield(Timeout(env, RandDist(Que.genArr, rngArr)))
    #println("$name arriving at $(now(env))") 
    Aplane.arrivTime = now(env)
    if ( length(Que.servList) > 0.0)
        push!(Que.waitList, Aplane)
        Que.accWait = accAdd(convert(Int64, length(Que.waitList)), env, Que.accWait)
    end
    yield(Request(bcs))  # Request resources from Runway
    #println("$name starting Service at $(now(env))")
    push!(Que.servList, Aplane)
    Aplane.serviceTime = now(env) 
    if ( Aplane.serviceTime > Aplane.arrivTime)
        shift!(Que.waitList)
        Que.accWait = accAdd(convert(Int64, length(Que.waitList)), env, Que.accWait)
    end
    
    Que.tallyWaits = tallyAdd((Aplane.serviceTime - Aplane.arrivTime), Que.tallyWaits)
    Que.statStore = add2TallyStore(Que.statStore, (Aplane.serviceTime - Aplane.arrivTime), Aplane.arrivTime)
    
    yield(Timeout(env, RandDist(Que.genServ, rngServ)))
    #println("$name leaving at $(now(env))")    
    Aplane.takeOffTime = now(env)
    
    yield(Release(bcs)) # Release Runway
    shift!(Que.servList)
end

##Reset waitList & servList
function resetLists(Que::Runway)

  empty!(Que.waitList)
  empty!(Que.servList)  
  return Que

end


function Simulates(Que::Runway,env::Environment,nSimulations::Int64)
    Airplanes = Airplane[]
    
    for i=1:nSimulations   
    # Execute!      
        println("Stats of Simulation ", string(i))    
        next_substream!(rngArr)
        next_substream!(rngServ)
        
        cw = Resource(env, 1) # cw is the server : Airplane Runway 

        Airplanes = [Airplane(env, "Airplane$j", cw, Que) for j = 1:numOfAirplanes] 
        run(env, simulationDuration)
        # Show Tally and Accumulate Reports
        tallyReport(Que.tallyWaits)
        accReport(Que.accWait, env)
        
        # Reset Stats
        env = Environment()      
        Que = resetLists(Que)
        Que.tallyWaits = resetTally(Que.tallyWaits)
        Que.accWait = resetAccumulate(Que.accWait,env)
        
        Airplanes = Airplane[]
    end

    ##Show TallyStore Stats
    data = quickSortServList(Que.statStore)
    
    println("###Quantile of delay time###")
    println("0.10 quantile or delay time: ", round(data[cld(length(data)*10,100)],3) )
    println("0.50 quantile or delay time: ", round(data[cld(length(data)*50,100)],3) )
    println("0.90 quantile or delay time: ", round(data[cld(length(data)*90,100)],3) )
    println("0.99 quantile or delay time: ", round(data[cld(length(data)*99,100)],3) , "\n")
    
    
    ArrivalTimeArray = quickSortArrvList(Que.statStore)
    println("###Quantile of Arrival time###")
    println("0.10 quantile of Arrival time: ", round(ArrivalTimeArray[cld(length(ArrivalTimeArray)*10,100)],3) )
    println("0.50 quantile of Arrival time: ", round(ArrivalTimeArray[cld(length(ArrivalTimeArray)*50,100)],3) )
    println("0.90 quantile of Arrival time: ", round(ArrivalTimeArray[cld(length(ArrivalTimeArray)*90,100)],3) )
    println("0.99 quantile of Arrival time: ", round(ArrivalTimeArray[cld(length(ArrivalTimeArray)*99,100)],3) , "\n")
    
    #Plot Arrival Times
    plot(sort(ArrivalTimeArray, alg=QuickSort, rev=true), label  = "Arrival Time Graph")

    
    simulationsStat = tally("TallyStore Stats")
    for element in data
        simulationsStat = tallyAdd(element, simulationsStat)
    end
    tallyReport(simulationsStat)
    simulationsStat = resetTally(simulationsStat)
    Que.statStore = resetTallyStore(Que.statStore)
  
end

const simulationDuration = 1000.0 # Duration of each simulation
const numOfAirplanes = 60  #Number of Airplanes
const lambda = 0.03
const mu = 0.1
const numSimulations=10

## Setup and start the simulation
println("Airplane")

## Create an environment and start the setup process
env = Environment()
simulation = Runway(env, lambda, mu)

##Start simulations
Simulates(simulation,env,numSimulations)